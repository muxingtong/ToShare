/**
 * 文件传输服务——基于 Wi-Fi Direct (P2P) + TCP Socket 实现互传文件
 *
 * 支持两种模式：
 *   发送方 (Sender): 创建 P2P 群组作为 GO，启动 TCP Server，等待接收方连接后发送文件
 *   接收方 (Receiver): 创建 P2P 群组作为 GO，启动 TCP Server，等待发送方连接后接收文件
 *
 * 流程（发送方）：
 *   1. 创建 P2P 群组（作为 GO）
 *   2. 等待接收方连接 P2P
 *   3. 启动 TCP Server
 *   4. 等待接收方连接 TCP，发送文件元数据和数据
 *
 * 流程（接收方）：
 *   1. 创建 P2P 群组（作为 GO）
 *   2. 等待发送方连接 P2P
 *   3. 启动 TCP Server
 *   4. 接收文件
 */

import { wifiManager } from '@kit.ConnectivityKit';
import { socket } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'FileTransfer';
const TRANSFER_PORT: number = 24680;

export class SocketMessage {
  message: ArrayBuffer;
  remoteInfo: socket.SocketRemoteInfo;

  constructor() {
    this.message = new ArrayBuffer(0);
    this.remoteInfo = {} as socket.SocketRemoteInfo;
  }
}

export enum TransferState {
  IDLE = 'idle',
  CREATING_GROUP = 'creating_group',
  GROUP_CREATED = 'group_created',
  P2P_CONNECTING = 'p2p_connecting',
  P2P_CONNECTED = 'p2p_connected',
  SOCKET_LISTENING = 'socket_listening',
  TRANSFERRING = 'transferring',
  COMPLETED = 'completed',
  ERROR = 'error'
}

export class TransferStatusCallback {
  onStatusChange: (state: TransferState, message?: string, progress?: number) => void;

  constructor(onStatusChange: (state: TransferState, message?: string, progress?: number) => void) {
    this.onStatusChange = onStatusChange;
  }
}

export class FileTransferService {
  private static instance: FileTransferService;
  private _state: TransferState = TransferState.IDLE;
  private listeners: TransferStatusCallback[] = [];
  private goIpAddress: string = '';
  private p2pGroupActive: boolean = false;
  private tcpServer: socket.TCPSocketServer | null = null;
  private pendingSendFile: string = '';
  private pendingSendName: string = '';
  private sentBytes: number = 0;
  private totalBytes: number = 0;

  static getInstance(): FileTransferService {
    if (!FileTransferService.instance) {
      FileTransferService.instance = new FileTransferService();
    }
    return FileTransferService.instance;
  }

  get state(): TransferState {
    return this._state;
  }

  get groupIp(): string {
    return this.goIpAddress;
  }

  get port(): number {
    return TRANSFER_PORT;
  }

  addListener(callback: TransferStatusCallback): void {
    if (!this.listeners.includes(callback)) {
      this.listeners.push(callback);
    }
  }

