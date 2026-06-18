import { Device } from '../models/Device';
import { DeviceType, DeviceStatus, TransportProtocol, DeviceDiscoveryStatus } from '../models/Enums';
import { ble, access } from '@kit.ConnectivityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { identifyShareDevice, ScanResultInput, SHARE_SERVICE_UUIDS, ShareVendor } from '../utils/ShareProtocol';

export type DeviceDiscoveryCallback = (devices: Device[]) => void;

export class DeviceDiscoveryService {
  private static instance: DeviceDiscoveryService;
  private discoveredDevices: Device[] = [];
  private _status: DeviceDiscoveryStatus = DeviceDiscoveryStatus.IDLE;
  private scanTimeout: number = -1;
  private listeners: DeviceDiscoveryCallback[] = [];
  // 设备超过 15 秒未广播即视为离线，从列表中移除
  private static readonly DEVICE_EXPIRY_MS: number = 15000;
  // 过期设备清理间隔 (每 5 秒检查一次)
  private static readonly EXPIRY_CHECK_INTERVAL_MS: number = 5000;
  private scanDuration: number = 12000; // 12秒扫描，确保能捕获到100ms间隔的广播
  private expiryTimer: number = -1;

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
    this.startExpiryCheck();
  }

  stopDiscovery(): void {
    this._status = DeviceDiscoveryStatus.IDLE;
    this.stopBLEScan();
    this.clearScanTimer();
    this.stopExpiryCheck();
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

      const scanOptions: ble.ScanOptions = {
        interval: 0,
        dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
        matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE
      };

      // ⭐ 系统级 BLE 过滤：只扫描已知互传联盟设备的 Service UUID
      // 减少系统负载和功耗，同时降低应用层收到无关设备的数量
      const filters: ble.ScanFilter[] = [];
      for (let i = 0; i < SHARE_SERVICE_UUIDS.length; i++) {
        filters.push({ serviceUuid: SHARE_SERVICE_UUIDS[i] });
      }

      ble.startBLEScan(filters, scanOptions);
      hilog.info(0x0001, 'ToShare', 'BLE scan started with %{public}d share UUID filters', filters.length);
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
          shareInfo.serviceUuids.length > 0) {
        hilog.info(0x0001, 'ToShare',
          '  --> SHARE_DEVICE: vendor=%{public}s, isShare=%{public}b, name=%{public}s, rssi=%{public}d, uuids=%{public}s',
          shareInfo.vendor, shareInfo.isShareDevice,
          shareInfo.deviceName, shareInfo.rssi,
          shareInfo.serviceUuids.join(','));
      }

      // ⭐ 只显示互传联盟设备，过滤掉普通 BLE 设备（蓝牙耳机、手环等）
      if (!shareInfo.isShareDevice) {
        continue;
      }

      // 互传联盟设备：生成设备名（原始名称，Display view 自动清理）
      const deviceName = cleanDeviceNameForStorage(shareInfo.vendor, shareInfo.deviceName);
      const deviceType = DeviceType.MOBILE;
      const protocols = [TransportProtocol.BLUETOOTH, TransportProtocol.WIFI_DIRECT];

      const existingIndex = this.discoveredDevices.findIndex(d => d.id === result.deviceId);
      if (existingIndex >= 0) {
        // 更新已有设备信息
        const existing = this.discoveredDevices[existingIndex];
        existing.signalStrength = result.rssi;
        existing.lastSeen = Date.now();
        existing.status = DeviceStatus.ONLINE;
        if (deviceName.length > existing.name.length) {
          existing.name = deviceName;
          existing.vendor = shareInfo.vendor;
          existing.supportedProtocols = protocols;
        }
      } else {
        this.discoveredDevices.push(new Device(
          result.deviceId,
          deviceName,
          shareInfo.vendor,
          '',
          deviceType,
          protocols,
          Date.now(),
          DeviceStatus.ONLINE,
          result.rssi
        ));
      }
    }
    this.notifyListeners();
  };

  clearDevices(): void {
    this.discoveredDevices = [];
  }

  /**
   * 启动过期设备清理定时器
   */
  private startExpiryCheck(): void {
    this.expiryTimer = setInterval(() => {
      const now = Date.now();
      const before = this.discoveredDevices.length;
      this.discoveredDevices = this.discoveredDevices.filter(d => (now - d.lastSeen) < DeviceDiscoveryService.DEVICE_EXPIRY_MS);
      if (this.discoveredDevices.length !== before) {
        hilog.info(0x0001, 'ToShare',
          'Expired devices removed: %{public}d -> %{public}d', before, this.discoveredDevices.length);
        this.notifyListeners();
      }
    }, DeviceDiscoveryService.EXPIRY_CHECK_INTERVAL_MS);
  }

  private stopExpiryCheck(): void {
    if (this.expiryTimer >= 0) {
      clearInterval(this.expiryTimer);
      this.expiryTimer = -1;
    }
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

/**
 * 生成存储用的原始设备名
 * - 对于已知厂商设备，若原始名已经包含厂商名，直接使用
 * - 否则按"[厂商] 设备名"格式存储（display 层进行清理）
 */
function cleanDeviceNameForStorage(vendor: ShareVendor, deviceName: string): string {
  const raw = deviceName.trim();
  const vendorStr = String(vendor);
  if (raw.includes(vendorStr) || vendorStr === '未知') {
    return raw || '附近设备';
  }
  return `[${vendorStr}] ${raw}`;
}
