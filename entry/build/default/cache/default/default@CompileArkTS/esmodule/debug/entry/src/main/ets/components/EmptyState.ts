if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface EmptyState_Params {
    icon?: string;
    title?: string;
    subtitle?: string;
    showAction?: boolean;
    actionText?: string;
    isDark?: boolean;
}
import { AppTheme } from "@normalized:N&&&entry/src/main/ets/theme/AppTheme&";
export class EmptyState extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__icon = new SynchedPropertySimpleOneWayPU(params.icon, this, "icon");
        this.__title = new SynchedPropertySimpleOneWayPU(params.title, this, "title");
        this.__subtitle = new SynchedPropertySimpleOneWayPU(params.subtitle, this, "subtitle");
        this.__showAction = new SynchedPropertySimpleOneWayPU(params.showAction, this, "showAction");
        this.__actionText = new SynchedPropertySimpleOneWayPU(params.actionText, this, "actionText");
        this.__isDark = new SynchedPropertySimpleOneWayPU(params.isDark, this, "isDark");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: EmptyState_Params) {
        if (params.icon === undefined) {
            this.__icon.set('\uD83D\uDCC1');
        }
        if (params.title === undefined) {
            this.__title.set('暂无数据');
        }
        if (params.subtitle === undefined) {
            this.__subtitle.set('');
        }
        if (params.showAction === undefined) {
            this.__showAction.set(false);
        }
        if (params.actionText === undefined) {
            this.__actionText.set('');
        }
        if (params.isDark === undefined) {
            this.__isDark.set(false);
        }
    }
    updateStateVars(params: EmptyState_Params) {
        this.__icon.reset(params.icon);
        this.__title.reset(params.title);
        this.__subtitle.reset(params.subtitle);
        this.__showAction.reset(params.showAction);
        this.__actionText.reset(params.actionText);
        this.__isDark.reset(params.isDark);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__icon.purgeDependencyOnElmtId(rmElmtId);
        this.__title.purgeDependencyOnElmtId(rmElmtId);
        this.__subtitle.purgeDependencyOnElmtId(rmElmtId);
        this.__showAction.purgeDependencyOnElmtId(rmElmtId);
        this.__actionText.purgeDependencyOnElmtId(rmElmtId);
        this.__isDark.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__icon.aboutToBeDeleted();
        this.__title.aboutToBeDeleted();
        this.__subtitle.aboutToBeDeleted();
        this.__showAction.aboutToBeDeleted();
        this.__actionText.aboutToBeDeleted();
        this.__isDark.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __icon: SynchedPropertySimpleOneWayPU<string>;
    get icon() {
        return this.__icon.get();
    }
    set icon(newValue: string) {
        this.__icon.set(newValue);
    }
    private __title: SynchedPropertySimpleOneWayPU<string>;
    get title() {
        return this.__title.get();
    }
    set title(newValue: string) {
        this.__title.set(newValue);
    }
    private __subtitle: SynchedPropertySimpleOneWayPU<string>;
    get subtitle() {
        return this.__subtitle.get();
    }
    set subtitle(newValue: string) {
        this.__subtitle.set(newValue);
    }
    private __showAction: SynchedPropertySimpleOneWayPU<boolean>;
    get showAction() {
        return this.__showAction.get();
    }
    set showAction(newValue: boolean) {
        this.__showAction.set(newValue);
    }
    private __actionText: SynchedPropertySimpleOneWayPU<string>;
    get actionText() {
        return this.__actionText.get();
    }
    set actionText(newValue: string) {
        this.__actionText.set(newValue);
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
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.justifyContent(FlexAlign.Center);
            Column.alignItems(HorizontalAlign.Center);
            Column.padding(32);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.icon);
            Text.fontSize(64);
            Text.margin({ bottom: 16 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.title);
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(AppTheme.getTextPrimary(this.isDark));
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.subtitle !== '') {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.subtitle);
                        Text.fontSize(14);
                        Text.fontColor(AppTheme.getTextSecondary(this.isDark));
                        Text.textAlign(TextAlign.Center);
                        Text.margin({ bottom: 16 });
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
            If.create();
            if (this.showAction && this.actionText !== '') {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel(this.actionText);
                        Button.fontSize(14);
                        Button.fontColor(Color.White);
                        Button.backgroundColor('#3F51B5');
                        Button.borderRadius(20);
                        Button.height(40);
                        Button.padding({ left: 24, right: 24 });
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
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
