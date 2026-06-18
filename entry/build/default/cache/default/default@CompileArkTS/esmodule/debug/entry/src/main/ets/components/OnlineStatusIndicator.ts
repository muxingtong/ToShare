if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface OnlineStatusIndicator_Params {
    status?: DeviceStatus;
    indicatorSize?: number;
}
import { DeviceStatus } from "@normalized:N&&&entry/src/main/ets/models/Enums&";
export class OnlineStatusIndicator extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__status = new SynchedPropertySimpleOneWayPU(params.status, this, "status");
        this.__indicatorSize = new SynchedPropertySimpleOneWayPU(params.indicatorSize, this, "indicatorSize");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: OnlineStatusIndicator_Params) {
        if (params.status === undefined) {
            this.__status.set(DeviceStatus.ONLINE);
        }
        if (params.indicatorSize === undefined) {
            this.__indicatorSize.set(10);
        }
    }
    updateStateVars(params: OnlineStatusIndicator_Params) {
        this.__status.reset(params.status);
        this.__indicatorSize.reset(params.indicatorSize);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__status.purgeDependencyOnElmtId(rmElmtId);
        this.__indicatorSize.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__status.aboutToBeDeleted();
        this.__indicatorSize.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __status: SynchedPropertySimpleOneWayPU<DeviceStatus>;
    get status() {
        return this.__status.get();
    }
    set status(newValue: DeviceStatus) {
        this.__status.set(newValue);
    }
    private __indicatorSize: SynchedPropertySimpleOneWayPU<number>;
    get indicatorSize() {
        return this.__indicatorSize.get();
    }
    set indicatorSize(newValue: number) {
        this.__indicatorSize.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Circle.create({ width: this.indicatorSize, height: this.indicatorSize });
            Circle.fill(this.getStatusColor());
            Circle.margin({ right: 6 });
        }, Circle);
    }
    getStatusColor(): ResourceColor {
        switch (this.status) {
            case DeviceStatus.ONLINE:
                return Color.Green;
            case DeviceStatus.AWAY:
                return Color.Orange;
            case DeviceStatus.OFFLINE:
                return Color.Gray;
            default:
                return Color.Gray;
        }
    }
    rerender() {
        this.updateDirtyElements();
    }
}
