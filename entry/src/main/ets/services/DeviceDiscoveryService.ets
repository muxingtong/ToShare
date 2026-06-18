import { Device } from '../models/Device';
import { DeviceType, DeviceStatus, TransportProtocol, DeviceDiscoveryStatus } from '../models/Enums';
import { ble, access } from '@kit.ConnectivityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { identifyShareDevice, ScanResultInput } from '../utils/ShareProtocol';

export type DeviceDiscoveryCallback = (devices: Device[]) => void;

export class DeviceDiscoveryService {
  private static instance: DeviceDiscoveryService;
  private discoveredDevices: Device[] = [];
  private _status: DeviceDiscoveryStatus = DeviceDiscoveryStatus.IDLE;
  private scanTimeout: number = -1;
  private listeners: DeviceDiscoveryCallback[] = [];
  private scanDuration: number = 12000; // 12秒扫描，确保能捕获到100ms间隔的广播

  static getInstance(): DeviceDiscoveryService {
    if (!DeviceDiscoveryService.instance) {
      DeviceDiscoveryService.instance = new DeviceDiscoveryService();
    }
    return DeviceDiscoveryService.instance;
  }

  get status(): DeviceDiscoveryStatus {
    return this._status;
  }

  getDevices(): Device[] {
    return this.discoveredDevices;
  }

  addListener(callback: DeviceDiscoveryCallback): void {
    if (!this.listeners.includes(callback)) {
      this.listeners.push(callback);
    }
  }

