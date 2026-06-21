/**
 * 传输服务 v2 — 文本协议 + HTTP 文件下载
 *
 * 借鉴 CatShare 架构，替代二进制 ShareTransferProtocol：
 *
 *   发送方                             接收方
 *     │                                  │
 *     │  Control TCP :24680              │
 *     │  ── text lines ─────────►        │
 *     │◄── ack ─────────────────         │
 *     │                                  │
 *     │  HTTP GET :24681 /file/{id}      │
 *     │  ◄─────────────────────────────  │
 *     │     streaming file data          │
 *     │                                  │
 *     │  Control TCP :24680              │
 *     │  ── status ──────────────►       │
 *     │◄── ack ─────────────────         │
 */

import { wifiManager } from '@kit.ConnectivityKit';
import { socket } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import http from '@ohos.net.http';
import util from '@ohos.util';
import {
  parseWsMessage, buildWsMessage, buildAck,
  buildVersionNegotiation, buildTaskPayload, buildStatusPayload,
  WsActionName, WsMessageType, PROTOCOL_VERSION,
  TaskFileItem, TaskPayload, StatusPayload,
  TEXT_MSG_TERMINATOR, DEFAULT_HTTP_PORT,
} from '../utils/WSTransferProtocol';
import { CryptoService } from './CryptoService';
import { HttpFileServer } from './HttpFileServer';

const TAG = 'TransportServiceV2';
const CONTROL_PORT = 24680;
const PROGRESS_INTERVAL = 500;
const RESPONSE_TIMEOUT = 30000;

export interface TransportEvent {
  type: string;
  phase?: string;
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

  // 连接
  private role: number = 0; // 1=sender, 2=receiver
  private tcpServer: socket.TCPSocketServer | null = null;
  private conn: socket.TCPSocketConnection | null = null;
  private recvBuf: string = '';
  private pendingAckResolve: ((msg: string) => void) | null = null;
  private pendingAckReject: ((err: Error) => void) | null = null;
  private pendingAckTimer: number = -1;

  // 状态
  private groupActive: boolean = false;
  private _goIp: string = '192.168.49.1';
  private _deviceName: string = 'ToShare';
  private _peerDeviceName: string = '';
  private httpPort: number = DEFAULT_HTTP_PORT;
  private p2pPassphrase: string = 'ToShare123';
  private sessionKey: cryptoFramework.SymKey | null = null;
  private sessionIv: Uint8Array | null = null;
  private encryptionEnabled: boolean = true;

  // 发送方
  private taskFiles: TaskFileItem[] = [];
  private fileDataProvider: ((id: number) => ArrayBuffer | null) | null = null;

  // 接收方
  private rcvTaskPayload: TaskPayload | null = null;

  static getInstance(): TransportService {
    if (!TransportService.instance) {
      TransportService.instance = new TransportService();
    }
    return TransportService.instance;
  }

  get goIp(): string { return this._goIp; }
  get peerDeviceName(): string { return this._peerDeviceName; }
  get port(): number { return CONTROL_PORT; }

  addEventListener(cb: TransportEventCallback): void {
    if (!this.eventListeners.includes(cb)) {
      this.eventListeners.push(cb);
    }
  }

  removeEventListener(cb: TransportEventCallback): void {
    const idx = this.eventListeners.indexOf(cb);
    if (idx >= 0) { this.eventListeners.splice(idx, 1); }
  }

  private emit(evt: TransportEvent): void {
    for (const cb of this.eventListeners) {
      try { cb(evt); } catch (e) {
        hilog.error(0x0001, TAG, 'Event cb err: %{public}s', JSON.stringify(e));
      }
    }
  }

  private emitError(msg: string): void {
    this.emit({ type: 'error', message: msg });
  }

  private emitPhase(phase: string, msg: string): void {
    this.emit({ type: 'phaseChange', phase, message: msg });
  }

  // ==================== TCP 文本控制通道 ====================

