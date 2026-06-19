/**
 * 传输服务——使用互传联盟 TCP 协议实现文件传输
 *
 * 基于 Wi-Fi Direct (P2P) 建立 TCP 连接后，使用 ShareTransferProtocol
 * 完成握手、元数据交换、分片传输、确认重传等完整流程。
 *
 * 协议核心流程：
 *   发送方                       接收方
 *     │                           │
 *     ├─ HANDSHAKE_REQ ─────────► │
 *     │◄─ HANDSHAKE_RESP ────────┤
 *     │                           │
 *     ├─ FILE_LIST_INFO ─────────►│
 *     │◄─ FILE_LIST_ACK ────────┤
 *     │                           │
 *     ├─ FILE_INFO ──────────────►│
 *     │◄─ FILE_INFO_ACK ────────┤
 *     │                           │
 *     ├─ DATA_CHUNK(seq) ───────►│
 *     │◄─ DATA_ACK(recvBytes) ──┤
 *     │  (重复直到文件结束)        │
 *     │                           │
 *     ├─ TRANSFER_DONE ─────────►│
 *     │◄─ TRANSFER_DONE_ACK ────┤
 *     │                           │
 */

import { wifiManager } from '@kit.ConnectivityKit';
import { socket } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  PacketCommand,
  Packet,
  SequenceManager,
  TransferPhase,
  encodePacket,
  parsePackets,
  decodeHandshakePayload,
  encodeFileInfoPayload,
  decodeFileInfoPayload,
  encodeDataChunkPayload,
  decodeDataChunkPayload,
  encodeDataAckPayload,
  decodeDataAckPayload,
  encodeTransferDonePayload,
  decodeTransferDonePayload,
  encodeFileListPayload,
  decodeFileListPayload,
  buildHandshakeReq,
  buildHandshakeResp,
  isCompatibleVersion,
  DEFAULT_CHUNK_SIZE,
  DataAckPayload,
  FileInfoPayload,
} from '../utils/ShareTransferProtocol';

const TAG = 'TransportService';
const TRANSFER_PORT: number = 24680;
const HANDSHAKE_TIMEOUT: number = 30000;
const CHUNK_TIMEOUT: number = 30000;
const MAX_RETRIES: number = 3;
const PROGRESS_REPORT_INTERVAL: number = 500; // ms
const HEARTBEAT_INTERVAL: number = 10000;

export { TransferPhase };

export interface TransportEvent {
  type: string;
  phase?: TransferPhase;
  message?: string;
  progress?: number;
  fileIndex?: number;
  fileName?: string;
  fileSize?: number;
  transferredBytes?: number;
  speed?: number;
  eta?: number;
}

export type TransportEventCallback = (event: TransportEvent) => void;

export class TransportService {
  private static instance: TransportService;
  private eventListeners: TransportEventCallback[] = [];
  private _phase: TransferPhase = TransferPhase.IDLE;
  private p2pGroupActive: boolean = false;
  private goIpAddress: string = '192.168.49.1';
  private seqManager: SequenceManager = new SequenceManager();
  private role: number = 0;
  private deviceName: string = 'ToShare';
  private conn: socket.TCPSocketConnection | null = null;
  private tcpServer: socket.TCPSocketServer | null = null;
  private handshakeOk: boolean = false;
  private remoteDeviceName: string = '';
  private remoteRole: number = 0;
  private pendingFiles: FileInfoPayload[] = [];
  private chunkSize: number = DEFAULT_CHUNK_SIZE;
  private fileDataProvider: ((fileIndex: number) => ArrayBuffer | null) | null = null;

  // 接收缓冲区
  private recvBuf: Uint8Array = new Uint8Array(0);

  // 包等待调度器
  private pktQueue: Packet[] = [];
  private pktResolve: ((pkt: Packet) => void) | null = null;
  private pktReject: ((err: Error) => void) | null = null;
  private pktTimer: number = -1;
  private pktExpectedCmd: PacketCommand | null = null;