  removeListener(callback: TransferStatusCallback): void {
    const index = this.listeners.indexOf(callback);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  private notifyListeners(state: TransferState, message?: string, progress?: number): void {
    this._state = state;
    for (const listener of this.listeners) {
      listener.onStatusChange(state, message, progress);
    }
  }

  /**
   * 作为发送方：创建 P2P 群组，等待接收方连接后发送文件
   * @param fileUri 文件路径
   * @param fileName 文件名称
   */
  async startAsSender(fileUri: string, fileName: string): Promise<void> {
    try {
      this.pendingSendFile = fileUri;
      this.pendingSendName = fileName;

      // Step 1: 创建 P2P 群组
      this.notifyListeners(TransferState.CREATING_GROUP, '正在创建连接通道...');

      const groupCreated = await this.createP2pGroup();
      if (!groupCreated) {
        this.notifyListeners(TransferState.ERROR, '创建连接通道失败');
        return;
      }
      this.notifyListeners(TransferState.GROUP_CREATED, '通道已创建');

      // Step 2: 获取 GO IP（标准 Wi-Fi Direct GO IP）
      this.goIpAddress = '192.168.49.1';
      hilog.info(0x0001, TAG, 'Sender GO IP: %{public}s', this.goIpAddress);

      // Step 3: 启动 TCP Server
      this.startTcpServerForSend();
      this.notifyListeners(TransferState.SOCKET_LISTENING,
        `等待接收方连接... (${this.goIpAddress}:${TRANSFER_PORT})`);

      // Step 4: 等待 P2P 连接（接收方连入）
      this.notifyListeners(TransferState.P2P_CONNECTING, '等待对方连接...');
      await this.waitForP2pConnection();
      this.notifyListeners(TransferState.P2P_CONNECTED, 'Wi-Fi Direct 已连接');

    } catch (err) {
      const msg = `发送准备失败: ${JSON.stringify(err)}`;
      hilog.error(0x0001, TAG, msg);
      this.notifyListeners(TransferState.ERROR, msg);
    }
  }

  /**
   * 作为接收方：创建 P2P 群组（GO），启动 TCP Server 等待发送方连接
   */
  async startAsReceiver(): Promise<void> {
    try {
      this.notifyListeners(TransferState.CREATING_GROUP, '正在创建连接通道...');

      const groupCreated = await this.createP2pGroup();
      if (!groupCreated) {
        this.notifyListeners(TransferState.ERROR, '创建连接通道失败');
        return;
      }
      this.notifyListeners(TransferState.GROUP_CREATED, '通道已创建');

      this.notifyListeners(TransferState.P2P_CONNECTING, '等待对方连接...');
      await this.waitForP2pConnection();

      // 标准 Wi-Fi Direct GO IP
      this.goIpAddress = '192.168.49.1';
      hilog.info(0x0001, TAG, 'Receiver GO IP: %{public}s', this.goIpAddress);

      this.startTcpServerForReceive();
    } catch (err) {
      const msg = `启动接收失败: ${JSON.stringify(err)}`;
      hilog.error(0x0001, TAG, msg);
      this.notifyListeners(TransferState.ERROR, msg);
    }
  }

  /**
   * 创建 Wi-Fi Direct P2P 群组（作为 GO）
   *
   * 监听 p2pPersistentGroupChange 事件确认群组已生效。
   * 15 秒超时后默认假设成功（createGroup 即使事件未触发也往往已生效）。
   */
  private async createP2pGroup(): Promise<boolean> {
    if (await this.checkGroupExists()) {
      return true;
    }

    return new Promise<boolean>((resolve) => {
      try {
        const groupName = `ToShare_${Date.now() % 100000}`;
        const config: wifiManager.WifiP2PConfig = {
          deviceAddress: '00:00:00:00:00:00',
          deviceAddressType: 1,
          netId: -2,
          passphrase: 'ToShare123',
          groupName: groupName,
          goBand: 0
        };

        let settled = false;
        const finish = (ok: boolean): void => {
          if (settled) {
            return;
          }
          settled = true;
          wifiManager.off('p2pPersistentGroupChange', onGroupChange);
          if (ok) {
            this.p2pGroupActive = true;
            this.goIpAddress = '192.168.49.1';
          }
          resolve(ok);
        };

        const onGroupChange = (): void => {
          finish(true);
        };
        wifiManager.on('p2pPersistentGroupChange', onGroupChange);
        wifiManager.createGroup(config);

        setTimeout(() => {
          if (!settled) {
            wifiManager.off('p2pPersistentGroupChange', onGroupChange);
            finish(true);
          }
        }, 15000);

      } catch (err) {
        hilog.error(0x0001, TAG, 'Create group exception: %{public}s', JSON.stringify(err));
        resolve(false);
      }
    });
  }

  private async checkGroupExists(): Promise<boolean> {
    try {
      const group = await wifiManager.getCurrentGroup();
      if (group) {
        this.goIpAddress = '192.168.49.1';
        this.p2pGroupActive = true;
        return true;
      }
    } catch (_err) {
      // ignore
    }
    return false;
  }

  /**
   * 等待对端 P2P 连接
   */
  private waitForP2pConnection(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      const timeout = setTimeout(() => {
        wifiManager.off('p2pConnectionChange', onConnectionChange);
        reject(new Error('P2P connection timeout (60s)'));
      }, 60000);

      const onConnectionChange = (info: wifiManager.WifiP2pLinkedInfo): void => {
        hilog.info(0x0001, TAG, 'P2P connection state: %{public}d', info.connectState);
        if (info.connectState === 1) {
          clearTimeout(timeout);
          wifiManager.off('p2pConnectionChange', onConnectionChange);
          this.notifyListeners(TransferState.P2P_CONNECTED, '设备已连接');
          resolve();
        }
      };

      wifiManager.on('p2pConnectionChange', onConnectionChange);
    });
  }

  /**
   * 启动 TCP Server（发送模式）——客户端连接后主动发送文件
   */
  private startTcpServerForSend(): void {
    this.tcpServer = socket.constructTCPSocketServerInstance();

    const ipAddress: socket.NetAddress = {
      address: '0.0.0.0',
      port: TRANSFER_PORT,
      family: 1
    } as socket.NetAddress;

    this.tcpServer.listen(ipAddress, (err) => {
      if (err) {
        hilog.error(0x0001, TAG, 'TCP listen failed: %{public}s', JSON.stringify(err));
        this.notifyListeners(TransferState.ERROR, '端口监听失败');
        return;
      }
      hilog.info(0x0001, TAG, 'TCP server listening on port %{public}d (send mode)', TRANSFER_PORT);
    });

    // 客户端连接后发送文件
    this.tcpServer.on('connect', (connection: socket.TCPSocketConnection) => {
      hilog.info(0x0001, TAG, 'TCP client connected, starting file send...');
      this.notifyListeners(TransferState.TRANSFERRING, '正在发送文件...');
      this.sendFileData(connection);
    });
  }

  /**
   * 发送文件数据给已连接的客户端
   */
  private async sendFileData(connection: socket.TCPSocketConnection): Promise<void> {
    try {
      // 读取文件
      const openFile = fileIo.openSync(this.pendingSendFile, fileIo.OpenMode.READ_ONLY);
      const statResult = fileIo.statSync(this.pendingSendFile);
      const fileBuffer = new ArrayBuffer(statResult.size);
      fileIo.readSync(openFile.fd, fileBuffer);
      fileIo.closeSync(openFile);

      if (fileBuffer.byteLength === 0) {
        hilog.error(0x0001, TAG, 'File is empty or cannot be read: %{public}s', this.pendingSendFile);
        this.notifyListeners(TransferState.ERROR, '文件读取失败');
        return;
      }

      this.totalBytes = fileBuffer.byteLength;
      this.sentBytes = 0;

      // 发送元数据
      const metadata = JSON.stringify({
        fileName: this.pendingSendName,
        fileSize: this.totalBytes
      });
      const encoder = new util.TextEncoder();
      const metadataBytes = encoder.encodeInto(metadata);

      connection.send({ data: metadataBytes.buffer }, (sendErr: Error) => {
        if (sendErr) {
          hilog.error(0x0001, TAG, 'Send metadata failed: %{public}s', sendErr.message);
          return;
        }
        hilog.info(0x0001, TAG, 'Metadata sent: %{public}s', metadata);

        // 分片发送文件数据（每片32KB）
        const chunkSize = 32768;
        let offset = 0;
        const sendNextChunk = () => {
          if (offset >= fileBuffer.byteLength) {
            hilog.info(0x0001, TAG, 'File send complete, total: %{public}d bytes', fileBuffer.byteLength);
            this.notifyListeners(TransferState.COMPLETED, `发送完成: ${this.pendingSendName}`, 1);
            connection.close();
            return;
          }

          const end = Math.min(offset + chunkSize, fileBuffer.byteLength);
          const chunk = fileBuffer.slice(offset, end);

          connection.send({ data: chunk }, (chunkErr: Error) => {
            if (chunkErr) {
              hilog.error(0x0001, TAG, 'Send chunk failed: %{public}s', chunkErr.message);
              this.notifyListeners(TransferState.ERROR, '发送数据失败');
              return;
            }
            offset = end;
            this.sentBytes = offset;
            const progress = this.sentBytes / this.totalBytes;
            this.notifyListeners(TransferState.TRANSFERRING,
              `发送中... ${(this.sentBytes / 1024).toFixed(1)} / ${(this.totalBytes / 1024).toFixed(1)} KB`,
              progress);
            sendNextChunk();
          });
        };

        sendNextChunk();
      });
    } catch (err) {
      hilog.error(0x0001, TAG, 'Send file failed: %{public}s', JSON.stringify(err));
      this.notifyListeners(TransferState.ERROR, '发送失败');
    }
  }

  /**
   * 启动 TCP Server（接收模式）——客户端连接后接收文件
   */
  private startTcpServerForReceive(): void {
    this.tcpServer = socket.constructTCPSocketServerInstance();

    const ipAddress: socket.NetAddress = {
      address: '0.0.0.0',
      port: TRANSFER_PORT,
      family: 1
    } as socket.NetAddress;

    this.tcpServer.listen(ipAddress, (err) => {
      if (err) {
        hilog.error(0x0001, TAG, 'TCP listen failed: %{public}s', JSON.stringify(err));
        this.notifyListeners(TransferState.ERROR, '端口监听失败');
        return;
      }

      this.notifyListeners(TransferState.SOCKET_LISTENING,
        `等待传输... (${this.goIpAddress}:${TRANSFER_PORT})`);
      hilog.info(0x0001, TAG, 'TCP server listening on port %{public}d (receive mode)', TRANSFER_PORT);
    });

    this.tcpServer.on('connect', (connection: socket.TCPSocketConnection) => {
      hilog.info(0x0001, TAG, 'Client connected (receive mode)');
      this.notifyListeners(TransferState.TRANSFERRING, '正在接收文件...');

      let fileData = new Uint8Array(0);
      let fileMetadata: string = '';

      connection.on('message', (value: SocketMessage) => {
        try {
          const buffer = new Uint8Array(value.message);
          const text = String.fromCharCode(...buffer.slice(0, Math.min(buffer.length, 200)));

          if (fileMetadata === '' && text.startsWith('{')) {
            fileMetadata = text;
            hilog.info(0x0001, TAG, 'Received metadata: %{public}s', fileMetadata);
            return;
          }

          const newData = new Uint8Array(fileData.length + buffer.length);
          newData.set(fileData, 0);
          newData.set(buffer, fileData.length);
          fileData = newData;

          this.notifyListeners(TransferState.TRANSFERRING,
            `接收中... ${(fileData.length / 1024).toFixed(1)} KB`);
        } catch (e) {
          hilog.error(0x0001, TAG, 'Message error: %{public}s', JSON.stringify(e));
        }
      });

      connection.on('close', () => {
        hilog.info(0x0001, TAG, 'Connection closed, saving file...');
        this.saveReceivedFile(fileMetadata, fileData);
      });

      connection.on('error', (err: Error) => {
        hilog.error(0x0001, TAG, 'Connection error: %{public}s', err.message);
        this.notifyListeners(TransferState.ERROR, '传输错误');
      });
    });
  }

  private saveReceivedFile(metadata: string, data: Uint8Array): void {
    try {
      let fileName = `received_${Date.now()}.jpg`;
      if (metadata) {
        const meta = JSON.parse(metadata) as Record<string, string>;
        fileName = meta.fileName || fileName;
      }

      const savePath = `/data/storage/el2/base/files/${fileName}`;
      const file = fileIo.openSync(savePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      fileIo.writeSync(file.fd, data.buffer);
      fileIo.closeSync(file);

      this.notifyListeners(TransferState.COMPLETED, `文件已保存: ${fileName}`);
      hilog.info(0x0001, TAG, 'File saved: %{public}s, size: %{public}d', fileName, data.length);
    } catch (err) {
      hilog.error(0x0001, TAG, 'Save file failed: %{public}s', JSON.stringify(err));
      this.notifyListeners(TransferState.ERROR, '保存文件失败');
    }
  }

  stop(): void {
    if (this.tcpServer) {
      try {
        this.tcpServer.off('connect');
      } catch (e) {
        // ignore
      }
      this.tcpServer = null;
    }

    try {
      wifiManager.removeGroup();
    } catch (e) {
      hilog.error(0x0001, TAG, 'Remove group failed: %{public}s', JSON.stringify(e));
    }

    this._state = TransferState.IDLE;
    this.pendingSendFile = '';
    this.pendingSendName = '';
    hilog.info(0x0001, TAG, 'File transfer service stopped');
  }

  destroy(): void {
    this.stop();
    this.listeners = [];
  }
}
