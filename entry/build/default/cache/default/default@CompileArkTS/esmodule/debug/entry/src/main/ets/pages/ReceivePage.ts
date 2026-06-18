if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ReceivePage_Params {
    isReceiving?: boolean;
    transferStatus?: TransferStatus;
    progress?: number;
    speed?: number;
    eta?: number;
    fileName?: string;
    fileSize?: number;
    isDark?: boolean;
    accentGradient?: AccentGradient;
}
import { TransferStatus } from "@normalized:N&&&entry/src/main/ets/models/Enums&";
import { TransferHistory } from "@normalized:N&&&entry/src/main/ets/models/TransferSession&";
import { TransferProgressRing } from "@normalized:N&&&entry/src/main/ets/components/TransferProgressRing&";
import { FileSizeFormatter } from "@normalized:N&&&entry/src/main/ets/utils/FileSizeFormatter&";
import { RelativeTime } from "@normalized:N&&&entry/src/main/ets/utils/RelativeTime&";
import { HistoryRepository } from "@normalized:N&&&entry/src/main/ets/services/HistoryRepository&";
import { AccentGradient } from "@normalized:N&&&entry/src/main/ets/theme/AppTheme&";
export class ReceivePage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__isReceiving = new ObservedPropertySimplePU(false, this, "isReceiving");
        this.__transferStatus = new ObservedPropertySimplePU(TransferStatus.IDLE, this, "transferStatus");
        this.__progress = new ObservedPropertySimplePU(0, this, "progress");
        this.__speed = new ObservedPropertySimplePU(0, this, "speed");
        this.__eta = new ObservedPropertySimplePU(-1, this, "eta");
        this.__fileName = new ObservedPropertySimplePU('', this, "fileName");
        this.__fileSize = new ObservedPropertySimplePU(0, this, "fileSize");
        this.__isDark = new ObservedPropertySimplePU(false, this, "isDark");
        this.accentGradient = new AccentGradient();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ReceivePage_Params) {
        if (params.isReceiving !== undefined) {
            this.isReceiving = params.isReceiving;
        }
        if (params.transferStatus !== undefined) {
            this.transferStatus = params.transferStatus;
        }
        if (params.progress !== undefined) {
            this.progress = params.progress;
        }
        if (params.speed !== undefined) {
            this.speed = params.speed;
        }
        if (params.eta !== undefined) {
            this.eta = params.eta;
        }
        if (params.fileName !== undefined) {
            this.fileName = params.fileName;
        }
        if (params.fileSize !== undefined) {
            this.fileSize = params.fileSize;
        }
        if (params.isDark !== undefined) {
            this.isDark = params.isDark;
        }
        if (params.accentGradient !== undefined) {
            this.accentGradient = params.accentGradient;
        }
    }
    updateStateVars(params: ReceivePage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__isReceiving.purgeDependencyOnElmtId(rmElmtId);
        this.__transferStatus.purgeDependencyOnElmtId(rmElmtId);
        this.__progress.purgeDependencyOnElmtId(rmElmtId);
        this.__speed.purgeDependencyOnElmtId(rmElmtId);
        this.__eta.purgeDependencyOnElmtId(rmElmtId);
        this.__fileName.purgeDependencyOnElmtId(rmElmtId);
        this.__fileSize.purgeDependencyOnElmtId(rmElmtId);
        this.__isDark.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__isReceiving.aboutToBeDeleted();
        this.__transferStatus.aboutToBeDeleted();
        this.__progress.aboutToBeDeleted();
        this.__speed.aboutToBeDeleted();
        this.__eta.aboutToBeDeleted();
        this.__fileName.aboutToBeDeleted();
        this.__fileSize.aboutToBeDeleted();
        this.__isDark.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __isReceiving: ObservedPropertySimplePU<boolean>;
    get isReceiving() {
        return this.__isReceiving.get();
    }
    set isReceiving(newValue: boolean) {
        this.__isReceiving.set(newValue);
    }
    private __transferStatus: ObservedPropertySimplePU<TransferStatus>;
    get transferStatus() {
        return this.__transferStatus.get();
    }
    set transferStatus(newValue: TransferStatus) {
        this.__transferStatus.set(newValue);
    }
    private __progress: ObservedPropertySimplePU<number>;
    get progress() {
        return this.__progress.get();
    }
    set progress(newValue: number) {
        this.__progress.set(newValue);
    }
    private __speed: ObservedPropertySimplePU<number>;
    get speed() {
        return this.__speed.get();
    }
    set speed(newValue: number) {
        this.__speed.set(newValue);
    }
    private __eta: ObservedPropertySimplePU<number>;
    get eta() {
        return this.__eta.get();
    }
    set eta(newValue: number) {
        this.__eta.set(newValue);
    }
    private __fileName: ObservedPropertySimplePU<string>;
    get fileName() {
        return this.__fileName.get();
    }
    set fileName(newValue: string) {
        this.__fileName.set(newValue);
    }
    private __fileSize: ObservedPropertySimplePU<number>;
    get fileSize() {
        return this.__fileSize.get();
    }
    set fileSize(newValue: number) {
        this.__fileSize.set(newValue);
    }
    private __isDark: ObservedPropertySimplePU<boolean>;
    get isDark() {
        return this.__isDark.get();
    }
    set isDark(newValue: boolean) {
        this.__isDark.set(newValue);
    }
    private accentGradient: AccentGradient;
    simulateReceive(): void {
        this.isReceiving = true;
        this.transferStatus = TransferStatus.TRANSFERRING;
        this.fileName = 'document.pdf';
        this.fileSize = 15 * 1024 * 1024;
        let simulatedProgress = 0;
        const interval = setInterval(() => {
            simulatedProgress += 0.05;
            this.progress = Math.min(simulatedProgress, 1.0);
            this.speed = 2 * 1024 * 1024 + Math.random() * 1024 * 1024;
            if (simulatedProgress >= 1.0) {
                clearInterval(interval);
                this.transferStatus = TransferStatus.COMPLETED;
                this.progress = 1.0;
                this.saveReceiveHistory(TransferStatus.COMPLETED);
            }
        }, 300);
    }
    pauseTransfer(): void {
        this.transferStatus = TransferStatus.PAUSED;
    }
    resumeTransfer(): void {
        this.transferStatus = TransferStatus.TRANSFERRING;
    }
    cancelTransfer(): void {
        this.transferStatus = TransferStatus.CANCELLED;
        this.isReceiving = false;
        this.progress = 0;
        this.saveReceiveHistory(TransferStatus.CANCELLED);
    }
    private saveReceiveHistory(status: TransferStatus): void {
        if (!this.fileName) {
            return;
        }
        const entry = new TransferHistory(`${Date.now()}_${Math.random().toString(36).slice(2, 8)}`, '附近设备', false, 1, this.fileSize, Date.now(), status, [this.fileName]);
        HistoryRepository.getInstance().addHistory(entry);
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
                angle: this.accentGradient.angle,
                colors: this.accentGradient.colors
            });
        }, Column);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.padding({ left: 20, right: 20, top: 4, bottom: 4 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('接收文件');
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
            If.create();
            if (!this.isReceiving) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                        Column.height('100%');
                        Column.justifyContent(FlexAlign.Center);
                        Column.alignItems(HorizontalAlign.Center);
                        Column.padding(32);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width(100);
                        Column.height(100);
                        Column.borderRadius(50);
                        Column.backgroundColor('#1200C9A7');
                        Column.justifyContent(FlexAlign.Center);
                        Column.margin({ bottom: 20 });
                    }, Column);
                    Column.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('等待接收文件');
                        Text.fontSize(20);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor('#1C1B1F');
                        Text.margin({ bottom: 8 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('确保双方设备已连接\n即可接收来自附近设备的文件');
                        Text.fontSize(14);
                        Text.fontColor('#625B71');
                        Text.textAlign(TextAlign.Center);
                        Text.margin({ bottom: 24 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('模拟接收');
                        Button.fontSize(14);
                        Button.fontColor(Color.White);
                        Button.linearGradient({
                            angle: this.accentGradient.angle,
                            colors: this.accentGradient.colors
                        });
                        Button.borderRadius(20);
                        Button.height(42);
                        Button.padding({ left: 28, right: 28 });
                        Button.shadow({ radius: 8, color: '#3000C9A7', offsetY: 3 });
                        Button.onClick(() => { this.simulateReceive(); });
                    }, Button);
                    Button.pop();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Scroll.create();
                        Scroll.width('100%');
                        Scroll.layoutWeight(1);
                        Scroll.scrollBar(BarState.Off);
                        Scroll.edgeEffect(EdgeEffect.Spring);
                    }, Scroll);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                        Column.alignItems(HorizontalAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        __Common__.create();
                        __Common__.margin({ top: 48, bottom: 24 });
                    }, __Common__);
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new TransferProgressRing(this, {
                                    progress: this.progress,
                                    status: this.transferStatus,
                                    ringSize: 120,
                                    strokeWidth: 8
                                }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/ReceivePage.ets", line: 141, col: 13 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        progress: this.progress,
                                        status: this.transferStatus,
                                        ringSize: 120,
                                        strokeWidth: 8
                                    };
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {
                                    progress: this.progress,
                                    status: this.transferStatus,
                                    ringSize: 120,
                                    strokeWidth: 8
                                });
                            }
                        }, { name: "TransferProgressRing" });
                    }
                    __Common__.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.fileName);
                        Text.fontSize(18);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor('#1C1B1F');
                        Text.margin({ bottom: 4 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(FileSizeFormatter.formatSize(this.fileSize));
                        Text.fontSize(14);
                        Text.fontColor('#625B71');
                        Text.margin({ bottom: 16 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.transferStatus === TransferStatus.TRANSFERRING) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Row.create();
                                    Row.margin({ bottom: 4 });
                                }, Row);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Column.create();
                                    Column.width(6);
                                    Column.height(6);
                                    Column.borderRadius(3);
                                    Column.backgroundColor('#00C9A7');
                                    Column.margin({ right: 6 });
                                }, Column);
                                Column.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(`${FileSizeFormatter.formatSpeed(this.speed)}`);
                                    Text.fontSize(14);
                                    Text.fontColor('#625B71');
                                }, Text);
                                Text.pop();
                                Row.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(`剩余 ${RelativeTime.formatETA(this.eta)}`);
                                    Text.fontSize(13);
                                    Text.fontColor('#9E9E9E');
                                    Text.margin({ bottom: 24 });
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
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 12 });
                        Row.margin({ top: 24 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.transferStatus === TransferStatus.TRANSFERRING ||
                            this.transferStatus === TransferStatus.PREPARING) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Button.createWithLabel('暂停');
                                    Button.fontSize(14);
                                    Button.fontColor('#6C5CE7');
                                    Button.backgroundColor('#126C5CE7');
                                    Button.borderRadius(20);
                                    Button.height(40);
                                    Button.padding({ left: 24, right: 24 });
                                    Button.onClick(() => { this.pauseTransfer(); });
                                }, Button);
                                Button.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.transferStatus === TransferStatus.PAUSED) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Button.createWithLabel('继续');
                                    Button.fontSize(14);
                                    Button.fontColor('#00C9A7');
                                    Button.backgroundColor('#1200C9A7');
                                    Button.borderRadius(20);
                                    Button.height(40);
                                    Button.padding({ left: 24, right: 24 });
                                    Button.onClick(() => { this.resumeTransfer(); });
                                }, Button);
                                Button.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('取消');
                        Button.fontSize(14);
                        Button.fontColor('#FF6B6B');
                        Button.backgroundColor('#12FF6B6B');
                        Button.borderRadius(20);
                        Button.height(40);
                        Button.padding({ left: 24, right: 24 });
                        Button.onClick(() => { this.cancelTransfer(); });
                    }, Button);
                    Button.pop();
                    Row.pop();
                    Column.pop();
                    Scroll.pop();
                });
            }
        }, If);
        If.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
