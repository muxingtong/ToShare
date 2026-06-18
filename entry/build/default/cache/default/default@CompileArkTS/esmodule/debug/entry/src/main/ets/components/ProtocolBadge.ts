if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ProtocolBadge_Params {
    protocol?: TransportProtocol;
}
import { TransportProtocol } from "@normalized:N&&&entry/src/main/ets/models/Enums&";
import { AppColors } from "@normalized:N&&&entry/src/main/ets/theme/AppColors&";
export class ProtocolBadge extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__protocol = new SynchedPropertySimpleOneWayPU(params.protocol, this, "protocol");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ProtocolBadge_Params) {
        if (params.protocol === undefined) {
            this.__protocol.set(TransportProtocol.WIFI_DIRECT);
        }
    }
    updateStateVars(params: ProtocolBadge_Params) {
        this.__protocol.reset(params.protocol);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__protocol.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__protocol.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __protocol: SynchedPropertySimpleOneWayPU<TransportProtocol>;
    get protocol() {
        return this.__protocol.get();
    }
    set protocol(newValue: TransportProtocol) {
        this.__protocol.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.padding({ left: 8, right: 8, top: 3, bottom: 3 });
            Row.borderRadius(12);
            Row.backgroundColor(this.getColor());
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.getLabel());
            Text.fontSize(12);
            Text.fontColor(Color.White);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        Row.pop();
    }
    getLabel(): string {
        switch (this.protocol) {
            case TransportProtocol.WIFI_DIRECT:
                return 'WiFi';
            case TransportProtocol.BLUETOOTH:
                return 'BLE';
            case TransportProtocol.NFC:
                return 'NFC';
            default:
                return '';
        }
    }
    getColor(): ResourceColor {
        switch (this.protocol) {
            case TransportProtocol.WIFI_DIRECT:
                return AppColors.WIFI_COLOR;
            case TransportProtocol.BLUETOOTH:
                return AppColors.BLE_COLOR;
            case TransportProtocol.NFC:
                return AppColors.NFC_COLOR;
            default:
                return Color.Gray;
        }
    }
    rerender() {
        this.updateDirtyElements();
    }
}