  removeListener(callback: DeviceDiscoveryCallback): void {
    const index = this.listeners.indexOf(callback);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  private notifyListeners(): void {
    for (const listener of this.listeners) {
      listener([...this.discoveredDevices]);
    }
  }

  async startDiscovery(): Promise<void> {
    // 确保蓝牙已开启
    const bluetoothOn = await this.ensureBluetoothOn();
    if (!bluetoothOn) {
      hilog.error(0x0001, 'ToShare', 'Cannot start discovery: Bluetooth is off');
      this._status = DeviceDiscoveryStatus.ERROR;
      return;
    }

    this._status = DeviceDiscoveryStatus.SCANNING;
    this.discoveredDevices = [];
    this.notifyListeners();
    this.startBLEScan();
    this.startScanTimer();
  }

  stopDiscovery(): void {
    this._status = DeviceDiscoveryStatus.IDLE;
    this.stopBLEScan();
    this.clearScanTimer();
    this.notifyListeners();
  }

  private startScanTimer(): void {
    this.scanTimeout = setTimeout(() => {
      hilog.info(0x0001, 'ToShare', 'Scan timeout reached, stopping discovery');
      this.stopDiscovery();
    }, this.scanDuration);
  }

  private clearScanTimer(): void {
    if (this.scanTimeout >= 0) {
      clearTimeout(this.scanTimeout);
      this.scanTimeout = -1;
    }
  }

  startBroadcast(): void {
    this._status = DeviceDiscoveryStatus.BROADCASTING;
  }

  stopBroadcast(): void {
    if (this._status === DeviceDiscoveryStatus.BROADCASTING) {
      this._status = DeviceDiscoveryStatus.IDLE;
    }
  }

  private startBLEScan(): void {
    try {
      ble.on('BLEDeviceFind', this.onBLEDeviceFind);

      // 使用主动扫描模式以获取更多广播数据（尤其是Scan Response中的设备名）
      const scanOptions: ble.ScanOptions = {
        interval: 0,  // 0 = 持续扫描直到手动停止
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE
      };

      // 不设置过滤器(null)，发现所有BLE设备，由应用层ShareProtocol过滤互传设备
      ble.startBLEScan(null, scanOptions);
      hilog.info(0x0001, 'ToShare', 'BLE scan started (active mode, no filter)');
    } catch (err) {
      hilog.error(0x0001, 'ToShare', 'BLE scan failed: %{public}s', JSON.stringify(err));
      this._status = DeviceDiscoveryStatus.ERROR;
    }
  }

  private stopBLEScan(): void {
    try {
      ble.off('BLEDeviceFind', this.onBLEDeviceFind);
      ble.stopBLEScan();
      hilog.info(0x0001, 'ToShare', 'BLE scan stopped');
    } catch (err) {
      hilog.error(0x0001, 'ToShare', 'BLE stop scan failed: %{public}s', JSON.stringify(err));
    }
  }

  private onBLEDeviceFind = (data: Array<ble.ScanResult>): void => {
    for (const result of data) {
      // 输出原始广播数据（16进制），便于调试协议兼容性
      const rawBytes = new Uint8Array(result.data);
      let hexStr = '';
      for (let i = 0; i < rawBytes.byteLength && i < 64; i++) {
        hexStr += rawBytes[i].toString(16).padStart(2, '0').toUpperCase();
      }
      hilog.info(0x0001, 'ToShare', 'BLE device: name=%{public}s, rssi=%{public}d, dataLen=%{public}d, hex=%{public}s',
        result.deviceName || '(empty)', result.rssi, rawBytes.byteLength, hexStr);

      const scanInput: ScanResultInput = {
        deviceId: result.deviceId,
        deviceName: result.deviceName,
        rssi: result.rssi,
        data: result.data
      };
      const shareInfo = identifyShareDevice(scanInput);

      // 输出详细的识别结果
      if (shareInfo.isShareDevice || shareInfo.vendor !== '未知' ||
          (shareInfo.serviceUuids.length > 0)) {
        hilog.info(0x0001, 'ToShare',
          '  --> SHARE_DEVICE: vendor=%{public}s, isShare=%{public}b, name=%{public}s, rssi=%{public}d, uuids=%{public}s',
          shareInfo.vendor, shareInfo.isShareDevice,
          shareInfo.deviceName, shareInfo.rssi,
          shareInfo.serviceUuids.join(','));
      }

      let deviceName: string;
      let deviceType: DeviceType;
      let protocols: TransportProtocol[];

      if (shareInfo.isShareDevice) {
        // 互传联盟设备：标签显示厂商名 + 原始名称
        deviceName = shareInfo.deviceName;
        if (shareInfo.vendor !== '未知' && !shareInfo.deviceName.includes(shareInfo.vendor)) {
          deviceName = `[${shareInfo.vendor}] ${shareInfo.deviceName}`;
        }
        deviceType = DeviceType.MOBILE;
        protocols = [TransportProtocol.BLUETOOTH, TransportProtocol.WIFI_DIRECT];
      } else {
        // 非互传设备，仅显示名称
        deviceName = result.deviceName || this.formatDeviceId(result.deviceId);
        deviceType = DeviceType.MOBILE;
        protocols = [TransportProtocol.BLUETOOTH];
      }

      const existingIndex = this.discoveredDevices.findIndex(d => d.id === result.deviceId);
      if (existingIndex >= 0) {
        // 更新已有设备信息（保留更准确的名称）
        const existing = this.discoveredDevices[existingIndex];
        existing.signalStrength = result.rssi;
        existing.lastSeen = Date.now();
        existing.status = DeviceStatus.ONLINE;
        // 如果新发现的设备名更有意义，则更新
        if (shareInfo.isShareDevice && deviceName.length > existing.name.length) {
          existing.name = deviceName;
          existing.supportedProtocols = protocols;
        }
      } else {
        const device = new Device(
          result.deviceId,
          deviceName,
          '',
          deviceType,
          protocols,
          Date.now(),
          DeviceStatus.ONLINE,
          result.rssi
        );
        this.discoveredDevices.push(device);
      }
    }
    this.notifyListeners();
  };

  private formatDeviceId(deviceId: string): string {
    if (deviceId.length >= 5) {
      return `设备 ${deviceId.substring(deviceId.length - 5)}`;
    }
    return `设备 ${deviceId}`;
  }

  addDiscoveredDevice(device: Device): void {
    const index = this.discoveredDevices.findIndex(d => d.id === device.id);
    if (index >= 0) {
      this.discoveredDevices[index] = device;
    } else {
      this.discoveredDevices.push(device);
    }
  }

  clearDevices(): void {
    this.discoveredDevices = [];
  }

  /**
   * 确保蓝牙已开启
   */
  private async ensureBluetoothOn(): Promise<boolean> {
    try {
      const state = access.getState();
      if (state === access.BluetoothState.STATE_ON ||
          state === access.BluetoothState.STATE_BLE_ON) {
        return true;
      }
      // 蓝牙未开启，仅返回false（由UI层提示用户开启）
      hilog.warn(0x0001, 'ToShare', 'Bluetooth is not on, state=%{public}d', state);
      return false;
    } catch (err) {
      hilog.error(0x0001, 'ToShare', 'Failed to check Bluetooth state: %{public}s', JSON.stringify(err));
      return false;
    }
  }
}
