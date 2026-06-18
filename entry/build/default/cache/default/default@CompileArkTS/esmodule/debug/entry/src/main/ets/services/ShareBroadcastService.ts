import ble from "@ohos:bluetooth.ble";
import access from "@ohos:bluetooth.access";
import hilog from "@ohos:hilog";
import util from "@ohos:util";
import { TransportService } from "@normalized:N&&&entry/src/main/ets/services/TransportService&";
const TAG = 'ShareBroadcast';
export enum BroadcastStatus {
    IDLE = "idle",
    STARTING = "starting",
    BROADCASTING = "broadcasting",
    STOPPING = "stopping",
    ERROR = "error"
}
export class BroadcastStatusCallback {
    onStatusChange: (status: BroadcastStatus, message?: string) => void;
    constructor(onStatusChange: (status: BroadcastStatus, message?: string) => void) {
        this.onStatusChange = onStatusChange;
    }
}
export class ShareBroadcastService {
    private static instance: ShareBroadcastService;
    private _status: BroadcastStatus = BroadcastStatus.IDLE;
    private listeners: BroadcastStatusCallback[] = [];
    private advHandle: number = -1;
    private gattServer: ble.GattServer | null = null;
    private deviceName: string = 'ToShare';
    private connectedDevices: Set<string> = new Set();
    // OPPO 互传 BLE 参数
    private readonly SHARE_SERVICE_UUID: string = '0000FDDF-0000-1000-8000-00805F9B34FB';
    private readonly OPPO_MANUFACTURER_ID: number = 0x0583;
    // GATT 特征值 UUID
    private readonly CHAR_DEVICE_INFO: string = '0000FDDF-0001-1000-8000-00805F9B34FB';
    private readonly CHAR_WIFI_INFO: string = '0000FDDF-0002-1000-8000-00805F9B34FB';
    private readonly CHAR_TRANSFER_CTRL: string = '0000FDDF-0003-1000-8000-00805F9B34FB';
    static getInstance(): ShareBroadcastService {
        if (!ShareBroadcastService.instance) {
            ShareBroadcastService.instance = new ShareBroadcastService();
        }
        return ShareBroadcastService.instance;
    }
    get status(): BroadcastStatus {
        return this._status;
    }
    setDeviceName(name: string): void {
        this.deviceName = name;
    }
    addListener(callback: BroadcastStatusCallback): void {
        if (!this.listeners.includes(callback)) {
            this.listeners.push(callback);
        }
    }
    removeListener(callback: BroadcastStatusCallback): void {
        const index = this.listeners.indexOf(callback);
        if (index >= 0) {
            this.listeners.splice(index, 1);
        }
    }
    private notifyListeners(status: BroadcastStatus, message?: string): void {
        for (const listener of this.listeners) {
            listener.onStatusChange(status, message);
        }
    }
    async startBroadcast(): Promise<void> {
        if (this._status === BroadcastStatus.BROADCASTING) {
            hilog.info(0x0001, TAG, 'Already broadcasting');
            return;
        }
        // 清理旧资源
        if (this.advHandle >= 0) {
            try {
                await ble.stopAdvertising(this.advHandle);
            }
            catch (e) {
                // ignore
            }
            this.advHandle = -1;
        }
        if (this.gattServer) {
            try {
                this.gattServer.off('connectionStateChange');
                this.gattServer.off('characteristicRead');
                this.gattServer.off('characteristicWrite');
            }
            catch (e) {
                // ignore
            }
            this.gattServer = null;
        }
        this._status = BroadcastStatus.STARTING;
        this.notifyListeners(BroadcastStatus.STARTING, '正在检查蓝牙状态...');
        const bluetoothReady = await this.ensureBluetoothEnabled();
        if (!bluetoothReady) {
            this._status = BroadcastStatus.ERROR;
            const msg = '蓝牙未开启，请在系统设置中开启蓝牙后重试';
            hilog.error(0x0001, TAG, msg);
            this.notifyListeners(BroadcastStatus.ERROR, msg);
            return;
        }
        try {
            // Step 1: 创建 GATT Server 并添加互传服务（含特征值属性和权限）
            this.setupGattServer();
            // Step 2: 订阅广播状态变化事件（用于调试）
            this.subscribeAdvertiseState();
            // Step 3: 启动 BLE 广播
            await this.startAdvertising();
        }
        catch (err) {
            this._status = BroadcastStatus.ERROR;
            const error = err as Error;
            const msg = `广播启动失败: ${error.message || JSON.stringify(err)}`;
            hilog.error(0x0001, TAG, msg);
            this.notifyListeners(BroadcastStatus.ERROR, msg);
        }
    }
    /**
     * 创建 GATT Server 并注册互传服务
     * 包含设备信息(只读)、WiFi信息(只读)和传输控制(可写)三个特征值
     */
    private setupGattServer(): void {
        try {
            this.gattServer = ble.createGattServer();
            // 监听 GATT 连接状态
            this.gattServer.on('connectionStateChange', (data: ble.BLEConnectionChangeState) => {
                hilog.info(0x0001, TAG, 'GATT connection state change: device=%{public}s, state=%{public}d', data.deviceId, data.state);
                // state: 0=DISCONNECTED, 1=CONNECTING, 2=CONNECTED, 3=DISCONNECTING
                if (data.state === 2) {
                    this.connectedDevices.add(data.deviceId);
                    hilog.info(0x0001, TAG, 'Device connected via GATT: %{public}s', data.deviceId);
                }
                else if (data.state === 0) {
                    this.connectedDevices.delete(data.deviceId);
                }
            });
            // 监听特征值读请求——当对端读取设备信息时返回设备名
            this.gattServer.on('characteristicRead', (data: ble.CharacteristicReadRequest) => {
                hilog.info(0x0001, TAG, 'Characteristic read: device=%{public}s, char=%{public}s', data.deviceId, data.characteristicUuid);
                if (data.characteristicUuid === this.CHAR_DEVICE_INFO) {
                    // 返回设备信息（互传协议格式）
                    const deviceInfo = JSON.stringify({
                        name: this.deviceName,
                        model: 'HarmonyOS',
                        brand: 'Huawei',
                        shareVersion: '1.0',
                        deviceType: 'mobile'
                    });
                    const response: ble.ServerResponse = {
                        deviceId: data.deviceId,
                        transId: data.transId,
                        status: 0,
                        offset: data.offset,
                        value: stringToArrayBuffer(deviceInfo)
                    };
                    this.gattServer?.sendResponse(response);
                }
                else if (data.characteristicUuid === this.CHAR_WIFI_INFO) {
                    // 返回 WiFi P2P 连接信息
                    const transport = TransportService.getInstance();
                    const wifiInfo = JSON.stringify({
                        ssid: 'ToShare',
                        passphrase: 'ToShare123',
                        ipAddress: transport.goIp || 'waiting',
                        port: transport.port
                    });
                    const response: ble.ServerResponse = {
                        deviceId: data.deviceId,
                        transId: data.transId,
                        status: 0,
                        offset: data.offset,
                        value: stringToArrayBuffer(wifiInfo)
                    };
                    this.gattServer?.sendResponse(response);
                }
                else {
                    const response: ble.ServerResponse = {
                        deviceId: data.deviceId,
                        transId: data.transId,
                        status: 0,
                        offset: data.offset,
                        value: new ArrayBuffer(0)
                    };
                    this.gattServer?.sendResponse(response);
                }
            });
            // 监听特征值写请求——用于接收传输控制命令
            this.gattServer.on('characteristicWrite', (data: ble.CharacteristicWriteRequest) => {
                hilog.info(0x0001, TAG, 'Characteristic write: device=%{public}s, char=%{public}s', data.deviceId, data.characteristicUuid);
                const response: ble.ServerResponse = {
                    deviceId: data.deviceId,
                    transId: data.transId,
                    status: 0,
                    offset: data.offset,
                    value: new ArrayBuffer(0)
                };
                this.gattServer?.sendResponse(response);
            });
            // 构造特征值——设备信息（只读）
            const charDeviceInfo: ble.BLECharacteristic = {
                serviceUuid: this.SHARE_SERVICE_UUID,
                characteristicUuid: this.CHAR_DEVICE_INFO,
                characteristicValue: new ArrayBuffer(0),
                descriptors: []
            };
            // 构造特征值——WiFi信息（只读）
            const charWifiInfo: ble.BLECharacteristic = {
                serviceUuid: this.SHARE_SERVICE_UUID,
                characteristicUuid: this.CHAR_WIFI_INFO,
                characteristicValue: new ArrayBuffer(0),
                descriptors: []
            };
            // 构造特征值——传输控制（可写）
            const charTransferCtrl: ble.BLECharacteristic = {
                serviceUuid: this.SHARE_SERVICE_UUID,
                characteristicUuid: this.CHAR_TRANSFER_CTRL,
                characteristicValue: new ArrayBuffer(0),
                descriptors: []
            };
            // 构造 GATT 服务
            const gattService: ble.GattService = {
                serviceUuid: this.SHARE_SERVICE_UUID,
                isPrimary: true,
                characteristics: [charDeviceInfo, charWifiInfo, charTransferCtrl],
                includeServices: []
            };
            this.gattServer.addService(gattService);
            hilog.info(0x0001, TAG, 'GATT server setup complete with 3 characteristics (with properties/permissions)');
        }
        catch (err) {
            const error = err as Error;
            hilog.error(0x0001, TAG, 'GATT server setup failed: %{public}s', error.message);
            throw new Error('GATT server setup failed: ' + error.message);
        }
    }
    /**
     * 订阅广播状态变化事件（调试用）
     */
    private subscribeAdvertiseState(): void {
        try {
            ble.on('advertisingStateChange', (data: ble.AdvertisingStateChangeInfo) => {
                hilog.info(0x0001, TAG, 'Advertise state changed: id=%{public}d, state=%{public}d', data.advertisingId, data.state);
            });
        }
        catch (err) {
            hilog.warn(0x0001, TAG, 'Failed to subscribe advertise state: %{public}s', JSON.stringify(err));
        }
    }
    /**
     * 启动 BLE 广播
     * 广播报文结构:
     *   AdvData:  Flags(3B) + 16-bit UUID List(4B: len+type+0xFDDF) + Manufacturer Data(8B: len+type+id+4B data) = ~15B
     *   ScanRsp:  Device Name (由 includeDeviceName 控制，确保不超过31字节)
     */
    private async startAdvertising(): Promise<void> {
        const setting: ble.AdvertiseSetting = {
            interval: 160,
            txPower: 0,
            connectable: true // 可连接广播（GATT Server模式必需）
        };
        // OPPO 互传协议厂商数据格式:
        // Byte 0: 协议版本主号 (0x01)
        // Byte 1: 协议版本副号 (0x00)  → 版本 1.0
        // Byte 2: 设备角色 (0x03 = 双端，可收可发)
        // Byte 3: 保留 (0x00)
        const manufactureValueBuffer = new Uint8Array(4);
        manufactureValueBuffer[0] = 0x01; // 协议版本主号
        manufactureValueBuffer[1] = 0x00; // 协议版本副号
        manufactureValueBuffer[2] = 0x03; // 设备角色：双端(可收可发)
        manufactureValueBuffer[3] = 0x00; // 保留
        const manufactureDataUnit: ble.ManufactureData = {
            manufactureId: this.OPPO_MANUFACTURER_ID,
            manufactureValue: manufactureValueBuffer.buffer
        };
        // OPPO 互传也通过 Service Data (AD Type 0x16) 携带协议标识
        // 格式: 2字节UUID(0xFDDF) + 协议数据
        // 这帮助OPPO设备更准确地识别互传服务
        const serviceDataValue = new Uint8Array(2);
        serviceDataValue[0] = 0x01; // 互传协议版本
        serviceDataValue[1] = 0x03; // 设备角色
        const serviceDataUnit: ble.ServiceData = {
            serviceUuid: this.SHARE_SERVICE_UUID,
            serviceValue: serviceDataValue.buffer
        };
        // advData: 广播报文（31字节限制内，不含设备名以避免超限）
        //   Flags(3) + 16-bit UUID(4) + Manufacturer Data(8) + Service Data(7) = 22B ✅
        const advData: ble.AdvertiseData = {
            serviceUuids: [this.SHARE_SERVICE_UUID],
            manufactureData: [manufactureDataUnit],
            serviceData: [serviceDataUnit],
            includeDeviceName: false // 不在主广播包中携带设备名，节省空间
        };
        // advResponse: 扫描响应报文（不含 serviceUuids/manufactureData 避免重复）
        //   仅携带设备名，通过主动扫描获取
        const advResponse: ble.AdvertiseData = {
            serviceUuids: [],
            manufactureData: [],
            serviceData: [],
            includeDeviceName: true // 设备名放在扫描响应包中
        };
        const advertisingParams: ble.AdvertisingParams = {
            advertisingSettings: setting,
            advertisingData: advData,
            advertisingResponse: advResponse,
            duration: 0 // 0 = 持续广播，直到手动停止
        };
        hilog.info(0x0001, TAG, 'Starting BLE advertising with service=%{public}s, manufacturer=0x%{public}x', this.SHARE_SERVICE_UUID, this.OPPO_MANUFACTURER_ID);
        this.advHandle = await ble.startAdvertising(advertisingParams);
        this._status = BroadcastStatus.BROADCASTING;
        this.notifyListeners(BroadcastStatus.BROADCASTING, `广播已启动 (${this.deviceName}) | GATT 服务已就绪 | advHandle=${this.advHandle}`);
        hilog.info(0x0001, TAG, 'Broadcast started, advHandle: %{public}d, GATT server ready', this.advHandle);
    }
    async stopBroadcast(): Promise<void> {
        if (this._status !== BroadcastStatus.BROADCASTING &&
            this._status !== BroadcastStatus.STARTING) {
            hilog.info(0x0001, TAG, 'Not broadcasting, skip stop');
            return;
        }
        this._status = BroadcastStatus.STOPPING;
        this.notifyListeners(BroadcastStatus.STOPPING);
        try {
            if (this.advHandle >= 0) {
                await ble.stopAdvertising(this.advHandle);
            }
            this.advHandle = -1;
            // 清理广告状态监听
            try {
                ble.off('advertisingStateChange');
            }
            catch (e) {
                // ignore
            }
            // 关闭 GATT Server
            if (this.gattServer) {
                try {
                    this.gattServer.off('connectionStateChange');
                    this.gattServer.off('characteristicRead');
                    this.gattServer.off('characteristicWrite');
                    this.connectedDevices.clear();
                }
                catch (e) {
                    hilog.warn(0x0001, TAG, 'GATT server cleanup warning');
                }
                this.gattServer = null;
            }
            this._status = BroadcastStatus.IDLE;
            this.notifyListeners(BroadcastStatus.IDLE);
            hilog.info(0x0001, TAG, 'Broadcast stopped');
        }
        catch (err) {
            hilog.error(0x0001, TAG, 'Stop broadcast failed: %{public}s', JSON.stringify(err));
            this._status = BroadcastStatus.IDLE;
            this.notifyListeners(BroadcastStatus.IDLE);
        }
    }
    private async ensureBluetoothEnabled(): Promise<boolean> {
        try {
            const state = access.getState();
            if (state === access.BluetoothState.STATE_ON ||
                state === access.BluetoothState.STATE_BLE_ON) {
                return true;
            }
            if (state === access.BluetoothState.STATE_OFF) {
                hilog.info(0x0001, TAG, 'Bluetooth is off, enabling...');
                access.enableBluetooth();
                return await this.waitForBluetoothOn(8000);
            }
            hilog.warn(0x0001, TAG, 'Bluetooth is in state: %{public}d, waiting...', state);
            return await this.waitForBluetoothOn(5000);
        }
        catch (err) {
            hilog.error(0x0001, TAG, 'Failed to check Bluetooth state: %{public}s', JSON.stringify(err));
            return false;
        }
    }
    private waitForBluetoothOn(timeoutMs: number): Promise<boolean> {
        return new Promise<boolean>((resolve) => {
            const quickCheck = access.getState();
            if (quickCheck === access.BluetoothState.STATE_ON ||
                quickCheck === access.BluetoothState.STATE_BLE_ON) {
                resolve(true);
                return;
            }
            const timer = setTimeout(() => {
                access.off('stateChange', onStateChange);
                hilog.warn(0x0001, TAG, 'Bluetooth enable timeout');
                resolve(false);
            }, timeoutMs);
            const onStateChange = (data: access.BluetoothState): void => {
                hilog.info(0x0001, TAG, 'Bluetooth state changed to: %{public}d', data);
                if (data === access.BluetoothState.STATE_ON || data === access.BluetoothState.STATE_BLE_ON) {
                    clearTimeout(timer);
                    access.off('stateChange', onStateChange);
                    resolve(true);
                }
            };
            access.on('stateChange', onStateChange);
        });
    }
    getConnectedDeviceCount(): number {
        return this.connectedDevices.size;
    }
    destroy(): void {
        if (this._status === BroadcastStatus.BROADCASTING) {
            this.stopBroadcast();
        }
        this.listeners = [];
    }
}
function stringToArrayBuffer(str: string): ArrayBuffer {
    const encoder = new util.TextEncoder();
    return encoder.encodeInto(str).buffer;
}
