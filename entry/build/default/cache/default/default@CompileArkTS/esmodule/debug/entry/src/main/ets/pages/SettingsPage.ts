if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SettingsPage_Params {
    deviceName?: string;
    autoReceive?: boolean;
    showNotification?: boolean;
    preferredProtocol?: number;
    enableResume?: boolean;
    themeMode?: number;
    retentionDays?: number;
    cacheSize?: number;
    isDark?: boolean;
    headerGradient?: HeaderGradient;
    protocols?: string[];
    retentionOptions?: number[];
    retentionLabels?: string[];
}
import { FileSizeFormatter } from "@normalized:N&&&entry/src/main/ets/utils/FileSizeFormatter&";
import { HeaderGradient } from "@normalized:N&&&entry/src/main/ets/theme/AppTheme&";
import hilog from "@ohos:hilog";
export class SettingsPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__deviceName = new ObservedPropertySimplePU('我的设备', this, "deviceName");
        this.__autoReceive = new ObservedPropertySimplePU(true, this, "autoReceive");
        this.__showNotification = new ObservedPropertySimplePU(true, this, "showNotification");
        this.__preferredProtocol = new ObservedPropertySimplePU(0, this, "preferredProtocol");
        this.__enableResume = new ObservedPropertySimplePU(true, this, "enableResume");
        this.__themeMode = new ObservedPropertySimplePU(0, this, "themeMode");
        this.__retentionDays = new ObservedPropertySimplePU(30, this, "retentionDays");
        this.__cacheSize = new ObservedPropertySimplePU(0, this, "cacheSize");
        this.__isDark = new ObservedPropertySimplePU(false, this, "isDark");
        this.headerGradient = new HeaderGradient();
        this.protocols = ['WiFi直连', '蓝牙', 'NFC'];
        this.retentionOptions = [7, 30, 90, -1];
        this.retentionLabels = ['7天', '30天', '90天', '永久'];
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SettingsPage_Params) {
        if (params.deviceName !== undefined) {
            this.deviceName = params.deviceName;
        }
        if (params.autoReceive !== undefined) {
            this.autoReceive = params.autoReceive;
        }
        if (params.showNotification !== undefined) {
            this.showNotification = params.showNotification;
        }
        if (params.preferredProtocol !== undefined) {
            this.preferredProtocol = params.preferredProtocol;
        }
        if (params.enableResume !== undefined) {
            this.enableResume = params.enableResume;
        }
        if (params.themeMode !== undefined) {
            this.themeMode = params.themeMode;
        }
        if (params.retentionDays !== undefined) {
            this.retentionDays = params.retentionDays;
        }
        if (params.cacheSize !== undefined) {
            this.cacheSize = params.cacheSize;
        }
        if (params.isDark !== undefined) {
            this.isDark = params.isDark;
        }
        if (params.headerGradient !== undefined) {
            this.headerGradient = params.headerGradient;
        }
        if (params.protocols !== undefined) {
            this.protocols = params.protocols;
        }
        if (params.retentionOptions !== undefined) {
            this.retentionOptions = params.retentionOptions;
        }
        if (params.retentionLabels !== undefined) {
            this.retentionLabels = params.retentionLabels;
        }
    }
    updateStateVars(params: SettingsPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__deviceName.purgeDependencyOnElmtId(rmElmtId);
        this.__autoReceive.purgeDependencyOnElmtId(rmElmtId);
        this.__showNotification.purgeDependencyOnElmtId(rmElmtId);
        this.__preferredProtocol.purgeDependencyOnElmtId(rmElmtId);
        this.__enableResume.purgeDependencyOnElmtId(rmElmtId);
        this.__themeMode.purgeDependencyOnElmtId(rmElmtId);
        this.__retentionDays.purgeDependencyOnElmtId(rmElmtId);
        this.__cacheSize.purgeDependencyOnElmtId(rmElmtId);
        this.__isDark.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__deviceName.aboutToBeDeleted();
        this.__autoReceive.aboutToBeDeleted();
        this.__showNotification.aboutToBeDeleted();
        this.__preferredProtocol.aboutToBeDeleted();
        this.__enableResume.aboutToBeDeleted();
        this.__themeMode.aboutToBeDeleted();
        this.__retentionDays.aboutToBeDeleted();
        this.__cacheSize.aboutToBeDeleted();
        this.__isDark.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __deviceName: ObservedPropertySimplePU<string>;
    get deviceName() {
        return this.__deviceName.get();
    }
    set deviceName(newValue: string) {
        this.__deviceName.set(newValue);
    }
    private __autoReceive: ObservedPropertySimplePU<boolean>;
    get autoReceive() {
        return this.__autoReceive.get();
    }
    set autoReceive(newValue: boolean) {
        this.__autoReceive.set(newValue);
    }
    private __showNotification: ObservedPropertySimplePU<boolean>;
    get showNotification() {
        return this.__showNotification.get();
    }
    set showNotification(newValue: boolean) {
        this.__showNotification.set(newValue);
    }
    private __preferredProtocol: ObservedPropertySimplePU<number>;
    get preferredProtocol() {
        return this.__preferredProtocol.get();
    }
    set preferredProtocol(newValue: number) {
        this.__preferredProtocol.set(newValue);
    }
    private __enableResume: ObservedPropertySimplePU<boolean>;
    get enableResume() {
        return this.__enableResume.get();
    }
    set enableResume(newValue: boolean) {
        this.__enableResume.set(newValue);
    }
    private __themeMode: ObservedPropertySimplePU<number>;
    get themeMode() {
        return this.__themeMode.get();
    }
    set themeMode(newValue: number) {
        this.__themeMode.set(newValue);
    }
    private __retentionDays: ObservedPropertySimplePU<number>;
    get retentionDays() {
        return this.__retentionDays.get();
    }
    set retentionDays(newValue: number) {
        this.__retentionDays.set(newValue);
    }
    private __cacheSize: ObservedPropertySimplePU<number>;
    get cacheSize() {
        return this.__cacheSize.get();
    }
    set cacheSize(newValue: number) {
        this.__cacheSize.set(newValue);
    }
    private __isDark: ObservedPropertySimplePU<boolean>;
    get isDark() {
        return this.__isDark.get();
    }
    set isDark(newValue: boolean) {
        this.__isDark.set(newValue);
    }
    private headerGradient: HeaderGradient;
    private protocols: string[];
    private retentionOptions: number[];
    private retentionLabels: string[];
    aboutToAppear(): void {
        try {
            const savedName = AppStorage.get<string>('deviceName');
            if (savedName) {
                this.deviceName = savedName;
            }
        }
        catch (err) {
            hilog.info(0x0001, 'ToShare', 'No saved settings');
        }
    }
    saveDeviceName(): void {
        AppStorage.set<string>('deviceName', this.deviceName);
    }
    clearCache(): void {
        this.cacheSize = 0;
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#F0EFF5');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.width('100%');
            Stack.height(80);
            Stack.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP]);
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.linearGradient({
                angle: this.headerGradient.angle,
                colors: this.headerGradient.colors
            });
        }, Column);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.padding({ left: 20, right: 20, top: 4, bottom: 4 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('设置');
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(Color.White);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        Row.pop();
        Stack.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            List.create();
            List.width('100%');
            List.layoutWeight(1);
        }, List);
        {
            const itemCreation = (elmtId, isInitialRender) => {
                ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                ListItem.create(deepRenderFunction, true);
                if (!isInitialRender) {
                    // 设备信息
                    ListItem.pop();
                }
                ViewStackProcessor.StopGetAccessRecording();
            };
            const itemCreation2 = (elmtId, isInitialRender) => {
                ListItem.create(deepRenderFunction, true);
            };
            const deepRenderFunction = (elmtId, isInitialRender) => {
                itemCreation(elmtId, isInitialRender);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create();
                    Column.padding(16);
                    Column.borderRadius(18);
                    Column.backgroundColor('#F2FFFFFF');
                    Column.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
                    Column.shadow({ radius: 4, color: '#0A000000', offsetY: 1 });
                    Column.margin({ left: 20, right: 20, bottom: 8 });
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('设备信息');
                    Text.fontSize(15);
                    Text.fontWeight(FontWeight.Bold);
                    Text.fontColor('#1C1B1F');
                    Text.width('100%');
                    Text.margin({ bottom: 10 });
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('设备名称');
                    Text.fontSize(14);
                    Text.fontColor('#625B71');
                    Text.layoutWeight(1);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    TextInput.create({ placeholder: '输入设备名称', text: this.deviceName });
                    TextInput.fontSize(14);
                    TextInput.textAlign(TextAlign.End);
                    TextInput.width(160);
                    TextInput.onChange((value: string) => {
                        this.deviceName = value;
                        this.saveDeviceName();
                    });
                }, TextInput);
                Row.pop();
                Column.pop();
                // 设备信息
                ListItem.pop();
            };
            this.observeComponentCreation2(itemCreation2, ListItem);
            // 设备信息
            ListItem.pop();
        }
        {
            const itemCreation = (elmtId, isInitialRender) => {
                ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                ListItem.create(deepRenderFunction, true);
                if (!isInitialRender) {
                    // 传输偏好
                    ListItem.pop();
                }
                ViewStackProcessor.StopGetAccessRecording();
            };
            const itemCreation2 = (elmtId, isInitialRender) => {
                ListItem.create(deepRenderFunction, true);
            };
            const deepRenderFunction = (elmtId, isInitialRender) => {
                itemCreation(elmtId, isInitialRender);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create();
                    Column.padding(16);
                    Column.borderRadius(18);
                    Column.backgroundColor('#F2FFFFFF');
                    Column.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
                    Column.shadow({ radius: 4, color: '#0A000000', offsetY: 1 });
                    Column.margin({ left: 20, right: 20, bottom: 8 });
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('传输偏好');
                    Text.fontSize(15);
                    Text.fontWeight(FontWeight.Bold);
                    Text.fontColor('#1C1B1F');
                    Text.width('100%');
                    Text.margin({ bottom: 10 });
                }, Text);
                Text.pop();
                this.settingToggle.bind(this)('自动接收', this.autoReceive, (v) => { this.autoReceive = v; });
                this.settingToggle.bind(this)('传输通知', this.showNotification, (v) => { this.showNotification = v; });
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.padding({ top: 10, bottom: 10 });
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('首选协议');
                    Text.fontSize(14);
                    Text.fontColor('#625B71');
                    Text.layoutWeight(1);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Select.create([{ value: 'WiFi直连' }, { value: '蓝牙' }, { value: 'NFC' }]);
                    Select.font({ size: 14 });
                    Select.onSelect((index: number) => { this.preferredProtocol = index; });
                }, Select);
                Select.pop();
                Row.pop();
                this.settingToggle.bind(this)('断点续传', this.enableResume, (v) => { this.enableResume = v; });
                Column.pop();
                // 传输偏好
                ListItem.pop();
            };
            this.observeComponentCreation2(itemCreation2, ListItem);
            // 传输偏好
            ListItem.pop();
        }
        {
            const itemCreation = (elmtId, isInitialRender) => {
                ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                ListItem.create(deepRenderFunction, true);
                if (!isInitialRender) {
                    // 外观
                    ListItem.pop();
                }
                ViewStackProcessor.StopGetAccessRecording();
            };
            const itemCreation2 = (elmtId, isInitialRender) => {
                ListItem.create(deepRenderFunction, true);
            };
            const deepRenderFunction = (elmtId, isInitialRender) => {
                itemCreation(elmtId, isInitialRender);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create();
                    Column.padding(16);
                    Column.borderRadius(18);
                    Column.backgroundColor('#F2FFFFFF');
                    Column.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
                    Column.shadow({ radius: 4, color: '#0A000000', offsetY: 1 });
                    Column.margin({ left: 20, right: 20, bottom: 8 });
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('外观');
                    Text.fontSize(15);
                    Text.fontWeight(FontWeight.Bold);
                    Text.fontColor('#1C1B1F');
                    Text.width('100%');
                    Text.margin({ bottom: 10 });
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.padding({ top: 10, bottom: 10 });
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('主题模式');
                    Text.fontSize(14);
                    Text.fontColor('#625B71');
                    Text.layoutWeight(1);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Select.create([{ value: '跟随系统' }, { value: '浅色' }, { value: '深色' }]);
                    Select.font({ size: 14 });
                    Select.onSelect((index: number) => { this.themeMode = index; });
                }, Select);
                Select.pop();
                Row.pop();
                Column.pop();
                // 外观
                ListItem.pop();
            };
            this.observeComponentCreation2(itemCreation2, ListItem);
            // 外观
            ListItem.pop();
        }
        {
            const itemCreation = (elmtId, isInitialRender) => {
                ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                ListItem.create(deepRenderFunction, true);
                if (!isInitialRender) {
                    // 存储管理
                    ListItem.pop();
                }
                ViewStackProcessor.StopGetAccessRecording();
            };
            const itemCreation2 = (elmtId, isInitialRender) => {
                ListItem.create(deepRenderFunction, true);
            };
            const deepRenderFunction = (elmtId, isInitialRender) => {
                itemCreation(elmtId, isInitialRender);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create();
                    Column.padding(16);
                    Column.borderRadius(18);
                    Column.backgroundColor('#F2FFFFFF');
                    Column.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
                    Column.shadow({ radius: 4, color: '#0A000000', offsetY: 1 });
                    Column.margin({ left: 20, right: 20, bottom: 8 });
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('存储管理');
                    Text.fontSize(15);
                    Text.fontWeight(FontWeight.Bold);
                    Text.fontColor('#1C1B1F');
                    Text.width('100%');
                    Text.margin({ bottom: 10 });
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.padding({ top: 10, bottom: 10 });
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('历史记录保留');
                    Text.fontSize(14);
                    Text.fontColor('#625B71');
                    Text.layoutWeight(1);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Select.create([{ value: '7天' }, { value: '30天' }, { value: '90天' }, { value: '永久' }]);
                    Select.font({ size: 14 });
                    Select.onSelect((index: number) => { this.retentionDays = this.retentionOptions[index]; });
                }, Select);
                Select.pop();
                Row.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.padding({ top: 10, bottom: 10 });
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('缓存大小');
                    Text.fontSize(14);
                    Text.fontColor('#625B71');
                    Text.layoutWeight(1);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(FileSizeFormatter.formatSize(this.cacheSize));
                    Text.fontSize(14);
                    Text.fontColor('#625B71');
                    Text.margin({ right: 8 });
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Button.createWithLabel('清除');
                    Button.fontSize(12);
                    Button.fontColor('#FF6B6B');
                    Button.backgroundColor('#12FF6B6B');
                    Button.borderRadius(14);
                    Button.height(28);
                    Button.padding({ left: 14, right: 14 });
                    Button.onClick(() => { this.clearCache(); });
                }, Button);
                Button.pop();
                Row.pop();
                Column.pop();
                // 存储管理
                ListItem.pop();
            };
            this.observeComponentCreation2(itemCreation2, ListItem);
            // 存储管理
            ListItem.pop();
        }
        {
            const itemCreation = (elmtId, isInitialRender) => {
                ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                ListItem.create(deepRenderFunction, true);
                if (!isInitialRender) {
                    // 关于
                    ListItem.pop();
                }
                ViewStackProcessor.StopGetAccessRecording();
            };
            const itemCreation2 = (elmtId, isInitialRender) => {
                ListItem.create(deepRenderFunction, true);
            };
            const deepRenderFunction = (elmtId, isInitialRender) => {
                itemCreation(elmtId, isInitialRender);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create();
                    Column.padding(16);
                    Column.borderRadius(18);
                    Column.backgroundColor('#F2FFFFFF');
                    Column.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
                    Column.shadow({ radius: 4, color: '#0A000000', offsetY: 1 });
                    Column.margin({ left: 20, right: 20, bottom: 8 });
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('关于');
                    Text.fontSize(15);
                    Text.fontWeight(FontWeight.Bold);
                    Text.fontColor('#1C1B1F');
                    Text.width('100%');
                    Text.margin({ bottom: 10 });
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.padding({ top: 4, bottom: 4 });
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('应用版本');
                    Text.fontSize(14);
                    Text.fontColor('#625B71');
                    Text.layoutWeight(1);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('1.0.0');
                    Text.fontSize(14);
                    Text.fontColor('#625B71');
                }, Text);
                Text.pop();
                Row.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.padding({ top: 4, bottom: 4 });
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('构建版本');
                    Text.fontSize(14);
                    Text.fontColor('#625B71');
                    Text.layoutWeight(1);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('2024.1');
                    Text.fontSize(14);
                    Text.fontColor('#625B71');
                }, Text);
                Text.pop();
                Row.pop();
                Column.pop();
                // 关于
                ListItem.pop();
            };
            this.observeComponentCreation2(itemCreation2, ListItem);
            // 关于
            ListItem.pop();
        }
        {
            const itemCreation = (elmtId, isInitialRender) => {
                ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                ListItem.create(deepRenderFunction, true);
                if (!isInitialRender) {
                    // 底部占位
                    ListItem.pop();
                }
                ViewStackProcessor.StopGetAccessRecording();
            };
            const itemCreation2 = (elmtId, isInitialRender) => {
                ListItem.create(deepRenderFunction, true);
            };
            const deepRenderFunction = (elmtId, isInitialRender) => {
                itemCreation(elmtId, isInitialRender);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.width('100%');
                    Row.height(80);
                }, Row);
                Row.pop();
                // 底部占位
                ListItem.pop();
            };
            this.observeComponentCreation2(itemCreation2, ListItem);
            // 底部占位
            ListItem.pop();
        }
        List.pop();
        Column.pop();
    }
    settingToggle(label: string, isOn: boolean, onChange: (v: boolean) => void, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.padding({ top: 10, bottom: 10 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.fontSize(14);
            Text.fontColor('#625B71');
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Toggle.create({ type: ToggleType.Switch, isOn: isOn });
            Toggle.onChange(onChange);
        }, Toggle);
        Toggle.pop();
        Row.pop();
    }
    getRetentionLabel(): string {
        const idx = this.retentionOptions.indexOf(this.retentionDays);
        return idx >= 0 ? this.retentionLabels[idx] : '30天';
    }
    rerender() {
        this.updateDirtyElements();
    }
}