  private async setupControlServer(): Promise<boolean> {
    try {
      this.tcpServer = socket.constructTCPSocketServerInstance();
      this.tcpServer.on('connect', (c: socket.TCPSocketConnection) => this.onControlConn(c));
      const addr: socket.NetAddress = { address: '0.0.0.0', port: CONTROL_PORT, family: 1 };
      await new Promise<void>((resolve, reject) => {
        this.tcpServer!.listen(addr, (err) => err ? reject(err) : resolve());
      });
      return true;
    } catch (err) {
      hilog.error(0x0001, TAG, 'Control server start fail: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  private onControlConn(c: socket.TCPSocketConnection): void {
    this.conn = c;
    this.recvBuf = '';

    c.on('message', (info: socket.SocketMessageInfo) => this.onControlData(info));
    c.on('close', () => this.onControlClose());
    c.on('error', (e: Error) => {
      hilog.error(0x0001, TAG, 'Control err: %{public}s', e.message);
      this.emitError('连接异常');
    });

    hilog.info(0x0001, TAG, 'Control connection established');
    this.emitPhase('connected', '控制通道已建立');
  }

  private onControlData(info: socket.SocketMessageInfo): void {
    const raw = new Uint8Array(info.message);
    const text = this.bytesToString(raw);
    this.recvBuf += text;

    // 按行分隔（可能粘包）
    while (true) {
      const nli = this.recvBuf.indexOf(TEXT_MSG_TERMINATOR);
      if (nli < 0) break;
      const line = this.recvBuf.substring(0, nli);
      this.recvBuf = this.recvBuf.substring(nli + 1);
      if (line.length > 0) {
        this.handleLine(line);
      }
    }
  }

  private onControlClose(): void {
    hilog.info(0x0001, TAG, 'Control closed');
    if (this.pendingAckReject) {
      this.pendingAckReject(new Error('连接关闭'));
      this.clearPending();
    }
  }

  private bytesToString(buf: Uint8Array): string {
    let s = '';
    for (let i = 0; i < buf.length; i++) {
      s += String.fromCharCode(buf[i]);
    }
    return s;
  }

  private stringToBytes(s: string): ArrayBuffer {
    const buf = new Uint8Array(s.length);
    for (let i = 0; i < s.length; i++) {
      buf[i] = s.charCodeAt(i);
    }
    return buf.buffer as ArrayBuffer;
  }

  private async sendLine(line: string): Promise<void> {
    if (!this.conn) { throw new Error('No connection'); }
    const data = this.stringToBytes(line + TEXT_MSG_TERMINATOR);
    return new Promise<void>((resolve, reject) => {
      this.conn!.send({ data }, (err) => err ? reject(err) : resolve());
    });
  }

  private async sendAction(name: string, payload?: string, id?: number): Promise<void> {
    await this.sendLine(buildWsMessage('action', id ?? 1, name, payload));
  }

  private async sendAck(id: number, name: string): Promise<void> {
    await this.sendLine(buildAck(id, name));
  }

  private clearPending(): void {
    if (this.pendingAckTimer >= 0) {
      clearTimeout(this.pendingAckTimer);
      this.pendingAckTimer = -1;
    }
    this.pendingAckResolve = null;
    this.pendingAckReject = null;
  }

  private waitAck(name: string, ms?: number): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      this.pendingAckResolve = (line: string) => { this.clearPending(); resolve(line); };
      this.pendingAckReject = (err: Error) => { this.clearPending(); reject(err); };
      this.pendingAckTimer = setTimeout(() => {
        if (this.pendingAckReject) {
          this.pendingAckReject(new Error(`等待 ack:${name} 超时`));
          this.clearPending();
        }
      }, ms ?? RESPONSE_TIMEOUT);
    });
  }

  private handleLine(line: string): void {
    const msg = parseWsMessage(line);
    if (msg === null) { return; }

    // ACK 匹配
    if (msg.type === 'ack' && this.pendingAckResolve) {
      this.pendingAckResolve(line);
      return;
    }

    // 接收方处理 action 消息
    if (this.role === 2) {
      this.handleAction(msg.type, msg.id, msg.name, msg.payload).catch((e: Error) => {
        hilog.error(0x0001, TAG, 'Handle action fail: %{public}s', e.message);
      });
    }
  }

  // ==================== P2P 群组 ====================

  private async ensureP2pGroup(): Promise<boolean> {
    return new Promise<boolean>((resolve) => {
      try {
        const cfg: wifiManager.WifiP2PConfig = {
          deviceAddress: '00:00:00:00:00:00',
          deviceAddressType: 1,
          netId: -2,
          passphrase: this.p2pPassphrase,
          groupName: `ToShare_${Date.now() % 100000}`,
          goBand: 0,
        };
        let done = false;
        const cb = () => { if (!done) { done = true; wifiManager.off('p2pPersistentGroupChange', cb); this.groupActive = true; resolve(true); } };
        wifiManager.on('p2pPersistentGroupChange', cb);
        wifiManager.createGroup(cfg);
        setTimeout(() => { if (!done) { done = true; wifiManager.off('p2pPersistentGroupChange', cb); this.groupActive = true; resolve(true); } }, 15000);
      } catch (err) {
        hilog.error(0x0001, TAG, 'Create group err: %{public}s', JSON.stringify(err));
        resolve(false);
      }
    });
  }

  private async waitP2pConnection(ms: number): Promise<boolean> {
    return new Promise<boolean>((resolve) => {
      const t = setTimeout(() => { wifiManager.off('p2pConnectionChange', cb); resolve(false); }, ms);
      const cb = (info: wifiManager.WifiP2pLinkedInfo) => {
        if (info.connectState === 1) { clearTimeout(t); wifiManager.off('p2pConnectionChange', cb); resolve(true); }
      };
      wifiManager.on('p2pConnectionChange', cb);
    });
  }

  private async waitControlConn(ms: number): Promise<boolean> {
    if (!this.tcpServer) return false;
    return new Promise<boolean>((resolve) => {
      if (this.conn) { resolve(true); return; }
      const t = setTimeout(() => resolve(false), ms);
      this.tcpServer!.on('connect', () => { clearTimeout(t); resolve(true); });
    });
  }

  // ==================== HTTP 文件服务 ====================

  private async startHttpServer(): Promise<boolean> {
    return HttpFileServer.getInstance().start(this.httpPort);
  }

  // ==================== Sender API ====================

  async startAsSender(files: TaskFileItem[], dataProvider?: (id: number) => ArrayBuffer | null): Promise<void> {
    this.role = 1;
    this.taskFiles = files;
    this.fileDataProvider = dataProvider ?? null;
    this.recvBuf = '';

    try {
      // 1. P2P 群组
      this.emitPhase('handshake', '正在创建 P2P 通道...');
      if (!(await this.ensureP2pGroup())) {
        this.emitError('创建 P2P 群组失败');
        return;
      }

      // 2. 注册文件到 HTTP 服务器（写临时文件，供接收方 HTTP GET）
      this.emitPhase('handshake', '准备文件...');
      HttpFileServer.getInstance().clearMemoryFiles();

      // P1: 加密——从 P2P 口令派生密钥
      this.sessionKey = await CryptoService.getInstance().deriveKeyFromPassphrase(this.p2pPassphrase);
      this.sessionIv = await CryptoService.getInstance().generateIv();

      for (let i = 0; i < this.taskFiles.length; i++) {
        const f = this.taskFiles[i];
        let rawData = this.fileDataProvider ? this.fileDataProvider(f.id) : null;
        if (rawData === null) {
          this.emitError(`无法读取文件: ${f.name}`);
          return;
        }
        let fileBytes = new Uint8Array(rawData);

        // 计算文件哈希用于完整性校验
        f.hash = await CryptoService.getInstance().hashFile(fileBytes);

        if (this.encryptionEnabled) {
          fileBytes = await CryptoService.getInstance().encrypt(fileBytes, this.sessionKey, this.sessionIv);
          hilog.info(0x0001, TAG, 'Encrypted %s: %d -> %d', f.name, rawData.byteLength, fileBytes.length);
        }

        HttpFileServer.getInstance().registerMemoryFile(f.name, fileBytes);
      }

      // 3. 启动 HTTP 文件服务（供接收方下载文件）
      this.emitPhase('handshake', '启动文件服务...');
      if (!(await this.startHttpServer())) {
        this.emitError('启动文件服务失败');
        return;
      }

      // 4. 启动控制 TCP server
      if (!(await this.setupControlServer())) {
        this.emitError('启动控制通道失败');
        return;
      }

      this.emitPhase('handshake', `等待连接... ${this._goIp}:${CONTROL_PORT}`);

      // 5. 等待 P2P 连接 + TCP 连接
      if (!(await this.waitP2pConnection(60000))) {
        this.emitError('P2P 连接超时');
        return;
      }
      if (!(await this.waitControlConn(60000))) {
        this.emitError('控制连接超时');
        return;
      }

      // 6. 版本协商
      this.emitPhase('handshake', '版本协商...');
      await this.sendLine(buildVersionNegotiation(0));
      await this.waitAck('versionNegotiation');

      // 6. 发送任务信息
      this.emitPhase('metadata', '发送任务信息...');
      const httpFiles = HttpFileServer.getInstance().fileList;
      const ivHex = this.bytesToHex(this.sessionIv);
      const taskPayloadStr = buildTaskPayload(
        Date.now().toString(),
        this._deviceName,
        this.taskFiles,
        undefined,
        this.httpPort,
        this.encryptionEnabled,
        ivHex,
      );
      await this.sendLine('action:1:task?' + taskPayloadStr);
      const ack = await this.waitAck('task');
      const ackMsg = parseWsMessage(ack);
      if (ackMsg === null) {
        this.emitError('任务响应解析失败');
        return;
      }
      if (ackMsg.payload !== undefined && ackMsg.payload['accepted'] === false) {
        this.emitError('对方拒绝任务');
        return;
      }

      // 7. 等待接收方下载完成
      this.emitPhase('data', '等待接收方下载文件...');
      for (let i = 0; i < this.taskFiles.length; i++) {
        const f = this.taskFiles[i];

        // 每个文件发送 download 通知，接收方开始 HTTP 拉取
        await this.sendLine('action:' + (i + 1) + ':download?{"fileId":' + f.id + ',"fileName":"' + f.name + '"}');
        const dlAck = await this.waitAck('download');
        if (dlAck === '') { /* continue */ }
      }

      // 8. 等待传输完成
      const doneMsg = await this.waitAck('done');
      const donePayload = parseWsMessage(doneMsg);
      if (donePayload !== null) {
        this.emit({ type: 'phaseChange', phase: 'complete', message: '全部文件传输完成' });
      }

    } catch (err) {
      hilog.error(0x0001, TAG, 'Sender error: %{public}s', JSON.stringify(err));
      this.emitError(`传输异常: ${(err as Error).message}`);
    } finally {
      this.cleanup();
    }
  }

  // ==================== Receiver API ====================

  async startAsReceiver(): Promise<void> {
    this.role = 2;
    this.recvBuf = '';

    try {
      // 1. P2P 群组
      this.emitPhase('handshake', '正在创建 P2P 通道...');
      if (!(await this.ensureP2pGroup())) {
        this.emitError('创建 P2P 群组失败');
        return;
      }

      this.emitPhase('handshake', '等待设备连接...');
      if (!(await this.waitP2pConnection(60000))) {
        this.emitError('P2P 连接超时');
        return;
      }

      // 2. 控制 TCP server
      if (!(await this.setupControlServer())) {
        this.emitError('启动控制通道失败');
        return;
      }

      this.emitPhase('handshake', `等待发送方连接... ${this._goIp}:${CONTROL_PORT}`);
      if (!(await this.waitControlConn(60000))) {
        this.emitError('控制连接超时');
        return;
      }

      // 3. 等待发送方发消息 —— 由 handleAction 处理
      this.emitPhase('metadata', '等待任务信息...');

      // 4. 等待 done 信号或连接关闭
      while (this.conn !== null) {
        await this.waitAck('done', 5000).catch(() => {});
        break;
      }

    } catch (err) {
      hilog.error(0x0001, TAG, 'Receiver error: %{public}s', JSON.stringify(err));
      this.emitError(`接收异常: ${(err as Error).message}`);
    } finally {
      this.cleanup();
    }
  }

  private async handleAction(type: string, id: number, name: string, payload?: Record<string, Object>): Promise<void> {
    // 发送 ACK
    await this.sendAck(id, name);

    switch (name) {
      case 'versionNegotiation':
        // 版本协商自动回复 ACK
        break;

      case 'task': {
        // 收到任务信息
        this.rcvTaskPayload = payload as object as TaskPayload;
        const task = this.rcvTaskPayload;
        this._peerDeviceName = task.senderName;
        this.emitPhase('metadata', `从 ${task.senderName} 收到 ${task.fileCount} 个文件`);

        // P1: 处理内嵌文本（catShareText）
        if (task.catShareText !== undefined && task.catShareText.length > 0) {
          this.emit({ type: 'textReceived', message: task.catShareText, fileName: 'message.txt' });
          // 保存为文本文件
          const encoder = new util.TextEncoder();
          const textData = encoder.encodeInto(task.catShareText);
          this.saveFile('ToShare_Text_' + Date.now() + '.txt', new Uint8Array(textData));
        }
        break;
      }

      case 'download': {
        const fileId = (payload?.['fileId'] as number) ?? -1;
        const fileName = (payload?.['fileName'] as string) ?? 'unknown';

        this.emitPhase('data', `下载: ${fileName}`);
        this.emit({ type: 'progress', fileIndex: fileId, fileName, message: '下载中...' });

        const task = this.rcvTaskPayload;
        if (task !== null && task.httpPort !== undefined) {
          const fileUrl = `http://${this._goIp}:${task.httpPort}/download?n=${encodeURIComponent(fileName)}`;

          try {
            const httpRequest = http.createHttp();
            const response = await new Promise<http.HttpResponse>((resolve, reject) => {
              httpRequest.request(fileUrl, (err: Error, data: http.HttpResponse) => {
                if (err) { reject(err); } else { resolve(data); }
              });
            });
            let buf = response.result as ArrayBuffer;
            let fileBytes = new Uint8Array(buf);

            // P1: 解密（如果任务标记为加密）
            if (task.encrypted === true && task.iv !== undefined) {
              const iv = this.hexToBytes(task.iv);
              const key = await CryptoService.getInstance().deriveKeyFromPassphrase(this.p2pPassphrase);
              try {
                fileBytes = await CryptoService.getInstance().decrypt(fileBytes, key, iv);
                this.emit({ type: 'progress', fileIndex: fileId, fileName, message: `${fileName} 解密完成` });
              } catch (_decErr) {
                hilog.error(0x0001, TAG, 'Decrypt fail, trying raw: %{public}s', (_decErr as Error).message);
                // 解密失败则保存原始数据
              }
            }

            await this.saveFile(fileName, fileBytes);
            this.emit({ type: 'progress', fileIndex: fileId, fileName, message: `${fileName} 已完成`, progress: 1 });
            httpRequest.destroy();
          } catch (err) {
            hilog.error(0x0001, TAG, 'HTTP download fail: %{public}s', JSON.stringify(err));
            this.emitError(`下载失败: ${(err as Error).message}`);
          }
        }
        break;
      }

      case 'status': {
        const st = payload as Record<string, Object> | undefined;
        if (st !== undefined) {
          this.emit({ type: 'status', message: (st['reason'] as string) ?? '', progress: (st['progress'] as number) ?? 0 });
        }
        break;
      }

      case 'done': {
        this.emitPhase('complete', '全部文件接收完成');
        break;
      }

      case 'cancel': {
        this.emitError('对方取消了传输');
        break;
      }
    }
  }

  // ==================== 文件保存 ====================

  private async saveFile(name: string, data: Uint8Array): Promise<void> {
    const dir = '/data/storage/el2/base/files/';
    try { fileIo.mkdirSync(dir); } catch (_e) { /* ok */ }
    const path = dir + 'ToShare_' + name;
    const fd = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
    try {
      fileIo.writeSync(fd.fd, data.buffer as ArrayBuffer);
      hilog.info(0x0001, TAG, 'Saved: %s size=%d', path, data.length);
    } finally {
      fileIo.closeSync(fd);
    }
  }

  // ==================== 清理 ====================

  private cleanup(): void {
    this.recvBuf = '';
    this.clearPending();
    if (this.conn) {
      try { this.conn.off('message'); this.conn.off('close'); this.conn.off('error'); this.conn.close(); } catch (_e) { /**/ }
      this.conn = null;
    }
    if (this.tcpServer) {
      try { this.tcpServer.off('connect'); this.tcpServer.close(); } catch (_e) { /**/ }
      this.tcpServer = null;
    }
    HttpFileServer.getInstance().stop();
    this.rcvTaskPayload = null;
  }

  stop(): void {
    this.cleanup();
    try { wifiManager.removeGroup(); } catch (_e) { /**/ }
    this.groupActive = false;
    this.eventListeners = [];
    this.taskFiles = [];
    this.fileDataProvider = null;
  }

  destroy(): void {
    this.stop();
  }

  private bytesToHex(bytes: Uint8Array): string {
    let hex = '';
    for (let i = 0; i < bytes.length; i++) {
      hex += bytes[i].toString(16).padStart(2, '0');
    }
    return hex;
  }

  private hexToBytes(hex: string): Uint8Array {
    const bytes = new Uint8Array(Math.ceil(hex.length / 2));
    for (let i = 0; i < bytes.length; i++) {
      const idx = i * 2;
      bytes[i] = parseInt(hex.substring(idx, idx + 2), 16);
    }
    return bytes;
  }
}
