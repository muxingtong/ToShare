if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface HistoryPage_Params {
    transferHistory?: TransferHistory[];
    todayStats?: TodayStats;
    isDark?: boolean;
    headerGradient?: HeaderGradient;
    historyRepo?: HistoryRepository;
}
import type { TransferHistory } from '../models/TransferSession';
import { TransferStatus } from "@normalized:N&&&entry/src/main/ets/models/Enums&";
import { HistoryCard } from "@normalized:N&&&entry/src/main/ets/components/HistoryCard&";
import { EmptyState } from "@normalized:N&&&entry/src/main/ets/components/EmptyState&";
import { FileSizeFormatter } from "@normalized:N&&&entry/src/main/ets/utils/FileSizeFormatter&";
import { HistoryRepository } from "@normalized:N&&&entry/src/main/ets/services/HistoryRepository&";
import { HeaderGradient } from "@normalized:N&&&entry/src/main/ets/theme/AppTheme&";
class TodayStats {
    sent: number;
    received: number;
    total: number;
    constructor(sent: number = 0, received: number = 0, total: number = 0) {
        this.sent = sent;
        this.received = received;
        this.total = total;
    }
}
export class HistoryPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__transferHistory = new ObservedPropertyObjectPU([], this, "transferHistory");
        this.__todayStats = new ObservedPropertyObjectPU(new TodayStats(), this, "todayStats");
        this.__isDark = new ObservedPropertySimplePU(false, this, "isDark");
        this.headerGradient = new HeaderGradient();
        this.historyRepo = HistoryRepository.getInstance();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: HistoryPage_Params) {
        if (params.transferHistory !== undefined) {
            this.transferHistory = params.transferHistory;
        }
        if (params.todayStats !== undefined) {
            this.todayStats = params.todayStats;
        }
        if (params.isDark !== undefined) {
            this.isDark = params.isDark;
        }
        if (params.headerGradient !== undefined) {
            this.headerGradient = params.headerGradient;
        }
        if (params.historyRepo !== undefined) {
            this.historyRepo = params.historyRepo;
        }
    }
    updateStateVars(params: HistoryPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__transferHistory.purgeDependencyOnElmtId(rmElmtId);
        this.__todayStats.purgeDependencyOnElmtId(rmElmtId);
        this.__isDark.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__transferHistory.aboutToBeDeleted();
        this.__todayStats.aboutToBeDeleted();
        this.__isDark.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __transferHistory: ObservedPropertyObjectPU<TransferHistory[]>;
    get transferHistory() {
        return this.__transferHistory.get();
    }
    set transferHistory(newValue: TransferHistory[]) {
        this.__transferHistory.set(newValue);
    }
    private __todayStats: ObservedPropertyObjectPU<TodayStats>;
    get todayStats() {
        return this.__todayStats.get();
    }
    set todayStats(newValue: TodayStats) {
        this.__todayStats.set(newValue);
    }
    private __isDark: ObservedPropertySimplePU<boolean>;
    get isDark() {
        return this.__isDark.get();
    }
    set isDark(newValue: boolean) {
        this.__isDark.set(newValue);
    }
    private headerGradient: HeaderGradient;
    private historyRepo: HistoryRepository;
    aboutToAppear(): void {
        this.loadHistory();
    }
    onPageShow(): void {
        this.loadHistory();
    }
    async loadHistory(): Promise<void> {
        const list = await this.historyRepo.getAllHistory();
        this.transferHistory = list;
        this.computeTodayStats();
    }
    computeTodayStats(): void {
        const today = new Date().toDateString();
        const todayHistory = this.transferHistory.filter(h => {
            return new Date(h.timestamp).toDateString() === today;
        });
        const stats = new TodayStats();
        stats.sent = todayHistory.filter(h => h.isSender).length;
        stats.received = todayHistory.filter(h => !h.isSender).length;
        stats.total = todayHistory.length;
        this.todayStats = stats;
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
            Text.create('传输历史');
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
            // 统计面板
            Row.create();
            // 统计面板
            Row.padding({ top: 16, bottom: 16 });
            // 统计面板
            Row.margin({ left: 20, right: 20, top: 12 });
            // 统计面板
            Row.borderRadius(18);
            // 统计面板
            Row.backgroundColor('#F2FFFFFF');
            // 统计面板
            Row.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
            // 统计面板
            Row.shadow({ radius: 6, color: '#0C000000', offsetY: 1 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.layoutWeight(1);
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${this.todayStats.sent}`);
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor('#6C5CE7');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('今日发送');
            Text.fontSize(11);
            Text.fontColor('#625B71');
            Text.margin({ top: 2 });
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.layoutWeight(1);
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${this.todayStats.received}`);
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor('#00C9A7');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('今日接收');
            Text.fontSize(11);
            Text.fontColor('#625B71');
            Text.margin({ top: 2 });
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.layoutWeight(1);
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${this.todayStats.total}`);
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor('#FF9F43');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('今日总计');
            Text.fontSize(11);
            Text.fontColor('#625B71');
            Text.margin({ top: 2 });
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.layoutWeight(1);
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(FileSizeFormatter.formatSize(this.totalSentSize));
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor('#1C1B1F');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('累计传输');
            Text.fontSize(11);
            Text.fontColor('#625B71');
            Text.margin({ top: 2 });
        }, Text);
        Text.pop();
        Column.pop();
        // 统计面板
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.transferHistory.length === 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new EmptyState(this, {
                                    icon: '📋',
                                    title: '暂无传输记录',
                                    subtitle: '发送或接收文件后，记录将显示在这里'
                                }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/HistoryPage.ets", line: 148, col: 9 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        icon: '📋',
                                        title: '暂无传输记录',
                                        subtitle: '发送或接收文件后，记录将显示在这里'
                                    };
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {
                                    icon: '📋',
                                    title: '暂无传输记录',
                                    subtitle: '发送或接收文件后，记录将显示在这里'
                                });
                            }
                        }, { name: "EmptyState" });
                    }
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        List.create();
                        List.width('100%');
                        List.layoutWeight(1);
                        List.padding({ left: 16, right: 16, top: 8 });
                    }, List);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const item = _item;
                            {
                                const itemCreation = (elmtId, isInitialRender) => {
                                    ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                                    ListItem.create(deepRenderFunction, true);
                                    if (!isInitialRender) {
                                        ListItem.pop();
                                    }
                                    ViewStackProcessor.StopGetAccessRecording();
                                };
                                const itemCreation2 = (elmtId, isInitialRender) => {
                                    ListItem.create(deepRenderFunction, true);
                                };
                                const deepRenderFunction = (elmtId, isInitialRender) => {
                                    itemCreation(elmtId, isInitialRender);
                                    {
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            if (isInitialRender) {
                                                let componentCall = new HistoryCard(this, { history: item }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/HistoryPage.ets", line: 157, col: 15 });
                                                ViewPU.create(componentCall);
                                                let paramsLambda = () => {
                                                    return {
                                                        history: item
                                                    };
                                                };
                                                componentCall.paramsGenerator_ = paramsLambda;
                                            }
                                            else {
                                                this.updateStateVarsOfChildByElmtId(elmtId, {
                                                    history: item
                                                });
                                            }
                                        }, { name: "HistoryCard" });
                                    }
                                    ListItem.pop();
                                };
                                this.observeComponentCreation2(itemCreation2, ListItem);
                                ListItem.pop();
                            }
                        };
                        this.forEachUpdateFunction(elmtId, this.transferHistory, forEachItemGenFunction, (item: TransferHistory) => item.id, false, false);
                    }, ForEach);
                    ForEach.pop();
                    List.pop();
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height(80);
        }, Column);
        Column.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
