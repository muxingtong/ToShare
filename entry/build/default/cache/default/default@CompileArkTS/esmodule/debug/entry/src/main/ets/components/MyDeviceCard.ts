if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface MyDeviceCard_Params {
    deviceName?: string;
    isBroadcasting?: boolean;
}
import { AppColors } from "@normalized:N&&&entry/src/main/ets/theme/AppColors&";
export class MyDeviceCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__deviceName = new SynchedPropertySimpleOneWayPU(params.deviceName, this, "deviceName");
        this.__isBroadcasting = new SynchedPropertySimpleOneWayPU(params.isBroadcasting, this, "isBroadcasting");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: MyDeviceCard_Params) {
        if (params.deviceName === undefined) {
            this.__deviceName.set('我的设备');
        }
        if (params.isBroadcasting === undefined) {
            this.__isBroadcasting.set(false);
        }
    }
    updateStateVars(params: MyDeviceCard_Params) {
        this.__deviceName.reset(params.deviceName);
        this.__isBroadcasting.reset(params.isBroadcasting);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__deviceName.purgeDependencyOnElmtId(rmElmtId);
        this.__isBroadcasting.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__deviceName.aboutToBeDeleted();
        this.__isBroadcasting.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __deviceName: SynchedPropertySimpleOneWayPU<string>;
    get deviceName() {
        return this.__deviceName.get();
    }
    set deviceName(newValue: string) {
        this.__deviceName.set(newValue);
    }
    private __isBroadcasting: SynchedPropertySimpleOneWayPU<boolean>;
    get isBroadcasting() {
        return this.__isBroadcasting.get();
    }
    set isBroadcasting(newValue: boolean) {
        this.__isBroadcasting.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.padding(18);
            Column.borderRadius(24);
            Column.backgroundColor('#F4FFFFFF');
            Column.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
            Column.shadow({ radius: 14, color: '#14000000', offsetY: 4 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 设备头像 —— 渐变圆形 + 符号图标
            Stack.create();
            // 设备头像 —— 渐变圆形 + 符号图标
            Stack.margin({ right: 14 });
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width(56);
            Column.height(56);
            Column.borderRadius(28);
            Column.linearGradient({
                angle: 135,
                colors: [
                    ['#6C5CE7', 0.0],
                    ['#A29BFE', 1.0]
                ]
            });
            Column.shadow({ radius: 12, color: '#406C5CE7' });
        }, Column);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 16777230, "type": 20000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" });
            Image.width(30);
            Image.height(30);
            Image.fillColor(Color.White);
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 广播状态指示器
            if (this.isBroadcasting) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width(16);
                        Column.height(16);
                        Column.borderRadius(8);
                        Column.backgroundColor(AppColors.STATUS_ONLINE);
                        Column.border({ width: 2.5, color: Color.White });
                        Column.position({ x: 42, y: 42 });
                        Column.shadow({ radius: 4, color: '#4000C9A7' });
                    }, Column);
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        // 设备头像 —— 渐变圆形 + 符号图标
        Stack.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 设备信息
            Column.create();
            // 设备信息
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.deviceName);
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(AppColors.TEXT_PRIMARY_LIGHT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.margin({ top: 4 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.isBroadcasting ? '● 互传广播已开启' : '○ 未广播');
            Text.fontSize(12);
            Text.fontColor(this.isBroadcasting ? '#00A383' : AppColors.TEXT_SECONDARY_LIGHT);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        Row.pop();
        // 设备信息
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 右侧操作区
            Column.create();
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 二维码入口
            Row.create();
            // 二维码入口
            Row.width(44);
            // 二维码入口
            Row.height(44);
            // 二维码入口
            Row.borderRadius(22);
            // 二维码入口
            Row.justifyContent(FlexAlign.Center);
            // 二维码入口
            Row.backgroundColor('#E8FFFFFF');
            // 二维码入口
            Row.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
            // 二维码入口
            Row.onClick(() => {
                AppStorage.set<string>('showQrCode', 'true');
            });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 125831600, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" });
            Image.width(22);
            Image.height(22);
            Image.fillColor('#6C5CE7');
        }, Image);
        // 二维码入口
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('二维码');
            Text.fontSize(10);
            Text.fontColor(AppColors.TEXT_SECONDARY_LIGHT);
            Text.margin({ top: 4 });
        }, Text);
        Text.pop();
        // 右侧操作区
        Column.pop();
        Row.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