  // 接收方异步处理
  private incomingHandler: ((pkt: Packet) => void) | null = null;
  private recvLoopResolve: (() => void) | null = null;
  private recvLoopReject: ((err: Error) => void) | null = null;

  // 接收方缓存
  private rcvFileInfo: FileInfoPayload | null = null;
  private rcvFileData: Uint8Array | null = null;
  private rcvFileList: FileInfoPayload[] = [];
  private rcvFileIndex: number = 0;

  // 心跳定时器
  private heartbeatTimer: number = -1;

  static getInstance(): TransportService {
    if (!TransportService.instance) {
      TransportService.instance = new TransportService();
    }
    return TransportService.instance;
  }

  get phase(): TransferPhase {
    return this._phase;
  }

  get peerDeviceName(): string {
    return this.remoteDeviceName;
  }

  get goIp(): string {
    return this.goIpAddress;
  }

  get port(): number {
    return TRANSFER_PORT;
  }

  isGroupActive(): boolean {
    return this.p2pGroupActive;
  }

  isConnected(): boolean {
    return this.conn !== null && this.handshakeOk;
  }

  addEventListener(cb: TransportEventCallback): void {
    if (!this.eventListeners.includes(cb)) {
      this.eventListeners.push(cb);
    }
  }

  removeEventListener(cb: TransportEventCallback): void {
    const idx = this.eventListeners.indexOf(cb);
    if (idx >= 0) {
      this.eventListeners.splice(idx, 1);
    }
  }

  private emit(evt: TransportEvent): void {
    for (const cb of this.eventListeners) {
      try { cb(evt); } catch (e) {
        hilog.error(0x0001, TAG, 'Event cb error: %{public}s', JSON.stringify(e));
      }
    }
  }

  private changePhase(phase: TransferPhase, msg?: string): void {
    this._phase = phase;
    this.emit({ type: 'phaseChange', phase, message: msg });
  }

  private emitHandshake(peer: string): void {
    this.emit({ type: 'handshake', message: `已连接 ${peer}` });
  }

  private emitError(msg: string): void {
    this.emit({ type: 'error', message: msg });
  }

  private emitProgress(fi?: number, msg?: string, p?: number, sent?: number, total?: number, spd?: number, eta?: number): void {
    this.emit({
      type: 'progress', fileIndex: fi, message: msg, progress: p,
      transferredBytes: sent, fileSize: total, speed: spd, eta,
    });
  }

  // ==================== 发送方 API ====================

  async startAsSender(
    files: FileInfoPayload[],
    dataProvider?: (fileIndex: number) => ArrayBuffer | null
  ): Promise<void> {
    this.role = 1;
    this.pendingFiles = files;
    this.fileDataProvider = dataProvider || null;
    this.seqManager.reset();
    this.handshakeOk = false;

    try {
      this.changePhase(TransferPhase.HANDSHAKE, '正在创建 Wi-Fi Direct 通道...');
      if (!(await this.ensureP2pGroup())) {
        this.changePhase(TransferPhase.ERROR, '创建 P2P 群组失败');
        return;
      }

      this.tcpServer = socket.constructTCPSocketServerInstance();
      const addr: socket.NetAddress = { address: '0.0.0.0', port: TRANSFER_PORT, family: 1 };
      await this.listenServer(addr);

      this.emit({ type: 'phaseChange', phase: TransferPhase.HANDSHAKE,
        message: `等待接收方连接... (${this.goIpAddress}:${TRANSFER_PORT})` });

      if (!(await this.waitP2pConnection(60000))) {
        this.changePhase(TransferPhase.ERROR, '等待 P2P 连接超时');
        return;
      }

      const conn = await this.waitTcpConn(60000);
      if (!conn) {
        this.changePhase(TransferPhase.ERROR, '等待 TCP 连接超时');
        return;
      }
      this.bindConn(conn);

      if (!(await this.doHandshake())) {
        this.changePhase(TransferPhase.ERROR, '握手失败');
        return;
      }
      this.handshakeOk = true;
      this.startHeartbeat();

      if (!(await this.sendFileList())) {
        this.changePhase(TransferPhase.ERROR, '发送文件列表失败');
        return;
      }

      for (let i = 0; i < this.pendingFiles.length; i++) {
        const fi = this.pendingFiles[i];
        if (!(await this.xferFile(fi))) {
          this.changePhase(TransferPhase.ERROR, `文件传输失败: ${fi.fileName}`);
          return;
        }
        this.emitProgress(undefined, `${fi.fileName} 传输完成`, (i + 1) / this.pendingFiles.length);
      }

      this.changePhase(TransferPhase.COMPLETE, '全部文件传输完成');
    } catch (err) {
      hilog.error(0x0001, TAG, 'Sender error: %{public}s', JSON.stringify(err));
      this.changePhase(TransferPhase.ERROR, `传输异常: ${(err as Error).message}`);
    } finally {
      this.cleanup();
    }
  }

