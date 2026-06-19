/**
 * 文件传输服务——UI层适配器
 *
 * 协调 FilePickerService（文件选择）和 TransportService，为 UI 层提供统一 API。
 *
 * 发送方: select file → read → dataProvider → TransportService.startAsSender
 * 接收方: TransportService.startAsReceiver → auto-save
 */

import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  TransportService,
  TransferPhase,
  TransportEvent,
  TransportEventCallback,
} from './TransportService';
import { FileInfoPayload } from '../utils/ShareTransferProtocol';

const TAG = 'FileTransferService';

export { TransferPhase };

export enum TransferState {
  IDLE = 'idle',
  CREATING_GROUP = 'creating_group',
  GROUP_CREATED = 'group_created',
  P2P_CONNECTING = 'p2p_connecting',
  P2P_CONNECTED = 'p2p_connected',
  SOCKET_LISTENING = 'socket_listening',
  HANDSHAKE = 'handshake',
  HANDSHAKE_DONE = 'handshake_done',
  METADATA = 'metadata',
  TRANSFERRING = 'transferring',
  COMPLETED = 'completed',
  ERROR = 'error',
}

export class TransferStatusCallback {
  onStatusChange: (state: TransferState, message?: string, progress?: number) => void;

  constructor(cb: (state: TransferState, message?: string, progress?: number) => void) {
    this.onStatusChange = cb;
  }
}

export class SendFileInfo {
  uri: string = '';
  name: string = '';
  size: number = 0;

  constructor(uri: string, name: string, size: number) {
    this.uri = uri;
    this.name = name;
    this.size = size;
  }
}

export class FileTransferService {
  private static instance: FileTransferService;
  private _state: TransferState = TransferState.IDLE;
  private listeners: TransferStatusCallback[] = [];
  private transport: TransportService;
  private transportCb: TransportEventCallback | null = null;
  private fileIndexCount: number = 0;
  private fileTotalCount: number = 0;

  static getInstance(): FileTransferService {
    if (!FileTransferService.instance) {
      FileTransferService.instance = new FileTransferService();
    }
    return FileTransferService.instance;
  }

  constructor() {
    this.transport = TransportService.getInstance();
    this.bindListener();
  }

  get state(): TransferState { return this._state; }
  get groupIp(): string { return this.transport.goIp; }
  get port(): number { return this.transport.port; }

  addListener(cb: TransferStatusCallback): void {
    if (!this.listeners.includes(cb)) this.listeners.push(cb);
  }

  removeListener(cb: TransferStatusCallback): void {
    const i = this.listeners.indexOf(cb);
    if (i >= 0) this.listeners.splice(i, 1);
  }

  private notify(state: TransferState, msg?: string, p?: number): void {
    this._state = state;
    for (const l of this.listeners) {
      try { l.onStatusChange(state, msg, p); } catch (e) {
        hilog.error(0x0001, TAG, 'notify err: %s', JSON.stringify(e));
      }
    }
  }

  private bindListener(): void {
    this.transportCb = (e: TransportEvent) => this.onEvent(e);
    this.transport.addEventListener(this.transportCb);
  }

  private onEvent(e: TransportEvent): void {
    if (e.type === 'phaseChange') {
      this.onPhase(e);
    } else if (e.type === 'progress') {
      const p = e.progress || 0;
      const msg = e.message || '';
      this.notify(TransferState.TRANSFERRING, msg, p);
      if (this.fileTotalCount > 0 && this.fileIndexCount > 0) {
        this.notify(TransferState.TRANSFERRING, msg, (this.fileIndexCount + p) / this.fileTotalCount);
      }
    } else if (e.type === 'handshake') {
      this.notify(TransferState.HANDSHAKE_DONE, e.message);
    } else if (e.type === 'complete') {
      this.notify(TransferState.COMPLETED, e.message, 1.0);
    } else if (e.type === 'error') {
      this.notify(TransferState.ERROR, e.message);
    }
  }

  private onPhase(e: TransportEvent): void {
    const ph = e.phase;
    const msg = e.message || '';
    if (ph === TransferPhase.IDLE) { this.notify(TransferState.IDLE); }
    else if (ph === TransferPhase.HANDSHAKE) {
      if (msg.includes('Wi-Fi Direct') || msg.includes('通道')) { this.notify(TransferState.CREATING_GROUP, msg); }
      else if (msg.includes('等待')) { this.notify(TransferState.P2P_CONNECTING, msg); }
      else { this.notify(TransferState.HANDSHAKE, msg); }
    } else if (ph === TransferPhase.METADATA) { this.notify(TransferState.METADATA, msg); }
    else if (ph === TransferPhase.DATA) { this.notify(TransferState.TRANSFERRING, msg, e.progress); }
    else if (ph === TransferPhase.COMPLETE) { this.notify(TransferState.COMPLETED, msg, 1.0); }
    else if (ph === TransferPhase.ERROR) { this.notify(TransferState.ERROR, msg); }
  }

