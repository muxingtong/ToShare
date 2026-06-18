if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface HistoryCard_Params {
    history?: TransferHistory;
    isDark?: boolean;
}
import { TransferHistory } from "@normalized:N&&&entry/src/main/ets/models/TransferSession&";
import { TransferStatus } from "@normalized:N&&&entry/src/main/ets/models/Enums&";
import { FileSizeFormatter } from "@normalized:N&&&entry/src/main/ets/utils/FileSizeFormatter&";
import { AppTheme } from "@normalized:N&&&entry/src/main/ets/theme/AppTheme&";
export class HistoryCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__history = new SynchedPropertyObjectOneWayPU(params.history, this, "history");
        this.__isDark = new SynchedPropertySimpleOneWayPU(params.isDark, this, "isDark");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: HistoryCard_Params) {
        if (params.history === undefined) {
            this.__history.set(new TransferHistory('', '', true, 0, 0, 0, TransferStatus.COMPLETED, []));
        }
        if (params.isDark === undefined) {
            this.__isDark.set(false);
        }
    }
    updateStateVars(params: HistoryCard_Params) {
        this.__history.reset(params.history);
        this.__isDark.reset(params.isDark);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__history.purgeDependencyOnElmtId(rmElmtId);
        this.__isDark.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__history.aboutToBeDeleted();
        this.__isDark.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __history: SynchedPropertySimpleOneWayPU<TransferHistory>;
    get history() {
        return this.__history.get();
    }
    set history(newValue: TransferHistory) {
        this.__history.set(newValue);
    }
    private __isDark: SynchedPropertySimpleOneWayPU<boolean>;
    get isDark() {
        return this.__isDark.get();
    }
    set isDark(newValue: boolean) {
        this.__isDark.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.padding(16);
            Row.borderRadius(18);
            Row.backgroundColor('#F2FFFFFF');
            Row.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
            Row.shadow({ radius: 4, color: '#0A000000', offsetY: 1 });
            Row.margin({ bottom: 8 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width(40);
            Column.height(40);
            Column.borderRadius(20);
            Column.backgroundColor(this.history.isSender ? '#126C5CE7' : '#1200C9A7');
            Column.justifyContent(FlexAlign.Center);
            Column.margin({ right: 12 });
        }, Column);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.history.peerDeviceName);
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(AppTheme.getTextPrimary(this.isDark));
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${this.history.fileCount}个文件 · ${FileSizeFormatter.formatSize(this.history.totalSize)}`);
            Text.fontSize(13);
            Text.fontColor(AppTheme.getTextSecondary(this.isDark));
            Text.margin({ top: 2 });
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.getStatusText());
            Text.fontSize(13);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(this.getStatusColor());
            Text.padding({ left: 10, right: 10, top: 4, bottom: 4 });
            Text.borderRadius(10);
            Text.backgroundColor(this.getStatusBg());
        }, Text);
        Text.pop();
        Row.pop();
    }
    getStatusText(): string {
        switch (this.history.status) {
            case TransferStatus.COMPLETED:
                return '已完成';
            case TransferStatus.FAILED:
                return '失败';
            case TransferStatus.CANCELLED:
                return '已取消';
            default:
                return '';
        }
    }
    getStatusColor(): ResourceColor {
        switch (this.history.status) {
            case TransferStatus.COMPLETED:
                return '#00A383';
            case TransferStatus.FAILED:
                return '#FF6B6B';
            case TransferStatus.CANCELLED:
                return '#FF9F43';
            default:
                return '#9E9E9E';
        }
    }
    getStatusBg(): ResourceColor {
        switch (this.history.status) {
            case TransferStatus.COMPLETED:
                return '#1000C9A7';
            case TransferStatus.FAILED:
                return '#10FF6B6B';
            case TransferStatus.CANCELLED:
                return '#10FF9F43';
            default:
                return '#109E9E9E';
        }
    }
    rerender() {
        this.updateDirtyElements();
    }
}
