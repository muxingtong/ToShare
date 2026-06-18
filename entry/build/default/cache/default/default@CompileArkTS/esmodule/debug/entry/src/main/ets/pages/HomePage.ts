if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface HomePage_Params {
    devices?: Device[];
    isScanning?: boolean;
    isBroadcasting?: boolean;
    broadcastError?: string;
    myDeviceName?: string;
    isDark?: boolean;
    transferStatus?: TransferState;
    transferMessage?: string;
    showTransferPanel?: boolean;
    animScanPulse?: number;
    tabsController?: HdsTabsController;
    discoveryService?: DeviceDiscoveryService;
    broadcastService?: ShareBroadcastService;
    transferService?: FileTransferService;
    materialLevel?: hdsMaterial.MaterialLevel;
    onDevicesDiscovered?: DeviceDiscoveryCallback;
    onBroadcastStatusChange?: BroadcastStatusCallback;
    onTransferStatusChange?: TransferStatusCallback;
}
import { DeviceDiscoveryService } from "@normalized:N&&&entry/src/main/ets/services/DeviceDiscoveryService&";
import type { DeviceDiscoveryCallback } from "@normalized:N&&&entry/src/main/ets/services/DeviceDiscoveryService&";
import { ShareBroadcastService, BroadcastStatus, BroadcastStatusCallback } from "@normalized:N&&&entry/src/main/ets/services/ShareBroadcastService&";
import { FileTransferService, TransferState, TransferStatusCallback } from "@normalized:N&&&entry/src/main/ets/services/FileTransferService&";
import type { Device } from '../models/Device';
import { DeviceDiscoveryStatus } from "@normalized:N&&&entry/src/main/ets/models/Enums&";
import { DeviceCard } from "@normalized:N&&&entry/src/main/ets/components/DeviceCard&";
import { MyDeviceCard } from "@normalized:N&&&entry/src/main/ets/components/MyDeviceCard&";
import { SendPage } from "@normalized:N&&&entry/src/main/ets/pages/SendPage&";
import { ReceivePage } from "@normalized:N&&&entry/src/main/ets/pages/ReceivePage&";
import { HistoryPage } from "@normalized:N&&&entry/src/main/ets/pages/HistoryPage&";
import { SettingsPage } from "@normalized:N&&&entry/src/main/ets/pages/SettingsPage&";
import { AppTheme } from "@normalized:N&&&entry/src/main/ets/theme/AppTheme&";
import { AppColors } from "@normalized:N&&&entry/src/main/ets/theme/AppColors&";
import hilog from "@ohos:hilog";
import picker from "@ohos:file.picker";
import abilityAccessCtrl from "@ohos:abilityAccessCtrl";
import type common from "@ohos:app.ability.common";
import type { Permissions } from "@ohos:abilityAccessCtrl";
import { HdsTabs } from "@hms:hds.hdsBaseComponent";
import { HdsTabsController } from "@hms:hds.hdsBaseComponent";
import { hdsMaterial } from "@hms:hds.hdsMaterial";
import type { HdsTabsAttribute } from "@hms:hds.hdsBaseComponent";
import { SymbolGlyphModifier } from "@ohos:arkui.modifier";
class HomePage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__devices = new ObservedPropertyObjectPU([], this, "devices");
        this.__isScanning = new ObservedPropertySimplePU(false, this, "isScanning");
        this.__isBroadcasting = new ObservedPropertySimplePU(false, this, "isBroadcasting");
        this.__broadcastError = new ObservedPropertySimplePU('', this, "broadcastError");
        this.__myDeviceName = new ObservedPropertySimplePU('我的设备', this, "myDeviceName");
        this.__isDark = new ObservedPropertySimplePU(false, this, "isDark");
        this.__transferStatus = new ObservedPropertySimplePU(TransferState.IDLE, this, "transferStatus");
        this.__transferMessage = new ObservedPropertySimplePU('', this, "transferMessage");
        this.__showTransferPanel = new ObservedPropertySimplePU(false, this, "showTransferPanel");
        this.__animScanPulse = new ObservedPropertySimplePU(1, this, "animScanPulse");
        this.tabsController = new HdsTabsController();
        this.discoveryService = DeviceDiscoveryService.getInstance();
        this.broadcastService = ShareBroadcastService.getInstance();
        this.transferService = FileTransferService.getInstance();
        this.__materialLevel = new ObservedPropertySimplePU(hdsMaterial.MaterialLevel.ADAPTIVE, this, "materialLevel");
        this.onDevicesDiscovered = (devices: Device[]) => {
            this.devices = devices;
            if (this.discoveryService.status !== DeviceDiscoveryStatus.SCANNING) {
                this.isScanning = false;
            }
        };
        this.onBroadcastStatusChange = new BroadcastStatusCallback((status: BroadcastStatus, message?: string) => {
            this.isBroadcasting = status === BroadcastStatus.BROADCASTING || status === BroadcastStatus.STARTING;
            if (status === BroadcastStatus.ERROR) {
                this.broadcastError = message || '广播启动失败';
                setTimeout(() => { this.broadcastError = ''; }, 4000);
            }
            else {
                this.broadcastError = '';
            }
        });
        this.onTransferStatusChange = new TransferStatusCallback((state: TransferState, message?: string) => {
            this.transferStatus = state;
            this.transferMessage = message || '';
            if (state === TransferState.IDLE || state === TransferState.COMPLETED || state === TransferState.ERROR) {
                setTimeout(() => { this.showTransferPanel = false; }, 3000);
            }
        });
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: HomePage_Params) {
        if (params.devices !== undefined) {
            this.devices = params.devices;
        }
        if (params.isScanning !== undefined) {
            this.isScanning = params.isScanning;
        }
        if (params.isBroadcasting !== undefined) {
            this.isBroadcasting = params.isBroadcasting;
        }
        if (params.broadcastError !== undefined) {
            this.broadcastError = params.broadcastError;
        }
        if (params.myDeviceName !== undefined) {
            this.myDeviceName = params.myDeviceName;
        }
        if (params.isDark !== undefined) {
            this.isDark = params.isDark;
        }
        if (params.transferStatus !== undefined) {
            this.transferStatus = params.transferStatus;
        }
        if (params.transferMessage !== undefined) {
            this.transferMessage = params.transferMessage;
        }
        if (params.showTransferPanel !== undefined) {
            this.showTransferPanel = params.showTransferPanel;
        }
        if (params.animScanPulse !== undefined) {
            this.animScanPulse = params.animScanPulse;
        }
        if (params.tabsController !== undefined) {
            this.tabsController = params.tabsController;
        }
        if (params.discoveryService !== undefined) {
            this.discoveryService = params.discoveryService;
        }
        if (params.broadcastService !== undefined) {
            this.broadcastService = params.broadcastService;
        }
        if (params.transferService !== undefined) {
            this.transferService = params.transferService;
        }
        if (params.materialLevel !== undefined) {
            this.materialLevel = params.materialLevel;
        }
        if (params.onDevicesDiscovered !== undefined) {
            this.onDevicesDiscovered = params.onDevicesDiscovered;
        }
        if (params.onBroadcastStatusChange !== undefined) {
            this.onBroadcastStatusChange = params.onBroadcastStatusChange;
        }
        if (params.onTransferStatusChange !== undefined) {
            this.onTransferStatusChange = params.onTransferStatusChange;
        }
    }
    updateStateVars(params: HomePage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__devices.purgeDependencyOnElmtId(rmElmtId);
        this.__isScanning.purgeDependencyOnElmtId(rmElmtId);
        this.__isBroadcasting.purgeDependencyOnElmtId(rmElmtId);
        this.__broadcastError.purgeDependencyOnElmtId(rmElmtId);
        this.__myDeviceName.purgeDependencyOnElmtId(rmElmtId);
        this.__isDark.purgeDependencyOnElmtId(rmElmtId);
        this.__transferStatus.purgeDependencyOnElmtId(rmElmtId);
        this.__transferMessage.purgeDependencyOnElmtId(rmElmtId);
        this.__showTransferPanel.purgeDependencyOnElmtId(rmElmtId);
        this.__animScanPulse.purgeDependencyOnElmtId(rmElmtId);
        this.__materialLevel.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__devices.aboutToBeDeleted();
        this.__isScanning.aboutToBeDeleted();
        this.__isBroadcasting.aboutToBeDeleted();
        this.__broadcastError.aboutToBeDeleted();
        this.__myDeviceName.aboutToBeDeleted();
        this.__isDark.aboutToBeDeleted();
        this.__transferStatus.aboutToBeDeleted();
        this.__transferMessage.aboutToBeDeleted();
        this.__showTransferPanel.aboutToBeDeleted();
        this.__animScanPulse.aboutToBeDeleted();
        this.__materialLevel.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __devices: ObservedPropertyObjectPU<Device[]>;
    get devices() {
        return this.__devices.get();
    }
    set devices(newValue: Device[]) {
        this.__devices.set(newValue);
    }
    private __isScanning: ObservedPropertySimplePU<boolean>;
    get isScanning() {
        return this.__isScanning.get();
    }
    set isScanning(newValue: boolean) {
        this.__isScanning.set(newValue);
    }
    private __isBroadcasting: ObservedPropertySimplePU<boolean>;
    get isBroadcasting() {
        return this.__isBroadcasting.get();
    }
    set isBroadcasting(newValue: boolean) {
        this.__isBroadcasting.set(newValue);
    }
    private __broadcastError: ObservedPropertySimplePU<string>;
    get broadcastError() {
        return this.__broadcastError.get();
    }
    set broadcastError(newValue: string) {
        this.__broadcastError.set(newValue);
    }
    private __myDeviceName: ObservedPropertySimplePU<string>;
    get myDeviceName() {
        return this.__myDeviceName.get();
    }
    set myDeviceName(newValue: string) {
        this.__myDeviceName.set(newValue);
    }
    private __isDark: ObservedPropertySimplePU<boolean>;
    get isDark() {
        return this.__isDark.get();
    }
    set isDark(newValue: boolean) {
        this.__isDark.set(newValue);
    }
    private __transferStatus: ObservedPropertySimplePU<TransferState>;
    get transferStatus() {
        return this.__transferStatus.get();
    }
    set transferStatus(newValue: TransferState) {
        this.__transferStatus.set(newValue);
    }
    private __transferMessage: ObservedPropertySimplePU<string>;
    get transferMessage() {
        return this.__transferMessage.get();
    }
    set transferMessage(newValue: string) {
        this.__transferMessage.set(newValue);
    }
    private __showTransferPanel: ObservedPropertySimplePU<boolean>;
    get showTransferPanel() {
        return this.__showTransferPanel.get();
    }
    set showTransferPanel(newValue: boolean) {
        this.__showTransferPanel.set(newValue);
    }
    private __animScanPulse: ObservedPropertySimplePU<number>;
    get animScanPulse() {
        return this.__animScanPulse.get();
    }
    set animScanPulse(newValue: number) {
        this.__animScanPulse.set(newValue);
    }
    private tabsController: HdsTabsController;
    private discoveryService: DeviceDiscoveryService;
    private broadcastService: ShareBroadcastService;
    private transferService: FileTransferService;
    private __materialLevel: ObservedPropertySimplePU<hdsMaterial.MaterialLevel>;
    get materialLevel() {
        return this.__materialLevel.get();
    }
    set materialLevel(newValue: hdsMaterial.MaterialLevel) {
        this.__materialLevel.set(newValue);
    }
    aboutToAppear(): void {
        this.loadMyDeviceName();
        this.discoveryService.addListener(this.onDevicesDiscovered);
        this.broadcastService.addListener(this.onBroadcastStatusChange);
        this.transferService.addListener(this.onTransferStatusChange);
        const materialTypes = hdsMaterial.getSystemMaterialTypes();
        if (materialTypes.indexOf(hdsMaterial.MaterialType.IMMERSIVE) < 0) {
            this.materialLevel = hdsMaterial.MaterialLevel.SMOOTH;
        }
    }
    aboutToDisappear(): void {
        this.discoveryService.removeListener(this.onDevicesDiscovered);
        this.broadcastService.removeListener(this.onBroadcastStatusChange);
        this.transferService.removeListener(this.onTransferStatusChange);
        if (this.isScanning) {
            this.discoveryService.stopDiscovery();
        }
    }
    private onDevicesDiscovered: DeviceDiscoveryCallback;
    private onBroadcastStatusChange: BroadcastStatusCallback;
    private onTransferStatusChange: TransferStatusCallback;
    loadMyDeviceName(): void {
        try {
            const saved = AppStorage.get<string>('deviceName');
            if (saved) {
                this.myDeviceName = saved;
            }
        }
        catch (err) {
            hilog.info(0x0001, 'ToShare', 'No saved device name');
        }
    }
    toggleScan(): void {
        if (this.isScanning) {
            this.discoveryService.stopDiscovery();
            this.isScanning = false;
            this.devices = [];
        }
        else {
            this.discoveryService.startDiscovery();
            this.isScanning = true;
        }
    }
    toggleBroadcast(): void {
        if (this.isBroadcasting) {
            this.broadcastService.stopBroadcast();
        }
        else {
            this.requestBluetoothPermissionAndBroadcast();
        }
    }
    private async requestBluetoothPermissionAndBroadcast(): Promise<void> {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const permissions: Array<Permissions> = [
            'ohos.permission.ACCESS_BLUETOOTH',
            'ohos.permission.USE_BLUETOOTH'
        ];
        const atManager = abilityAccessCtrl.createAtManager();
        atManager.requestPermissionsFromUser(context, permissions).then(async (data) => {
            if (data.authResults.length >= 2 &&
                data.authResults[0] === 0 && data.authResults[1] === 0) {
                this.broadcastService.setDeviceName(this.myDeviceName);
                await this.broadcastService.startBroadcast();
            }
            else {
                this.broadcastError = '需要蓝牙权限才能开启广播';
                setTimeout(() => { this.broadcastError = ''; }, 3000);
            }
        }).catch((err: Error) => {
            this.broadcastError = `权限请求失败: ${err.message}`;
            setTimeout(() => { this.broadcastError = ''; }, 3000);
        });
    }
    async sendImageToDevice(device: Device): Promise<void> {
        try {
            const photoSelectOptions = new picker.PhotoSelectOptions();
            photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
            photoSelectOptions.maxSelectNumber = 1;
            const photoPicker = new picker.PhotoViewPicker();
            const result = await photoPicker.select(photoSelectOptions);
            if (result.photoUris.length === 0) {
                return;
            }
            const fileUri = result.photoUris[0];
            const fileName = fileUri.split('/').pop() || 'image.jpg';
            if (!this.isBroadcasting) {
                this.requestBluetoothPermissionAndBroadcast();
                await this.delay(1000);
            }
            this.showTransferPanel = true;
            this.transferService.startAsSender(fileUri, fileName);
        }
        catch (err) {
            hilog.error(0x0001, 'ToShare', 'Select photo failed: %{public}s', JSON.stringify(err));
        }
    }
    private delay(ms: number): Promise<void> {
        return new Promise<void>((resolve) => { setTimeout(resolve, ms); });
    }
    homeTabContent(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
        }, Column);
        // 头部区域
        this.buildHeader.bind(this)();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.width('100%');
            Scroll.layoutWeight(1);
            Scroll.scrollable(ScrollDirection.Vertical);
            Scroll.scrollBar(BarState.Off);
            Scroll.edgeEffect(EdgeEffect.Spring);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            __Common__.create();
            __Common__.margin({ left: 16, right: 16, top: 16, bottom: 0 });
        }, __Common__);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new 
                    // 我的设备卡片
                    MyDeviceCard(this, {
                        deviceName: this.myDeviceName,
                        isBroadcasting: this.isBroadcasting
                    }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/HomePage.ets", line: 175, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            deviceName: this.myDeviceName,
                            isBroadcasting: this.isBroadcasting
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        deviceName: this.myDeviceName,
                        isBroadcasting: this.isBroadcasting
                    });
                }
            }, { name: "MyDeviceCard" });
        }
        __Common__.pop();
        // 操作卡片区 —— 核心交互
        this.buildActionCards.bind(this)();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 错误提示卡片
            if (this.broadcastError !== '') {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.buildErrorCard.bind(this)();
                });
            }
            // 传输状态卡片
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 传输状态卡片
            if (this.showTransferPanel) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.buildTransferCard.bind(this)();
                });
            }
            // 设备列表区域
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        // 设备列表区域
        this.buildDeviceList.bind(this)();
        Column.pop();
        Scroll.pop();
        Column.pop();
    }
    // ─── Header ─────────────────────────────────────────────
    buildHeader(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.width('100%');
            Stack.height(102);
            Stack.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP]);
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 渐变背景
            Column.create();
            // 渐变背景
            Column.width('100%');
            // 渐变背景
            Column.height('100%');
            // 渐变背景
            Column.linearGradient({
                angle: 180,
                colors: [
                    ['#2D1B69', 0.0],
                    ['#4834D4', 0.4],
                    ['#6C5CE7', 0.75],
                    ['#A29BFE', 1.0]
                ]
            });
        }, Column);
        // 渐变背景
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 装饰光点
            Column.create();
            // 装饰光点
            Column.width(100);
            // 装饰光点
            Column.height(100);
            // 装饰光点
            Column.borderRadius(50);
            // 装饰光点
            Column.backgroundColor('#10FFFFFF');
            // 装饰光点
            Column.position({ x: -30, y: -20 });
        }, Column);
        // 装饰光点
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width(40);
            Column.height(40);
            Column.borderRadius(20);
            Column.backgroundColor('#15FFFFFF');
            Column.position({ x: '80%', y: 20 });
        }, Column);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 标题
            Row.create();
            // 标题
            Row.width('100%');
            // 标题
            Row.padding({ left: 18, right: 18, top: 4, bottom: 4 });
            // 标题
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 125831536, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" });
            Image.width(28);
            Image.height(28);
            Image.fillColor(Color.White);
            Image.margin({ right: 10 });
            Image.shadow({ radius: 8, color: '#40000000' });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('ToShare');
            Text.fontSize(26);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(Color.White);
            Text.letterSpacing(1);
            Text.shadow({ radius: 4, color: '#30000000' });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('跨平台文件互传');
            Text.fontSize(11);
            Text.fontColor('#C8C0FF');
            Text.letterSpacing(2);
            Text.margin({ top: 2 });
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 场景指示器
            Row.create();
            // 场景指示器
            Row.padding({ left: 12, right: 12, top: 5, bottom: 5 });
            // 场景指示器
            Row.borderRadius(12);
            // 场景指示器
            Row.backgroundColor('#15FFFFFF');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width(7);
            Column.height(7);
            Column.borderRadius(4);
            Column.backgroundColor(this.isBroadcasting ?
                AppColors.STATUS_ONLINE : AppColors.STATUS_OFFLINE);
            Column.margin({ right: 5 });
        }, Column);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.isBroadcasting ? '可见' : '隐藏');
            Text.fontSize(11);
            Text.fontColor('#C8C0FF');
        }, Text);
        Text.pop();
        // 场景指示器
        Row.pop();
        // 标题
        Row.pop();
        Stack.pop();
    }
    // ─── 操作卡片 ─────────────────────────────────────────
    buildActionCards(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.padding({ left: 16, right: 16, top: 12, bottom: 8 });
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 操作卡片容器
            Column.create();
            // 操作卡片容器
            Column.width('100%');
            // 操作卡片容器
            Column.padding(18);
            // 操作卡片容器
            Column.borderRadius(24);
            // 操作卡片容器
            Column.backgroundColor('#EEFFFFFF');
            // 操作卡片容器
            Column.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
            // 操作卡片容器
            Column.shadow({ radius: 12, color: '#12000000', offsetY: 3 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 标题行
            Row.create();
            // 标题行
            Row.margin({ bottom: 12 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 16777232, "type": 20000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" });
            Image.width(16);
            Image.height(16);
            Image.fillColor(AppColors.PRIMARY);
            Image.margin({ right: 6 });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('快捷操作');
            Text.fontSize(13);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(AppColors.PRIMARY);
        }, Text);
        Text.pop();
        // 标题行
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 双卡并排
            Row.create();
            // 双卡并排
            Row.width('100%');
            // 双卡并排
            Row.justifyContent(FlexAlign.SpaceBetween);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 卡片1: 让他人发现我
            Column.create();
            // 卡片1: 让他人发现我
            Column.width('47%');
            // 卡片1: 让他人发现我
            Column.padding(16);
            // 卡片1: 让他人发现我
            Column.borderRadius(20);
            // 卡片1: 让他人发现我
            Column.backgroundColor('#F8FFFFFF');
            // 卡片1: 让他人发现我
            Column.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
            // 卡片1: 让他人发现我
            Column.shadow({ radius: 8, color: '#10000000', offsetY: 2 });
            // 卡片1: 让他人发现我
            Column.alignItems(HorizontalAlign.Start);
            // 卡片1: 让他人发现我
            Column.onClick(() => { this.toggleBroadcast(); });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width(44);
            Column.height(44);
            Column.borderRadius(22);
            Column.linearGradient({
                angle: 135,
                colors: this.isBroadcasting ?
                    [['#FF6B6B', 0.0], ['#FF9F43', 1.0]] :
                    [['#6C5CE7', 0.0], ['#A29BFE', 1.0]]
            });
            Column.shadow({ radius: 10, color: this.isBroadcasting ? '#40FF6B6B' : '#406C5CE7' });
        }, Column);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 125832033, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" });
            Image.width(24);
            Image.height(24);
            Image.fillColor(Color.White);
            Image.position({ x: 10, y: 10 });
        }, Image);
        Stack.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width(1);
            Column.height(36);
            Column.backgroundColor('#12E6E1E5');
            Column.margin({ left: 6, right: 6 });
        }, Column);
        Column.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.isBroadcasting ? '已可见' : '让他人发现我');
            Text.fontSize(14);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(this.isBroadcasting ? '#FF6B6B' : AppColors.TEXT_PRIMARY_LIGHT);
            Text.margin({ top: 12 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.isBroadcasting ? '点击停止广播' : '开启互传广播');
            Text.fontSize(11);
            Text.fontColor(AppColors.TEXT_SECONDARY_LIGHT);
            Text.margin({ top: 4 });
        }, Text);
        Text.pop();
        // 卡片1: 让他人发现我
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 卡片2: 扫描设备
            Column.create();
            // 卡片2: 扫描设备
            Column.width('47%');
            // 卡片2: 扫描设备
            Column.padding(16);
            // 卡片2: 扫描设备
            Column.borderRadius(20);
            // 卡片2: 扫描设备
            Column.backgroundColor('#F8FFFFFF');
            // 卡片2: 扫描设备
            Column.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
            // 卡片2: 扫描设备
            Column.shadow({ radius: 8, color: '#10000000', offsetY: 2 });
            // 卡片2: 扫描设备
            Column.alignItems(HorizontalAlign.Start);
            // 卡片2: 扫描设备
            Column.onClick(() => { this.toggleScan(); });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width(44);
            Column.height(44);
            Column.borderRadius(22);
            Column.linearGradient({
                angle: 135,
                colors: this.isScanning ?
                    [['#00C9A7', 0.0], ['#55EFC4', 1.0]] :
                    [['#00A383', 0.0], ['#00C9A7', 1.0]]
            });
            Column.shadow({ radius: 10, color: '#4000C9A7' });
        }, Column);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 16777232, "type": 20000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" });
            Image.width(24);
            Image.height(24);
            Image.fillColor(Color.White);
            Image.position({ x: 10, y: 10 });
        }, Image);
        Stack.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width(1);
            Column.height(36);
            Column.backgroundColor('#12E6E1E5');
            Column.margin({ left: 6, right: 6 });
        }, Column);
        Column.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.isScanning ? '扫描中' : '扫描设备');
            Text.fontSize(14);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(this.isScanning ? '#00C9A7' : AppColors.TEXT_PRIMARY_LIGHT);
            Text.margin({ top: 12 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.isScanning ? `${this.devices.length} 台设备已发现` : '搜寻附近互传设备');
            Text.fontSize(11);
            Text.fontColor(AppColors.TEXT_SECONDARY_LIGHT);
            Text.margin({ top: 4 });
        }, Text);
        Text.pop();
        // 卡片2: 扫描设备
        Column.pop();
        // 双卡并排
        Row.pop();
        // 操作卡片容器
        Column.pop();
        Column.pop();
    }
    // ─── 错误卡片 ─────────────────────────────────────────
    buildErrorCard(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('92%');
            Row.padding(14);
            Row.borderRadius(16);
            Row.backgroundColor('#0FFF6B6B');
            Row.border({ width: 1, color: '#20FF6B6B' });
            Row.margin({ top: 8, bottom: 4 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 125832652, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" });
            Image.width(18);
            Image.height(18);
            Image.fillColor(AppColors.ERROR);
            Image.margin({ right: 10 });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.broadcastError);
            Text.fontSize(13);
            Text.fontColor(AppColors.ERROR);
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 125831487, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" });
            Image.width(16);
            Image.height(16);
            Image.fillColor('#A0FF6B6B');
            Image.onClick(() => { this.broadcastError = ''; });
        }, Image);
        Row.pop();
    }
    // ─── 传输状态卡片 ─────────────────────────────────────
    buildTransferCard(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('92%');
            Row.padding(14);
            Row.borderRadius(18);
            Row.backgroundColor('#F2FFFFFF');
            Row.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
            Row.shadow({ radius: 10, color: '#12000000', offsetY: 2 });
            Row.margin({ top: 8, bottom: 6 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.margin({ right: 12 });
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width(48);
            Column.height(48);
            Column.borderRadius(24);
            Column.linearGradient({
                angle: 135,
                colors: this.transferStatus === TransferState.COMPLETED ?
                    [['#00C9A7', 0.0], ['#55EFC4', 1.0]] :
                    this.transferStatus === TransferState.ERROR ?
                        [['#FF6B6B', 0.0], ['#FFBE76', 1.0]] :
                        [['#6C5CE7', 0.0], ['#A29BFE', 1.0]]
            });
        }, Column);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create(this.transferStatus === TransferState.COMPLETED ? { "id": 125831490, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" } :
                this.transferStatus === TransferState.ERROR ? { "id": 125831487, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" } : { "id": 125831535, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" });
            Image.width(24);
            Image.height(24);
            Image.fillColor(Color.White);
        }, Image);
        Stack.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.transferMessage || this.getTransferLabel());
            Text.fontSize(14);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(AppColors.TEXT_PRIMARY_LIGHT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.transferStatus === TransferState.TRANSFERRING) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.margin({ top: 4 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        LoadingProgress.create();
                        LoadingProgress.width(12);
                        LoadingProgress.height(12);
                        LoadingProgress.color('#6C5CE7');
                        LoadingProgress.margin({ right: 4 });
                    }, LoadingProgress);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('传输中...');
                        Text.fontSize(11);
                        Text.fontColor('#6C5CE7');
                    }, Text);
                    Text.pop();
                    Row.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        Row.pop();
    }
    private getTransferLabel(): string {
        switch (this.transferStatus) {
            case TransferState.CREATING_GROUP:
                return '正在创建连接通道...';
            case TransferState.P2P_CONNECTING:
                return '等待对方连接...';
            case TransferState.GROUP_CREATED:
                return '通道已创建';
            case TransferState.P2P_CONNECTED:
                return 'Wi-Fi Direct 已连接';
            case TransferState.SOCKET_LISTENING:
                return '等待文件传输...';
            case TransferState.TRANSFERRING:
                return '正在传输文件...';
            case TransferState.COMPLETED:
                return '传输完成!';
            case TransferState.ERROR:
                return '传输失败';
            default:
                return '';
        }
    }
    // ─── 设备列表区域 ─────────────────────────────────────
    buildDeviceList(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 区域标题
            Row.create();
            // 区域标题
            Row.width('100%');
            // 区域标题
            Row.padding({ left: 20, right: 20, top: 20, bottom: 10 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 125832033, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" });
            Image.width(16);
            Image.height(16);
            Image.fillColor(AppColors.TEXT_SECONDARY_LIGHT);
            Image.margin({ right: 6 });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('附近设备');
            Text.fontSize(13);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(AppColors.TEXT_SECONDARY_LIGHT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.devices.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`· ${this.devices.length}`);
                        Text.fontSize(13);
                        Text.fontColor(AppColors.PRIMARY);
                        Text.fontWeight(FontWeight.Medium);
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        // 区域标题
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 扫描中 - 空状态
            if (this.isScanning && this.devices.length === 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.buildSearchingState.bind(this)();
                });
            }
            // 未扫描 - 空状态
            else if (!this.isScanning && this.devices.length === 0) {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.buildEmptyState.bind(this)();
                });
            }
            // 有设备 - 列表
            else {
                this.ifElseBranchUpdateFunction(2, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const device = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                __Common__.create();
                                __Common__.margin({ left: 16, right: 16, bottom: 8 });
                                __Common__.onClick(() => { this.sendImageToDevice(device); });
                            }, __Common__);
                            {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    if (isInitialRender) {
                                        let componentCall = new DeviceCard(this, { device: device }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/HomePage.ets", line: 585, col: 13 });
                                        ViewPU.create(componentCall);
                                        let paramsLambda = () => {
                                            return {
                                                device: device
                                            };
                                        };
                                        componentCall.paramsGenerator_ = paramsLambda;
                                    }
                                    else {
                                        this.updateStateVarsOfChildByElmtId(elmtId, {
                                            device: device
                                        });
                                    }
                                }, { name: "DeviceCard" });
                            }
                            __Common__.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.devices, forEachItemGenFunction, (device: Device) => device.id, false, false);
                    }, ForEach);
                    ForEach.pop();
                    Column.pop();
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 底部安全间距
            Column.create();
            // 底部安全间距
            Column.width('100%');
            // 底部安全间距
            Column.height(88);
        }, Column);
        // 底部安全间距
        Column.pop();
        Column.pop();
    }
    buildSearchingState(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('94%');
            Column.borderRadius(24);
            Column.backgroundColor('#F0FFFFFF');
            Column.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
            Column.shadow({ radius: 8, color: '#08000000', offsetY: 1 });
            Column.margin({ left: 16, right: 16 });
            Column.onAppear(() => {
                this.animScanPulse = 1.3;
            });
            Column.onDisAppear(() => {
                this.animScanPulse = 1;
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding({ top: 30, bottom: 40 });
            Column.justifyContent(FlexAlign.Center);
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 雷达动画
            Stack.create();
            // 雷达动画
            Stack.margin({ bottom: 20 });
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            globalThis.Context.animation({
                duration: 1500,
                curve: Curve.EaseInOut,
                iterations: -1,
                playMode: PlayMode.Alternate
            });
            Column.width(80);
            Column.height(80);
            Column.borderRadius(40);
            Column.border({ width: 2, color: '#30A29BFE' });
            Column.scale({ x: this.animScanPulse, y: this.animScanPulse });
            Column.opacity(0.5);
            globalThis.Context.animation(null);
        }, Column);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            globalThis.Context.animation({
                duration: 1500,
                curve: Curve.EaseInOut,
                iterations: -1,
                playMode: PlayMode.AlternateReverse
            });
            Column.width(50);
            Column.height(50);
            Column.borderRadius(25);
            Column.border({ width: 1.5, color: '#20A29BFE' });
            Column.scale({ x: 1.5 - this.animScanPulse, y: 1.5 - this.animScanPulse });
            Column.opacity(0.4);
            globalThis.Context.animation(null);
        }, Column);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width(36);
            Column.height(36);
            Column.borderRadius(18);
            Column.linearGradient({
                angle: 135,
                colors: [['#6C5CE7', 0.0], ['#A29BFE', 1.0]]
            });
        }, Column);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 16777232, "type": 20000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" });
            Image.width(20);
            Image.height(20);
            Image.fillColor(Color.White);
        }, Image);
        // 雷达动画
        Stack.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('正在搜寻附近设备');
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(AppColors.TEXT_PRIMARY_LIGHT);
            Text.margin({ bottom: 6 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('请确保对方也已开启互传广播');
            Text.fontSize(12);
            Text.fontColor(AppColors.TEXT_SECONDARY_LIGHT);
        }, Text);
        Text.pop();
        Column.pop();
        Column.pop();
    }
    buildEmptyState(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('94%');
            Column.borderRadius(24);
            Column.backgroundColor('#F0FFFFFF');
            Column.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
            Column.shadow({ radius: 8, color: '#08000000', offsetY: 1 });
            Column.margin({ left: 16, right: 16 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding({ top: 30, bottom: 40 });
            Column.justifyContent(FlexAlign.Center);
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 125832011, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" });
            Image.width(48);
            Image.height(48);
            Image.fillColor('#A29BFE');
            Image.margin({ bottom: 18 });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('没有发现设备');
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(AppColors.TEXT_PRIMARY_LIGHT);
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('开启可见或扫描来发现附近设备');
            Text.fontSize(12);
            Text.fontColor(AppColors.TEXT_SECONDARY_LIGHT);
            Text.textAlign(TextAlign.Center);
            Text.margin({ bottom: 20 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.linearGradient({
                angle: 135,
                colors: [['#6C5CE7', 0.0], ['#A29BFE', 1.0]]
            });
            Button.borderRadius(18);
            Button.height(38);
            Button.padding({ left: 20, right: 20 });
            Button.shadow({ radius: 8, color: '#306C5CE7' });
            Button.onClick(() => { this.toggleBroadcast(); });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('让他人发现我');
            Text.fontSize(13);
            Text.fontColor(Color.White);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width(12);
        }, Column);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.backgroundColor('#15A29BFE');
            Button.borderRadius(18);
            Button.height(38);
            Button.padding({ left: 20, right: 20 });
            Button.onClick(() => { this.toggleScan(); });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('扫描设备');
            Text.fontSize(13);
            Text.fontColor('#6C5CE7');
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        Button.pop();
        Row.pop();
        Column.pop();
        Column.pop();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(AppTheme.getBackground(this.isDark));
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            HdsTabs.create({ controller: this.tabsController });
            HdsTabs.barOverlap(true);
            HdsTabs.barPosition(BarPosition.End);
            HdsTabs.vertical(false);
            HdsTabs.barFloatingStyle({
                barBottomMargin: 24,
                systemMaterialEffect: {
                    materialType: hdsMaterial.MaterialType.ADAPTIVE,
                    materialLevel: this.materialLevel
                }
            });
            HdsTabs.scrollable(false);
            HdsTabs.barMode(BarMode.Fixed);
            HdsTabs.animationDuration(200);
        }, HdsTabs);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                this.homeTabContent.bind(this)();
            });
            TabContent.tabBar(new BottomTabBarStyle({
                normal: new SymbolGlyphModifier({ "id": 125831534, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" })
                    .fontColor([{ "id": 125829426, "type": 10001, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" }]),
                selected: new SymbolGlyphModifier({ "id": 125831534, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" })
                    .fontColor([{ "id": 125829201, "type": 10001, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" }])
            }, '首页'));
        }, TabContent);
        TabContent.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new SendPage(this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/HomePage.ets", line: 761, col: 11 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {};
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {});
                        }
                    }, { name: "SendPage" });
                }
            });
            TabContent.tabBar(new BottomTabBarStyle({
                normal: new SymbolGlyphModifier({ "id": 125832671, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" })
                    .fontColor([{ "id": 125829426, "type": 10001, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" }]),
                selected: new SymbolGlyphModifier({ "id": 125832671, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" })
                    .fontColor([{ "id": 125829201, "type": 10001, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" }])
            }, '发送'));
        }, TabContent);
        TabContent.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new ReceivePage(this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/HomePage.ets", line: 771, col: 11 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {};
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {});
                        }
                    }, { name: "ReceivePage" });
                }
            });
            TabContent.tabBar(new BottomTabBarStyle({
                normal: new SymbolGlyphModifier({ "id": 125832675, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" })
                    .fontColor([{ "id": 125829426, "type": 10001, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" }]),
                selected: new SymbolGlyphModifier({ "id": 125832675, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" })
                    .fontColor([{ "id": 125829201, "type": 10001, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" }])
            }, '接收'));
        }, TabContent);
        TabContent.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new HistoryPage(this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/HomePage.ets", line: 781, col: 11 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {};
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {});
                        }
                    }, { name: "HistoryPage" });
                }
            });
            TabContent.tabBar(new BottomTabBarStyle({
                normal: new SymbolGlyphModifier({ "id": 125832302, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" })
                    .fontColor([{ "id": 125829426, "type": 10001, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" }]),
                selected: new SymbolGlyphModifier({ "id": 125832302, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" })
                    .fontColor([{ "id": 125829201, "type": 10001, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" }])
            }, '历史'));
        }, TabContent);
        TabContent.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new SettingsPage(this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/HomePage.ets", line: 791, col: 11 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {};
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {});
                        }
                    }, { name: "SettingsPage" });
                }
            });
            TabContent.tabBar(new BottomTabBarStyle({
                normal: new SymbolGlyphModifier({ "id": 125831493, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" })
                    .fontColor([{ "id": 125829426, "type": 10001, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" }]),
                selected: new SymbolGlyphModifier({ "id": 125831493, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" })
                    .fontColor([{ "id": 125829201, "type": 10001, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" }])
            }, '设置'));
        }, TabContent);
        TabContent.pop();
        HdsTabs.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "HomePage";
    }
}
registerNamedRoute(() => new HomePage(undefined, {}), "", { bundleName: "com.toshare.harmonyos", moduleName: "entry", pagePath: "pages/HomePage", pageFullPath: "entry/src/main/ets/pages/HomePage", integratedHsp: "false", moduleType: "followWithHap" });
