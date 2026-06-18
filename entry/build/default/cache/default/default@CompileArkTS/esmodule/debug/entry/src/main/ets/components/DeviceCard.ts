if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface DeviceCard_Params {
    device?: Device;
}
import { Device } from "@normalized:N&&&entry/src/main/ets/models/Device&";
import { TransportProtocol, DeviceType, DeviceStatus } from "@normalized:N&&&entry/src/main/ets/models/Enums&";
import { ProtocolBadge } from "@normalized:N&&&entry/src/main/ets/components/ProtocolBadge&";
import { AppColors } from "@normalized:N&&&entry/src/main/ets/theme/AppColors&";
export class DeviceCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__device = new SynchedPropertyObjectOneWayPU(params.device, this, "device");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: DeviceCard_Params) {
        if (params.device === undefined) {
            this.__device.set(new Device('', '', '', DeviceType.MOBILE, [], 0, DeviceStatus.ONLINE, 0));
        }
    }
    updateStateVars(params: DeviceCard_Params) {
        this.__device.reset(params.device);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__device.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__device.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __device: SynchedPropertySimpleOneWayPU<Device>;
    get device() {
        return this.__device.get();
    }
    set device(newValue: Device) {
        this.__device.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.padding(16);
            Row.borderRadius(20);
            Row.backgroundColor('#F2FFFFFF');
            Row.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
            Row.shadow({ radius: 8, color: '#10000000', offsetY: 2 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 左侧：设备图标 + 在线指示
            Stack.create();
            // 左侧：设备图标 + 在线指示
            Stack.margin({ right: 14 });
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 设备类型图标背景
            Column.create();
            // 设备类型图标背景
            Column.width(48);
            // 设备类型图标背景
            Column.height(48);
            // 设备类型图标背景
            Column.borderRadius(18);
            // 设备类型图标背景
            Column.linearGradient({
                angle: 135,
                colors: this.device.status === DeviceStatus.ONLINE ?
                    [['#6C5CE7', 0.0], ['#A29BFE', 1.0]] :
                    [['#CAC4D0', 0.0], ['#E6E1E5', 1.0]]
            });
            // 设备类型图标背景
            Column.opacity(this.device.status === DeviceStatus.ONLINE ? 1.0 : 0.5);
        }, Column);
        // 设备类型图标背景
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 16777229, "type": 20000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" });
            Image.width(24);
            Image.height(24);
            Image.fillColor(Color.White);
            Image.opacity(this.device.status === DeviceStatus.ONLINE ? 1.0 : 0.5);
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 在线状态圆点
            if (this.device.status === DeviceStatus.ONLINE) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width(12);
                        Column.height(12);
                        Column.borderRadius(6);
                        Column.backgroundColor(AppColors.STATUS_ONLINE);
                        Column.border({ width: 2, color: Color.White });
                        Column.position({ x: 38, y: 38 });
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
        // 左侧：设备图标 + 在线指示
        Stack.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 中间：设备信息
            Column.create();
            // 中间：设备信息
            Column.alignItems(HorizontalAlign.Start);
            // 中间：设备信息
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.device.name);
            Text.fontSize(15);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(this.device.status === DeviceStatus.ONLINE ?
                AppColors.TEXT_PRIMARY_LIGHT : AppColors.TEXT_SECONDARY_LIGHT);
            Text.maxLines(1);
            Text.textOverflow({ overflow: TextOverflow.Ellipsis });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 厂商标签（如果有的话）
            if (this.isShareDevice()) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.padding({ left: 6, right: 6, top: 2, bottom: 2 });
                        Column.borderRadius(6);
                        Column.backgroundColor('#10A29BFE');
                        Column.margin({ left: 6 });
                    }, Column);
                    Column.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('互传');
                        Text.fontSize(10);
                        Text.fontColor('#6C5CE7');
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
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.margin({ top: 4 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.getDeviceTypeLabel());
            Text.fontSize(12);
            Text.fontColor(AppColors.TEXT_SECONDARY_LIGHT);
            Text.margin({ right: 6 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const protocol = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    __Common__.create();
                    __Common__.margin({ right: 4 });
                }, __Common__);
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new ProtocolBadge(this, { protocol: protocol }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/components/DeviceCard.ets", line: 79, col: 13 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {
                                    protocol: protocol
                                };
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {
                                protocol: protocol
                            });
                        }
                    }, { name: "ProtocolBadge" });
                }
                __Common__.pop();
            };
            this.forEachUpdateFunction(elmtId, this.device.supportedProtocols, forEachItemGenFunction);
        }, ForEach);
        ForEach.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.device.signalStrength) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.getSignalLabel());
                        Text.fontSize(11);
                        Text.fontColor(AppColors.TEXT_SECONDARY_LIGHT);
                        Text.margin({ left: 4 });
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
        Row.pop();
        // 中间：设备信息
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 右侧：快捷发送
            Button.createWithChild();
            // 右侧：快捷发送
            Button.linearGradient({
                angle: 135,
                colors: [
                    ['#6C5CE7', 0.0],
                    ['#A29BFE', 1.0]
                ]
            });
            // 右侧：快捷发送
            Button.borderRadius(16);
            // 右侧：快捷发送
            Button.height(34);
            // 右侧：快捷发送
            Button.padding({ left: 14, right: 14 });
            // 右侧：快捷发送
            Button.shadow({ radius: 6, color: '#306C5CE7', offsetY: 2 });
            // 右侧：快捷发送
            Button.enabled(this.device.status === DeviceStatus.ONLINE);
            // 右侧：快捷发送
            Button.opacity(this.device.status === DeviceStatus.ONLINE ? 1.0 : 0.4);
            // 右侧：快捷发送
            Button.onClick(() => {
                AppStorage.set<Device>('selectedDevice', ObservedObject.GetRawObject(this.device));
            });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 125831535, "type": 40000, params: [], "bundleName": "com.toshare.harmonyos", "moduleName": "entry" });
            Image.width(14);
            Image.height(14);
            Image.fillColor(Color.White);
            Image.margin({ right: 4 });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('发送');
            Text.fontSize(12);
            Text.fontColor(Color.White);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        Row.pop();
        // 右侧：快捷发送
        Button.pop();
        Row.pop();
    }
    private isShareDevice(): boolean {
        return this.device.supportedProtocols.includes(TransportProtocol.WIFI_DIRECT);
    }
    private getDeviceTypeLabel(): string {
        switch (this.device.type) {
            case DeviceType.MOBILE:
                return '手机';
            case DeviceType.TABLET:
                return '平板';
            case DeviceType.DESKTOP:
                return '电脑';
            default:
                return '设备';
        }
    }
    private getSignalLabel(): string {
        const rssi = this.device.signalStrength;
        if (rssi >= -55)
            return '📶 强';
        if (rssi >= -75)
            return '📶 中';
        return '📶 弱';
    }
    rerender() {
        this.updateDirtyElements();
    }
}
