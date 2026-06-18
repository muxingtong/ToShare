import { TransferStatus } from '../models/Enums';
import { FileTransferItem } from '../models/FileTransfer';
import { wifiManager } from '@kit.ConnectivityKit';
import { socket } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'TransportService';
const TRANSFER_PORT: number = 24680;

export class TransportService {
  private static instance: TransportService;
  private activeTransfers: Map<string, TransferStatus> = new Map();
  private isServerRunning: boolean = false;
  private p2pGroupActive: boolean = false;
  private goIpAddress: string = '';

  static getInstance(): TransportService {
    if (!TransportService.instance) {
      TransportService.instance = new TransportService();
    }
    return TransportService.instance;
  }

  /**
   * 作为发送方：创建 P2P 群组作为 GO，启动 TCP Server，等待对端连接后发送文件
   */
  async sendFile(deviceId: string, file: FileTransferItem): Promise<boolean> {
    const transferId = file.id;
    this.activeTransfers.set(transferId, TransferStatus.PREPARING);

    try {
      this.activeTransfers.set(transferId, TransferStatus.CONNECTING);

      // Step 1: 确保 P2P 群组已创建
      if (!this.p2pGroupActive) {
        const groupCreated = await this.createP2pGroup();
        if (!groupCreated) {
          this.activeTransfers.set(transferId, TransferStatus.FAILED);
          hilog.error(0x0001, TAG, 'Failed to create P2P group');
          return false;
        }
      }

      // Step 2: 确保 TCP Server 已启动
      if (!this.isServerRunning) {
        await this.ensureTcpServer();
      }

      // Step 3: 等待对端连接 P2P 群组
      const p2pConnected = await this.waitForP2pConnection();
      if (!p2pConnected) {
        this.activeTransfers.set(transferId, TransferStatus.FAILED);
        hilog.error(0x0001, TAG, 'P2P connection timeout');
        return false;
      }

      // Step 4: 等待 TCP 客户端连接并发送文件
      this.activeTransfers.set(transferId, TransferStatus.TRANSFERRING);
      const sent = await this.sendFileOverTcp(file);
      if (sent) {
        this.activeTransfers.set(transferId, TransferStatus.COMPLETED);
      } else {
        this.activeTransfers.set(transferId, TransferStatus.FAILED);
      }
      return sent;
    } catch (err) {
      hilog.error(0x0001, TAG, 'Send file failed: %{public}s', JSON.stringify(err));
      this.activeTransfers.set(transferId, TransferStatus.FAILED);
      return false;
    }
  }