  // ==================== 发送方 ====================

  async startAsSender(fileUri: string, fileName: string, fileSize?: number): Promise<void> {
    this.fileIndexCount = 0;
    this.fileTotalCount = 1;

    this.notify(TransferState.CREATING_GROUP, '正在创建连接通道...');

    try {
      let actualSize = fileSize || 0;
      if (actualSize <= 0) {
        try { actualSize = fileIo.statSync(fileUri).size; } catch (_) { /* keep 0 */ }
      }

      this.notify(TransferState.METADATA, `读取文件: ${fileName}`);
      const data = await this.readFile(fileUri);
      if (!data) { this.notify(TransferState.ERROR, '文件读取失败'); return; }

      const fi: FileInfoPayload = {
        fileCount: 1, fileIndex: 0, fileName, fileSize: data.byteLength,
        mimeType: this.mimeType(fileName), fileHash: '',
      };

      await this.transport.startAsSender([fi], () => data);
    } catch (err) {
      hilog.error(0x0001, TAG, 'sender err: %s', JSON.stringify(err));
      this.notify(TransferState.ERROR, `发送失败: ${(err as Error).message}`);
    }
  }

  async startAsSenderMulti(files: SendFileInfo[]): Promise<void> {
    this.fileIndexCount = 0;
    this.fileTotalCount = files.length;

    this.notify(TransferState.CREATING_GROUP, '正在准备文件...');

    try {
      this.notify(TransferState.METADATA, `读取 ${files.length} 个文件...`);
      const infos: FileInfoPayload[] = [];
      const dataMap = new Map<number, ArrayBuffer>();

      for (let i = 0; i < files.length; i++) {
        const f = files[i];
        const data = await this.readFile(f.uri);
        if (!data) { this.notify(TransferState.ERROR, `读取失败: ${f.name}`); return; }
        infos.push({
          fileCount: files.length, fileIndex: i, fileName: f.name,
          fileSize: data.byteLength, mimeType: this.mimeType(f.name), fileHash: f.uri,
        });
        dataMap.set(i, data);
      }

      await this.transport.startAsSender(infos, (idx: number) => dataMap.get(idx) || null);
    } catch (err) {
      hilog.error(0x0001, TAG, 'multi sender err: %s', JSON.stringify(err));
      this.notify(TransferState.ERROR, `发送失败: ${(err as Error).message}`);
    }
  }

  // ==================== 接收方 ====================

  async startAsReceiver(): Promise<void> {
    this.notify(TransferState.CREATING_GROUP, '正在创建连接通道...');
    try {
      await this.transport.startAsReceiver();
    } catch (err) {
      hilog.error(0x0001, TAG, 'receiver err: %s', JSON.stringify(err));
      this.notify(TransferState.ERROR, `启动接收失败: ${(err as Error).message}`);
    }
  }

  // ==================== 文件 I/O ====================

  private async readFile(uri: string): Promise<ArrayBuffer | null> {
    try {
      const f = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const buf = new ArrayBuffer(fileIo.statSync(uri).size);
      fileIo.readSync(f.fd, buf);
      fileIo.closeSync(f);
      return buf;
    } catch (err) {
      hilog.error(0x0001, TAG, 'read err: %s uri=%s', JSON.stringify(err), uri);
      return null;
    }
  }

  private mimeType(name: string): string {
    const ext = name.split('.').pop()?.toLowerCase() || '';
    if (ext === 'jpg' || ext === 'jpeg') return 'image/jpeg';
    if (ext === 'png') return 'image/png';
    if (ext === 'gif') return 'image/gif';
    if (ext === 'webp') return 'image/webp';
    if (ext === 'mp4') return 'video/mp4';
    if (ext === 'mkv') return 'video/x-matroska';
    if (ext === 'mp3') return 'audio/mpeg';
    if (ext === 'pdf') return 'application/pdf';
    if (ext === 'doc' || ext === 'docx') return 'application/msword';
    if (ext === 'zip') return 'application/zip';
    if (ext === 'rar') return 'application/vnd.rar';
    if (ext === '7z') return 'application/x-7z-compressed';
    if (ext === 'txt') return 'text/plain';
    if (ext === 'html') return 'text/html';
    if (ext === 'js') return 'text/javascript';
    if (ext === 'ts') return 'text/typescript';
    if (ext === 'json') return 'application/json';
    return 'application/octet-stream';
  }

  // ==================== 控制 ====================

  stop(): void {
    if (this.transportCb) this.transport.removeEventListener(this.transportCb);
    this.transport.stop();
    this._state = TransferState.IDLE;
    this.bindListener();
  }

  destroy(): void {
    this.stop();
    this.listeners = [];
  }
}