  async startAsReceiver(): Promise<void> {
    this.role = 2;
    this.seqManager.reset();
    this.handshakeOk = false;
    this.pendingFiles = [];
    this.rcvFileList = [];

    try {
      this.changePhase(TransferPhase.HANDSHAKE, '正在创建 Wi-Fi Direct 通道...');
      if (!(await this.ensureP2pGroup())) {
        this.changePhase(TransferPhase.ERROR, '创建 P2P 群组失败');
        return;
      }

      this.emit({ type: 'phaseChange', phase: TransferPhase.HANDSHAKE, message: '等待设备连接...' });
      if (!(await this.waitP2pConnection(60000))) {
        this.changePhase(TransferPhase.ERROR, '等待 P2P 连接超时');
        return;
      }

      this.tcpServer = socket.constructTCPSocketServerInstance();
      const addr: socket.NetAddress = { address: '0.0.0.0', port: TRANSFER_PORT, family: 1 };
      await this.listenServer(addr);

      this.emit({ type: 'phaseChange', phase: TransferPhase.HANDSHAKE,
        message: `等待发送方连接... (${this.goIpAddress}:${TRANSFER_PORT})` });

      const conn = await this.waitTcpConn(60000);
      if (!conn) {
        this.changePhase(TransferPhase.ERROR, '等待 TCP 连接超时');
        return;
      }
      this.bindConn(conn);

      if (!(await this.waitHandshake(60000))) {
        this.changePhase(TransferPhase.ERROR, '握手失败');
        return;
      }
      this.handshakeOk = true;
      this.startHeartbeat();

      this.changePhase(TransferPhase.METADATA, '准备接收文件...');
      await this.recvLoop();
    } catch (err) {
      hilog.error(0x0001, TAG, 'Receiver error: %{public}s', JSON.stringify(err));
      this.changePhase(TransferPhase.ERROR, `接收异常: ${(err as Error).message}`);
    } finally {
      this.cleanup();
    }
  }

  // ==================== P2P 群组 ====================

  private async ensureP2pGroup(): Promise<boolean> {
    if (await this.isGroupAlive()) return true;
    return new Promise<boolean>((resolve) => {
      try {
        const cfg: wifiManager.WifiP2PConfig = {
          deviceAddress: '00:00:00:00:00:00',
          deviceAddressType: 1,
          netId: -2,
          passphrase: 'ToShare123',
          groupName: `ToShare_${Date.now() % 100000}`,
          goBand: 0,
        };
        let done = false;
        const onGroupChange = () => {
          if (done) return;
          done = true;
          wifiManager.off('p2pPersistentGroupChange', onGroupChange);
          this.p2pGroupActive = true;
          resolve(true);
        };
        wifiManager.on('p2pPersistentGroupChange', onGroupChange);
        wifiManager.createGroup(cfg);
        setTimeout(() => {
          if (!done) {
            done = true;
            wifiManager.off('p2pPersistentGroupChange', onGroupChange);
            this.p2pGroupActive = true;
            resolve(true);
          }
        }, 15000);
      } catch (err) {
        hilog.error(0x0001, TAG, 'Create group err: %{public}s', JSON.stringify(err));
        resolve(false);
      }
    });
  }