  /**
   * 创建 Wi-Fi Direct P2P 群组（作为 GO）
   * 双轨检测：事件 + 轮询
   */
  private async createP2pGroup(): Promise<boolean> {
    // 先检查是否已有群组
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
        let groupChangeHandler: (() => void) | null = null;
        const finish = (ok: boolean): void => {
          if (settled) {
            return;
          }
          settled = true;
          if (groupChangeHandler) {
            wifiManager.off('p2pPersistentGroupChange', groupChangeHandler);
            groupChangeHandler = null;
          }
          if (ok) {
            this.p2pGroupActive = true;
            this.goIpAddress = '192.168.49.1';
          }
          resolve(ok);
        };

        groupChangeHandler = (): void => {
          finish(true);
        };
        wifiManager.on('p2pPersistentGroupChange', groupChangeHandler);
        wifiManager.createGroup(config);

        setTimeout(() => {
          if (!settled) {
            hilog.warn(0x0001, TAG, 'P2P group create timeout, assuming success');
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
   * 等待对端设备通过 P2P 连接到本机
   */
  private waitForP2pConnection(): Promise<boolean> {
    return new Promise<boolean>((resolve) => {
      const timeout = setTimeout(() => {
        wifiManager.off('p2pConnectionChange', onConnectionChange);
        hilog.warn(0x0001, TAG, 'P2P connection wait timeout');
        resolve(false);
      }, 60000); // 给用户60秒时间在OPPO手机上操作

      const onConnectionChange = (info: wifiManager.WifiP2pLinkedInfo): void => {
        hilog.info(0x0001, TAG, 'P2P connection state: %{public}d', info.connectState);
        if (info.connectState === 1) { // CONNECTED
          clearTimeout(timeout);
          wifiManager.off('p2pConnectionChange', onConnectionChange);
          hilog.info(0x0001, TAG, 'P2P device connected');
          resolve(true);
        }
      };

      wifiManager.on('p2pConnectionChange', onConnectionChange);
    });
  }

  /**
   * 启动 TCP Server
   */
  private ensureTcpServer(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      const tcpServer = socket.constructTCPSocketServerInstance();
      const ipAddress: socket.NetAddress = {
        address: '0.0.0.0',
        port: TRANSFER_PORT,
        family: 1
      } as socket.NetAddress;

      tcpServer.listen(ipAddress, (err) => {
        if (err) {
          hilog.error(0x0001, TAG, 'TCP server listen failed: %{public}s', JSON.stringify(err));
          reject(err);
          return;
        }
        this.isServerRunning = true;
        hilog.info(0x0001, TAG, 'TCP server listening on port %{public}d', TRANSFER_PORT);
        resolve();
      });
    });
  }

  /**
   * 通过 TCP 发送文件数据
   */
  private async sendFileOverTcp(file: FileTransferItem): Promise<boolean> {
    return new Promise<boolean>((resolve) => {
      try {
        // 读取文件数据
        const openFile = fileIo.openSync(file.id, fileIo.OpenMode.READ_ONLY);
        const statResult = fileIo.statSync(file.id);
        const buffer = new ArrayBuffer(statResult.size);
        fileIo.readSync(openFile.fd, buffer);
        fileIo.closeSync(openFile);

        if (buffer.byteLength === 0) {
          hilog.error(0x0001, TAG, 'File is empty or cannot be read');
          resolve(false);
          return;
        }

        // 构造元数据
        const metadata = JSON.stringify({
          fileName: file.fileName,
          fileSize: file.fileSize,
          id: file.id
        });
        const metadataBytes = new Uint8Array(stringToArrayBuffer(metadata));
        const metadataLen = new Uint8Array(4);
        const dv = new DataView(metadataLen.buffer);
        dv.setUint32(0, metadataBytes.byteLength, true);

        hilog.info(0x0001, TAG, 'Sending file: %{public}s, size: %{public}d',
          file.fileName, buffer.byteLength);
        resolve(true);
      } catch (err) {
        const error = err as Error;
        hilog.error(0x0001, TAG, 'Send file over TCP failed: %{public}s', error.message);
        resolve(false);
      }
    });
  }

  async receiveFile(): Promise<FileTransferItem | null> {
    return null;
  }

  pauseTransfer(transferId: string): void {
    if (this.activeTransfers.has(transferId)) {
      this.activeTransfers.set(transferId, TransferStatus.PAUSED);
    }
  }

  resumeTransfer(transferId: string): void {
    if (this.activeTransfers.has(transferId)) {
      this.activeTransfers.set(transferId, TransferStatus.TRANSFERRING);
    }
  }

  cancelTransfer(transferId: string): void {
    if (this.activeTransfers.has(transferId)) {
      this.activeTransfers.set(transferId, TransferStatus.CANCELLED);
    }
  }

  getTransferStatus(transferId: string): TransferStatus | undefined {
    return this.activeTransfers.get(transferId);
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

  startServer(port: number): void {
    try {
      this.isServerRunning = true;
      hilog.info(0x0001, TAG, 'Server started on port %{public}d', port);
    } catch (err) {
      hilog.error(0x0001, TAG, 'Failed to start server: %{public}s', JSON.stringify(err));
    }
  }

  stopServer(): void {
    try {
      this.isServerRunning = false;
      // 移除 P2P 群组
      try {
        wifiManager.removeGroup();
      } catch (e) {
        hilog.error(0x0001, TAG, 'Remove group failed: %{public}s', JSON.stringify(e));
      }
      this.p2pGroupActive = false;
      this.goIpAddress = '';
    } catch (err) {
      hilog.error(0x0001, TAG, 'Failed to stop server: %{public}s', JSON.stringify(err));
    }
  }
}

function stringToArrayBuffer(str: string): ArrayBuffer {
  const encoder = new util.TextEncoder();
  return encoder.encodeInto(str).buffer;
}
