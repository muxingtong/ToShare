if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface TransferProgressRing_Params {
    progress?: number;
    status?: TransferStatus;
    ringSize?: number;
    strokeWidth?: number;
}
import { TransferStatus } from "@normalized:N&&&entry/src/main/ets/models/Enums&";
import { AppColors } from "@normalized:N&&&entry/src/main/ets/theme/AppColors&";
export class TransferProgressRing extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__progress = new SynchedPropertySimpleOneWayPU(params.progress, this, "progress");
        this.__status = new SynchedPropertySimpleOneWayPU(params.status, this, "status");
        this.__ringSize = new SynchedPropertySimpleOneWayPU(params.ringSize, this, "ringSize");
        this.__strokeWidth = new SynchedPropertySimpleOneWayPU(params.strokeWidth, this, "strokeWidth");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: TransferProgressRing_Params) {
        if (params.progress === undefined) {
            this.__progress.set(0);
        }
        if (params.status === undefined) {
            this.__status.set(TransferStatus.IDLE);
        }
        if (params.ringSize === undefined) {
            this.__ringSize.set(80);
        }
        if (params.strokeWidth === undefined) {
            this.__strokeWidth.set(6);
        }
    }
    updateStateVars(params: TransferProgressRing_Params) {
        this.__progress.reset(params.progress);
        this.__status.reset(params.status);
        this.__ringSize.reset(params.ringSize);
        this.__strokeWidth.reset(params.strokeWidth);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__progress.purgeDependencyOnElmtId(rmElmtId);
        this.__status.purgeDependencyOnElmtId(rmElmtId);
        this.__ringSize.purgeDependencyOnElmtId(rmElmtId);
        this.__strokeWidth.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__progress.aboutToBeDeleted();
        this.__status.aboutToBeDeleted();
        this.__ringSize.aboutToBeDeleted();
        this.__strokeWidth.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __progress: SynchedPropertySimpleOneWayPU<number>;
    get progress() {
        return this.__progress.get();
    }
    set progress(newValue: number) {
        this.__progress.set(newValue);
    }
    private __status: SynchedPropertySimpleOneWayPU<TransferStatus>;
    get status() {
        return this.__status.get();
    }
    set status(newValue: TransferStatus) {
        this.__status.set(newValue);
    }
    private __ringSize: SynchedPropertySimpleOneWayPU<number>;
    get ringSize() {
        return this.__ringSize.get();
    }
    set ringSize(newValue: number) {
        this.__ringSize.set(newValue);
    }
    private __strokeWidth: SynchedPropertySimpleOneWayPU<number>;
    get strokeWidth() {
        return this.__strokeWidth.get();
    }
    set strokeWidth(newValue: number) {
        this.__strokeWidth.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.width(this.ringSize);
            Stack.height(this.ringSize);
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Progress.create({
                value: this.progress * 100,
                total: 100,
                type: ProgressType.Ring
            });
            Progress.width(this.ringSize);
            Progress.height(this.ringSize);
            Progress.color(this.getProgressColor());
            Progress.style({ strokeWidth: this.strokeWidth });
        }, Progress);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${Math.round(this.progress * 100)}%`);
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.getStatusIcon() !== '') {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.getStatusIcon());
                        Text.fontSize(16);
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
        Column.pop();
        Stack.pop();
    }
    getProgressColor(): ResourceColor {
        switch (this.status) {
            case TransferStatus.COMPLETED:
                return AppColors.SUCCESS;
            case TransferStatus.FAILED:
            case TransferStatus.CANCELLED:
                return AppColors.ERROR;
            case TransferStatus.PAUSED:
                return AppColors.WARNING;
            default:
                return AppColors.PRIMARY;
        }
    }
    getStatusIcon(): string {
        switch (this.status) {
            case TransferStatus.COMPLETED:
                return '\u2713';
            case TransferStatus.FAILED:
                return '\u2717';
            case TransferStatus.PAUSED:
                return '\u23F8';
            default:
                return '';
        }
    }
    rerender() {
        this.updateDirtyElements();
    }
}