  private async isGroupAlive(): Promise<boolean> {
    try {
      const g = await wifiManager.getCurrentGroup();
      if (g) { this.p2pGroupActive = true; return true; }
    } catch (_) { /* ignore */ }
    return false;
  }

  private waitP2pConnection(ms: number): Promise<boolean> {
    return new Promise<boolean>((resolve) => {
      const t = setTimeout(() => { wifiManager.off('p2pConnectionChange', cb); resolve(false); }, ms);
      const cb = (info: wifiManager.WifiP2pLinkedInfo) => {
        if (info.connectState === 1) { clearTimeout(t); wifiManager.off('p2pConnectionChange', cb); resolve(true); }
      };
      wifiManager.on('p2pConnectionChange', cb);
    });
  }

  // ==================== TCP 服务器 ====================

  private listenServer(addr: socket.NetAddress): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      this.tcpServer!.listen(addr, (err) => err ? reject(err) : resolve());
    });
  }

  private waitTcpConn(ms: number): Promise<socket.TCPSocketConnection | null> {
    if (!this.tcpServer) return Promise.resolve(null);
    return new Promise<socket.TCPSocketConnection | null>((resolve) => {
      const t = setTimeout(() => resolve(null), ms);
      this.tcpServer!.on('connect', (c: socket.TCPSocketConnection) => {
        clearTimeout(t);
        resolve(c);
      });
    });
  }

  private bindConn(c: socket.TCPSocketConnection): void {
    this.conn = c;
    c.on('message', (v: socket.SocketMessageInfo) => this.onMsg(v));
    c.on('close', () => {
      hilog.info(0x0001, TAG, 'TCP closed');
      this.emitError('连接已断开');
      if (this.recvLoopResolve) this.recvLoopResolve();
    });
    c.on('error', (e: Error) => {
      hilog.error(0x0001, TAG, 'TCP err: %{public}s', e.message);
      this.emitError(`连接异常: ${e.message}`);
    });
  }

  // ==================== 心跳 ====================

  private startHeartbeat(): void {
    this.stopHeartbeat();
    this.heartbeatTimer = setInterval(() => {
      if (this.conn) {
        const pkt = encodePacket(PacketCommand.HEARTBEAT, new ArrayBuffer(0), this.seqManager.next());
        this.conn.send({ data: pkt }, () => {});
      }
    }, HEARTBEAT_INTERVAL);
  }

  private stopHeartbeat(): void {
    if (this.heartbeatTimer >= 0) {
      clearInterval(this.heartbeatTimer);
      this.heartbeatTimer = -1;
    }
  }

  // ==================== 数据收发 ====================

  private sendBuf(buf: ArrayBuffer): Promise<void> {
    if (!this.conn) return Promise.reject(new Error('No connection'));
    return new Promise<void>((resolve, reject) => {
      this.conn!.send({ data: buf }, (err) => err ? reject(err) : resolve());
    });
  }

  private sendPkt(pkt: Packet): Promise<void> {
    return this.sendBuf(encodePacket(pkt.header.command as PacketCommand, pkt.payload, pkt.header.sequence));
  }

  private onMsg(v: socket.SocketMessageInfo): void {
    const raw = new Uint8Array(v.message);
    const nb = new Uint8Array(this.recvBuf.length + raw.length);
    nb.set(this.recvBuf);
    nb.set(raw, this.recvBuf.length);
    this.recvBuf = nb;

    const res = parsePackets(this.recvBuf);
    this.recvBuf = res.remaining;
    for (const pkt of res.packets) {
      hilog.info(0x0001, TAG, 'Rcv cmd=0x%04x seq=%d len=%d', pkt.header.command, pkt.header.sequence, pkt.header.payloadLength);
      this.pktQueue.push(pkt);
      this.dispatch();
    }
  }

  private dispatch(): void {
    while (this.pktQueue.length > 0) {
      const pkt = this.pktQueue.shift()!;
      if (pkt.header.command === PacketCommand.HEARTBEAT) {
        this.onHeartbeat(pkt);
        continue;
      }
      if (pkt.header.command === PacketCommand.HEARTBEAT_ACK) continue;

      // 有等待特定命令的 resolver
      if (this.pktResolve && this.pktExpectedCmd !== null) {
        if (pkt.header.command === this.pktExpectedCmd) {
          clearTimeout(this.pktTimer);
          const r = this.pktResolve; const reject = this.pktReject;
          this.clearWait();
          r(pkt);
          continue;
        }
        if (pkt.header.command === PacketCommand.CANCEL) {
          clearTimeout(this.pktTimer);
          const reject = this.pktReject;
          this.clearWait();
          if (reject) reject(new Error('对端取消'));
          continue;
        }
        // 非期待命令，放回等待
        this.pktQueue.unshift(pkt);
        break;
      }

      // 接收方自驱处理
      if (this.role === 2 && this.incomingHandler) {
        this.incomingHandler(pkt);
        continue;
      }

      // 无匹配者，丢弃
      hilog.warn(0x0001, TAG, 'Dropping packet cmd=0x%04x (no waiter)', pkt.header.command);
    }
  }

  private clearWait(): void {
    this.pktResolve = null;
    this.pktReject = null;
    this.pktExpectedCmd = null;
    this.pktTimer = -1;
  }

  private waitCmd(cmd: PacketCommand, ms: number): Promise<Packet> {
    return new Promise<Packet>((resolve, reject) => {
      const idx = this.pktQueue.findIndex((p) => p.header.command === cmd);
      if (idx >= 0) {
        resolve(this.pktQueue.splice(idx, 1)[0]);
        return;
      }
      this.pktExpectedCmd = cmd;
      this.pktResolve = resolve;
      this.pktReject = reject;
      this.pktTimer = setTimeout(() => {
        if (this.pktResolve) {
          this.clearWait();
          reject(new Error(`等待 0x${cmd.toString(16)} 超时`));
        }
      }, ms);
    });
  }

  private onHeartbeat(pkt: Packet): void {
    const ack = encodePacket(PacketCommand.HEARTBEAT_ACK, new ArrayBuffer(0), pkt.header.sequence);
    this.conn?.send({ data: ack }, () => {});
  }

  // ==================== 构建包辅助 ====================

  private buildPkt(cmd: PacketCommand, payload: ArrayBuffer): Packet {
    return {
      header: { magic: 0x54534852, version: 0x0100, command: cmd, payloadLength: payload.byteLength, sequence: this.seqManager.next() },
      payload,
    };
  }

  // ==================== 握手 ====================

  private async doHandshake(): Promise<boolean> {
    for (let i = 0; i < MAX_RETRIES; i++) {
      try {
        await this.sendPkt(buildHandshakeReq(this.deviceName, this.role, this.seqManager));

        const resp = await this.waitCmd(PacketCommand.HANDSHAKE_RESP, HANDSHAKE_TIMEOUT);
        const pl = decodeHandshakePayload(resp.payload);
        const features: Record<string, Object> = JSON.parse(pl.supportedFeatures) as Record<string, Object>;

        if (features['accepted'] === false) {
          hilog.error(0x0001, TAG, 'Handshake rejected');
          return false;
        }

        this.remoteDeviceName = pl.deviceName;
        this.remoteRole = pl.role;
        this.chunkSize = (features['maxChunkSize'] as number) || DEFAULT_CHUNK_SIZE;
        hilog.info(0x0001, TAG, 'Handshake OK: peer=%s role=%d chunk=%d', this.remoteDeviceName, this.remoteRole, this.chunkSize);
        this.emitHandshake(this.remoteDeviceName);
        return true;
      } catch (err) {
        hilog.warn(0x0001, TAG, 'Handshake %d failed: %s', i + 1, (err as Error).message);
        if (i === MAX_RETRIES - 1) return false;
      }
    }
    return false;
  }

  private async waitHandshake(ms: number): Promise<boolean> {
    try {
      const req = await this.waitCmd(PacketCommand.HANDSHAKE_REQ, ms);
      const pl = decodeHandshakePayload(req.payload);
      if (!isCompatibleVersion(pl.protocolVersion)) {
        await this.sendPkt(buildHandshakeResp(this.deviceName, this.role, req.header.sequence, false));
        return false;
      }
      this.remoteDeviceName = pl.deviceName;
      this.remoteRole = pl.role;
      await this.sendPkt(buildHandshakeResp(this.deviceName, this.role, req.header.sequence, true));
      hilog.info(0x0001, TAG, 'Handshake accepted: peer=%s', this.remoteDeviceName);
      this.emitHandshake(this.remoteDeviceName);
      return true;
    } catch (err) {
      hilog.error(0x0001, TAG, 'Wait handshake err: %s', (err as Error).message);
      return false;
    }
  }

  // ==================== 文件列表 ====================

  private async sendFileList(): Promise<boolean> {
    for (let i = 0; i < MAX_RETRIES; i++) {
      try {
        await this.sendPkt(this.buildPkt(PacketCommand.FILE_LIST_INFO, encodeFileListPayload(this.pendingFiles)));
        await this.waitCmd(PacketCommand.FILE_LIST_ACK, 15000);
        return true;
      } catch (_) { hilog.warn(0x0001, TAG, 'File list retry %d', i + 1); }
    }
    return false;
  }

  // ==================== 单个文件传输 ====================

  private async xferFile(fi: FileInfoPayload): Promise<boolean> {
    this.changePhase(TransferPhase.METADATA, `正在发送: ${fi.fileName}`);

    if (!(await this.sendFileInfo(fi))) return false;

    const data = this.getData(fi.fileIndex);
    if (!data || data.byteLength === 0) {
      hilog.error(0x0001, TAG, 'No data for %d: %s', fi.fileIndex, fi.fileName);
      return false;
    }

    this.changePhase(TransferPhase.DATA, `传输中: ${fi.fileName}`);
    if (!(await this.sendChunks(fi.fileIndex, data))) return false;

    if (!(await this.sendDone(fi))) return false;

    this.changePhase(TransferPhase.METADATA, `${fi.fileName} 传输完成`);
    return true;
  }

  private async sendFileInfo(fi: FileInfoPayload): Promise<boolean> {
    for (let i = 0; i < MAX_RETRIES; i++) {
      try {
        await this.sendPkt(this.buildPkt(PacketCommand.FILE_INFO, encodeFileInfoPayload(fi)));
        await this.waitCmd(PacketCommand.FILE_INFO_ACK, 15000);
        return true;
      } catch (_) { hilog.warn(0x0001, TAG, 'File info retry %d', i + 1); }
    }
    return false;
  }

  private async sendDone(fi: FileInfoPayload): Promise<boolean> {
    for (let i = 0; i < MAX_RETRIES; i++) {
      try {
        await this.sendPkt(this.buildPkt(PacketCommand.TRANSFER_DONE,
          encodeTransferDonePayload({ fileIndex: fi.fileIndex, totalBytes: fi.fileSize, checksum: '', status: 0 })));
        await this.waitCmd(PacketCommand.TRANSFER_DONE_ACK, 15000);
        return true;
      } catch (_) { hilog.warn(0x0001, TAG, 'Transfer done retry %d', i + 1); }
    }
    return false;
  }

  private async sendChunks(idx: number, data: ArrayBuffer): Promise<boolean> {
    const total = data.byteLength;
    const chunks = Math.ceil(total / this.chunkSize);
    let sent = 0;
    const t0 = Date.now();
    let lastT = t0, lastB = 0;

    for (let ci = 0; ci < chunks; ci++) {
      const off = ci * this.chunkSize;
      const end = Math.min(off + this.chunkSize, total);
      const chunk = data.slice(off, end);

      let ok = false;
      for (let retry = 0; retry < MAX_RETRIES; retry++) {
        try {
          await this.sendPkt(this.buildPkt(PacketCommand.DATA_CHUNK, encodeDataChunkPayload(idx, off, chunk)));
          const ackPkt = await this.waitCmd(PacketCommand.DATA_ACK, CHUNK_TIMEOUT);
          const ack: DataAckPayload = decodeDataAckPayload(ackPkt.payload);

          if (ack.receivedBytes >= end) {
            ok = true;
            sent = ack.receivedBytes;
            break;
          }
          // 重传请求
          if (ack.retransmitOffset > 0) {
            ci = Math.floor(ack.retransmitOffset / this.chunkSize);
            sent = ack.retransmitOffset;
            ok = true;
            break;
          }
        } catch (_) {
          if (retry === MAX_RETRIES - 1) {
            hilog.error(0x0001, TAG, 'Chunk fail at off=%d after %d retries', off, MAX_RETRIES);
            return false;
          }
        }
      }
      if (!ok) return false;

      const now = Date.now();
      if (now - lastT >= PROGRESS_REPORT_INTERVAL) {
        const spd = (sent - lastB) / ((now - lastT) / 1000);
        this.emitProgress(idx, `${(sent / 1024).toFixed(1)}/${(total / 1024).toFixed(1)} KB`, sent / total, sent, total, spd, total - sent > 0 && spd > 0 ? (total - sent) / spd : -1);
        lastT = now;
        lastB = sent;
      }
    }
    return true;
  }

  private getData(idx: number): ArrayBuffer | null {
    return this.fileDataProvider ? this.fileDataProvider(idx) : null;
  }

  // ==================== 接收方 ====================

  private recvLoop(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      this.recvLoopResolve = resolve;
      this.recvLoopReject = reject;
      this.incomingHandler = (pkt: Packet) => {
        this.handleIncoming(pkt).catch((e: Error) => {
          hilog.error(0x0001, TAG, 'Incoming err: %s', e.message);
          if (this.recvLoopReject) this.recvLoopReject(e);
        });
      };
    });
  }

  private async handleIncoming(pkt: Packet): Promise<void> {
    switch (pkt.header.command) {
      case PacketCommand.FILE_LIST_INFO: {
        const files = decodeFileListPayload(pkt.payload);
        this.rcvFileList = files;
        this.rcvFileData = null;
        this.rcvFileIndex = 0;
        hilog.info(0x0001, TAG, 'Rcv file list: %d files', files.length);
        await this.sendBuf(encodePacket(PacketCommand.FILE_LIST_ACK, new ArrayBuffer(0), pkt.header.sequence));
        this.emit({ type: 'phaseChange', phase: TransferPhase.METADATA, message: `收到 ${files.length} 个文件` });
        this.changePhase(TransferPhase.METADATA, '等待文件数据...');
        break;
      }

      case PacketCommand.FILE_INFO: {
        const fi = decodeFileInfoPayload(pkt.payload);
        this.rcvFileInfo = fi;
        this.rcvFileData = new Uint8Array(fi.fileSize);
        this.rcvFileIndex = fi.fileIndex;
        hilog.info(0x0001, TAG, 'Rcv file: %s size=%d', fi.fileName, fi.fileSize);
        await this.sendBuf(encodePacket(PacketCommand.FILE_INFO_ACK, new ArrayBuffer(0), pkt.header.sequence));
        this.emit({ type: 'phaseChange', phase: TransferPhase.DATA, fileIndex: fi.fileIndex, fileName: fi.fileName, fileSize: fi.fileSize, message: `接收: ${fi.fileName}` });
        this.changePhase(TransferPhase.DATA, `接收中: ${fi.fileName}`);
        break;
      }

      case PacketCommand.DATA_CHUNK: {
        if (!this.rcvFileData || !this.rcvFileInfo) break;
        const chunk = decodeDataChunkPayload(pkt.payload);
        const cd = new Uint8Array(chunk.data);
        this.rcvFileData.set(cd, chunk.offset);

        const endOff = chunk.offset + cd.byteLength;
        const fs = this.rcvFileInfo.fileSize;

        await this.sendBuf(encodePacket(PacketCommand.DATA_ACK,
          encodeDataAckPayload({ fileIndex: this.rcvFileInfo.fileIndex, receivedBytes: Math.min(endOff, fs), retransmitOffset: 0 }), pkt.header.sequence));

        const rcv = Math.min(endOff, fs);
        this.emit({ type: 'progress', fileIndex: this.rcvFileInfo.fileIndex, fileName: this.rcvFileInfo.fileName, fileSize: this.rcvFileInfo.fileSize, transferredBytes: rcv, progress: rcv / fs, message: `接收中... ${(rcv / 1024).toFixed(1)}/${(fs / 1024).toFixed(1)} KB` });
        break;
      }

      case PacketCommand.TRANSFER_DONE: {
        const done = decodeTransferDonePayload(pkt.payload);
        if (this.rcvFileData && this.rcvFileInfo) {
          await this.saveFile(this.rcvFileInfo.fileName, this.rcvFileData);
        }
        await this.sendBuf(encodePacket(PacketCommand.TRANSFER_DONE_ACK, new ArrayBuffer(0), pkt.header.sequence));
        this.rcvFileData = null;
        this.rcvFileInfo = null;
        if (this.rcvFileIndex >= this.rcvFileList.length - 1) {
          this.changePhase(TransferPhase.COMPLETE, '全部文件接收完成');
          if (this.recvLoopResolve) this.recvLoopResolve();
        } else {
          this.rcvFileIndex++;
          this.changePhase(TransferPhase.METADATA, '等待下一个文件...');
        }
        break;
      }

      default:
        hilog.info(0x0001, TAG, 'Unhandled cmd=0x%04x', pkt.header.command);
    }
  }

  // ==================== 文件保存 ====================

  private saveFile(name: string, data: Uint8Array): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      try {
        const dir = '/data/storage/el2/base/files/';
        try { fileIo.mkdirSync(dir); } catch (_) { /* ok */ }
        const path = dir + 'ToShare_' + name;
        const f = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
        fileIo.writeSync(f.fd, data.buffer);
        fileIo.closeSync(f);
        hilog.info(0x0001, TAG, 'Saved: %s size=%d', path, data.length);
        this.emit({ type: 'phaseChange', phase: TransferPhase.METADATA, message: `已保存: ${name}` });
        resolve();
      } catch (err) {
        hilog.error(0x0001, TAG, 'Save err: %s', JSON.stringify(err));
        reject(err);
      }
    });
  }

  // ==================== 清理 ====================

  private cleanup(): void {
    this.stopHeartbeat();
    this.handshakeOk = false;
    this.recvBuf = new Uint8Array(0);
    this.pktQueue = [];
    this.clearWait();
    this.incomingHandler = null;
    this.recvLoopResolve = null;
    this.recvLoopReject = null;
    this.rcvFileData = null;
    this.rcvFileInfo = null;
    this.rcvFileList = [];

    if (this.conn) {
      try { this.conn.off('message'); this.conn.off('close'); this.conn.off('error'); this.conn.close(); } catch (_) { /* ignore */ }
      this.conn = null;
    }
    if (this.tcpServer) {
      try { this.tcpServer.off('connect'); this.tcpServer.close(); } catch (_) { /* ignore */ }
      this.tcpServer = null;
    }
  }

  stop(): void {
    this.cleanup();
    try { wifiManager.removeGroup(); } catch (_) { /* ignore */ }
    this.p2pGroupActive = false;
    this._phase = TransferPhase.IDLE;
    this.eventListeners = [];
    this.seqManager.reset();
    this.pendingFiles = [];
    this.fileDataProvider = null;
  }

  destroy(): void {
    this.stop();
  }
}
