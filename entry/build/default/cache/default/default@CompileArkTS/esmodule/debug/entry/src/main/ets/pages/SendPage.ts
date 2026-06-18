if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SendPage_Params {
    selectedFiles?: SelectableFile[];
    selectedDevice?: Device | null;
    isTransferring?: boolean;
    transferProgress?: number;
    transferMessage?: string;
    isDark?: boolean;
    filePicker?: FilePickerService;
    transferService?: FileTransferService;
    transport?: TransportService;
    headerGradient?: HeaderGradient;
    brandGradient?: BrandGradient;
}
import type { SelectableFile } from '../models/FileTransfer';
import { TransferHistory } from "@normalized:N&&&entry/src/main/ets/models/TransferSession&";
import { TransferStatus } from "@normalized:N&&&entry/src/main/ets/models/Enums&";
import type { Device } from '../models/Device';
import { FilePickerService } from "@normalized:N&&&entry/src/main/ets/services/FilePickerService&";
import { FileTransferService, TransferState, TransferStatusCallback } from "@normalized:N&&&entry/src/main/ets/services/FileTransferService&";
import { TransportService } from "@normalized:N&&&entry/src/main/ets/services/TransportService&";
import { HistoryRepository } from "@normalized:N&&&entry/src/main/ets/services/HistoryRepository&";
import { FileSizeFormatter } from "@normalized:N&&&entry/src/main/ets/utils/FileSizeFormatter&";
import { AppTheme, BrandGradient, HeaderGradient } from "@normalized:N&&&entry/src/main/ets/theme/AppTheme&";
import hilog from "@ohos:hilog";
export class SendPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__selectedFiles = new ObservedPropertyObjectPU([], this, "selectedFiles");
        this.__selectedDevice = new ObservedPropertyObjectPU(null, this, "selectedDevice");
        this.__isTransferring = new ObservedPropertySimplePU(false, this, "isTransferring");
        this.__transferProgress = new ObservedPropertySimplePU(0, this, "transferProgress");
        this.__transferMessage = new ObservedPropertySimplePU('', this, "transferMessage");
        this.__isDark = new ObservedPropertySimplePU(false, this, "isDark");
        this.filePicker = FilePickerService.getInstance();
        this.transferService = FileTransferService.getInstance();
        this.transport = TransportService.getInstance();
        this.headerGradient = new HeaderGradient();
        this.brandGradient = new BrandGradient();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SendPage_Params) {
        if (params.selectedFiles !== undefined) {
            this.selectedFiles = params.selectedFiles;
        }
        if (params.selectedDevice !== undefined) {
            this.selectedDevice = params.selectedDevice;
        }
        if (params.isTransferring !== undefined) {
            this.isTransferring = params.isTransferring;
        }
        if (params.transferProgress !== undefined) {
            this.transferProgress = params.transferProgress;
        }
        if (params.transferMessage !== undefined) {
            this.transferMessage = params.transferMessage;
        }
        if (params.isDark !== undefined) {
            this.isDark = params.isDark;
        }
        if (params.filePicker !== undefined) {
            this.filePicker = params.filePicker;
        }
        if (params.transferService !== undefined) {
            this.transferService = params.transferService;
        }
        if (params.transport !== undefined) {
            this.transport = params.transport;
        }
        if (params.headerGradient !== undefined) {
            this.headerGradient = params.headerGradient;
        }
        if (params.brandGradient !== undefined) {
            this.brandGradient = params.brandGradient;
        }
    }
    updateStateVars(params: SendPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__selectedFiles.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedDevice.purgeDependencyOnElmtId(rmElmtId);
        this.__isTransferring.purgeDependencyOnElmtId(rmElmtId);
        this.__transferProgress.purgeDependencyOnElmtId(rmElmtId);
        this.__transferMessage.purgeDependencyOnElmtId(rmElmtId);
        this.__isDark.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__selectedFiles.aboutToBeDeleted();
        this.__selectedDevice.aboutToBeDeleted();
        this.__isTransferring.aboutToBeDeleted();
        this.__transferProgress.aboutToBeDeleted();
        this.__transferMessage.aboutToBeDeleted();
        this.__isDark.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __selectedFiles: ObservedPropertyObjectPU<SelectableFile[]>;
    get selectedFiles() {
        return this.__selectedFiles.get();
    }
    set selectedFiles(newValue: SelectableFile[]) {
        this.__selectedFiles.set(newValue);
    }
    private __selectedDevice: ObservedPropertyObjectPU<Device | null>;
    get selectedDevice() {
        return this.__selectedDevice.get();
    }
    set selectedDevice(newValue: Device | null) {
        this.__selectedDevice.set(newValue);
    }
    private __isTransferring: ObservedPropertySimplePU<boolean>;
    get isTransferring() {
        return this.__isTransferring.get();
    }
    set isTransferring(newValue: boolean) {
        this.__isTransferring.set(newValue);
    }
    private __transferProgress: ObservedPropertySimplePU<number>;
    get transferProgress() {
        return this.__transferProgress.get();
    }
    set transferProgress(newValue: number) {
        this.__transferProgress.set(newValue);
    }
    private __transferMessage: ObservedPropertySimplePU<string>;
    get transferMessage() {
        return this.__transferMessage.get();
    }
    set transferMessage(newValue: string) {
        this.__transferMessage.set(newValue);
    }
    private __isDark: ObservedPropertySimplePU<boolean>;
    get isDark() {
        return this.__isDark.get();
    }
    set isDark(newValue: boolean) {
        this.__isDark.set(newValue);
    }
    private filePicker: FilePickerService;
    private transferService: FileTransferService;
    private transport: TransportService;
    private headerGradient: HeaderGradient;
    private brandGradient: BrandGradient;
    aboutToAppear(): void {
        try {
            const dev = AppStorage.get<Device>('selectedDevice');
            if (dev) {
                this.selectedDevice = dev;
            }
        }
        catch (err) {
            hilog.info(0x0001, 'ToShare', 'No selected device');
        }
    }
    async pickFiles(): Promise<void> {
        const files = await this.filePicker.pickFiles();
        this.selectedFiles = files;
    }
    async startTransfer(): Promise<void> {
        if (this.selectedFiles.length === 0 || !this.selectedDevice) {
            return;
        }
        AppStorage.setOrCreate('selectedDevice', this.selectedDevice);
        this.isTransferring = true;
        this.transferProgress = 0;
        this.transferMessage = '';
        for (let i = 0; i < this.selectedFiles.length; i++) {
            const file = this.selectedFiles[i];
            this.transferMessage = `准备发送: ${file.name}`;
            try {
                await this.transferService.startAsSender(file.path, file.name);
                const result = await this.waitForTransferComplete();
                if (result) {
                    this.transferProgress = (i + 1) / this.selectedFiles.length;
                }
                else {
                    hilog.error(0x0001, 'ToShare', 'Transfer failed for: %{public}s', file.name);
                    break;
                }
            }
            catch (err) {
                hilog.error(0x0001, 'ToShare', 'Transfer error: %{public}s', JSON.stringify(err));
                break;
            }
        }
        this.isTransferring = false;
        if (this.transferProgress >= 1.0) {
            this.transferMessage = '全部发送完成!';
            this.saveSendHistory(TransferStatus.COMPLETED);
        }
        else if (this.transferProgress > 0) {
            this.transferMessage = '部分发送完成';
            this.saveSendHistory(TransferStatus.COMPLETED);
        }
        else {
            this.transferMessage = '发送失败';
            this.saveSendHistory(TransferStatus.FAILED);
        }
    }
    private saveSendHistory(status: TransferStatus): void {
        const deviceName = this.selectedDevice?.name || '未知设备';
        const fileNames = this.selectedFiles.map(f => f.name);
        const entry = new TransferHistory(`${Date.now()}_${Math.random().toString(36).slice(2, 8)}`, deviceName, true, this.selectedFiles.length, this.totalSize, Date.now(), status, fileNames);
        HistoryRepository.getInstance().addHistory(entry);
    }
    private waitForTransferComplete(): Promise<boolean> {
        return new Promise<boolean>((resolve) => {
            const callback = new TransferStatusCallback((state: TransferState, message?: string) => {
                this.transferMessage = message || '';
                if (state === TransferState.COMPLETED) {
                    this.transferService.removeListener(callback);
                    resolve(true);
                }
                else if (state === TransferState.ERROR) {
                    this.transferService.removeListener(callback);
                    resolve(false);
                }
            });
            this.transferService.addListener(callback);
            setTimeout(() => {
                this.transferService.removeListener(callback);
                resolve(false);
            }, 120000);
        });
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(AppTheme.getBackground(this.isDark));
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 渐变标题
            Stack.create();
            // 渐变标题
            Stack.width('100%');
            // 渐变标题
            Stack.height(80);
            // 渐变标题
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
            Text.create('发送文件');
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
        // 渐变标题
        Stack.pop();
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
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.padding({ left: 20, right: 20, top: 16, bottom: 8 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('选择接收设备');
            Text.fontSize(15);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(AppTheme.getTextPrimary(this.isDark));
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.selectedDevice) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.padding(14);
                        Row.borderRadius(14);
                        Row.backgroundColor('#F2FFFFFF');
                        Row.backgroundBlurStyle(BlurStyle.BACKGROUND_THIN);
                        Row.shadow({ radius: 6, color: '#0C000000', offsetY: 1 });
                        Row.margin({ left: 20, right: 20, bottom: 4 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.selectedDevice.name);
                        Text.fontSize(15);
                        Text.fontColor(AppTheme.getTextPrimary(this.isDark));
                        Text.layoutWeight(1);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('更换');
                        Text.fontSize(13);
                        Text.fontColor('#6C5CE7');
                        Text.onClick(() => { this.selectedDevice = null; });
                    }, Text);
                    Text.pop();
                    Row.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.padding(14);
                        Row.margin({ left: 20, right: 20, bottom: 4 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('请先在首页选择目标设备');
                        Text.fontSize(14);
                        Text.fontColor('#9E97AA');
                    }, Text);
                    Text.pop();
                    Row.pop();
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.padding({ left: 20, right: 20, top: 12, bottom: 8 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('已选文件');
            Text.fontSize(15);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(AppTheme.getTextPrimary(this.isDark));
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('选择文件');
            Button.fontSize(13);
            Button.fontColor('#6C5CE7');
            Button.backgroundColor('#126C5CE7');
            Button.borderRadius(16);
            Button.height(32);
            Button.padding({ left: 14, right: 14 });
            Button.onClick(() => { this.pickFiles(); });
        }, Button);
        Button.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.selectedFiles.length === 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                        Column.padding({ top: 24, bottom: 24 });
                        Column.justifyContent(FlexAlign.Center);
                        Column.alignItems(HorizontalAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('📂');
                        Text.fontSize(40);
                        Text.margin({ bottom: 8 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('请选择要发送的文件');
                        Text.fontSize(14);
                        Text.fontColor('#9E97AA');
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        List.create();
                        List.width('100%');
                        List.height(220);
                    }, List);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const file = _item;
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
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Row.create();
                                        Row.padding({ top: 10, bottom: 10, left: 14, right: 14 });
                                        Row.borderRadius(10);
                                        Row.backgroundColor('#F8FFFFFF');
                                        Row.margin({ left: 20, right: 20, bottom: 4 });
                                    }, Row);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create(file.name);
                                        Text.fontSize(14);
                                        Text.fontColor(AppTheme.getTextPrimary(this.isDark));
                                        Text.layoutWeight(1);
                                        Text.maxLines(1);
                                        Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                                    }, Text);
                                    Text.pop();
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create(FileSizeFormatter.formatSize(file.size));
                                        Text.fontSize(12);
                                        Text.fontColor(AppTheme.getTextSecondary(this.isDark));
                                        Text.margin({ left: 8 });
                                    }, Text);
                                    Text.pop();
                                    Row.pop();
                                    ListItem.pop();
                                };
                                this.observeComponentCreation2(itemCreation2, ListItem);
                                ListItem.pop();
                            }
                        };
                        this.forEachUpdateFunction(elmtId, this.selectedFiles, forEachItemGenFunction);
                    }, ForEach);
                    ForEach.pop();
                    List.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.padding({ left: 20, right: 20, top: 8 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`共 ${this.selectedFiles.length} 个文件`);
                        Text.fontSize(12);
                        Text.fontColor(AppTheme.getTextSecondary(this.isDark));
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(' · ');
                        Text.fontSize(12);
                        Text.fontColor('#9E97AA');
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(FileSizeFormatter.formatSize(this.totalSize));
                        Text.fontSize(12);
                        Text.fontColor(AppTheme.getTextSecondary(this.isDark));
                    }, Text);
                    Text.pop();
                    Row.pop();
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.isTransferring && this.transferMessage !== '') {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.padding({ top: 12, bottom: 4, left: 20 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.transferMessage);
                        Text.fontSize(13);
                        Text.fontColor('#6C5CE7');
                        Text.margin({ right: 6 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.transferProgress > 0 && this.transferProgress < 1) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    LoadingProgress.create();
                                    LoadingProgress.width(16);
                                    LoadingProgress.height(16);
                                    LoadingProgress.color('#6C5CE7');
                                }, LoadingProgress);
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    Row.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height(100);
        }, Column);
        Column.pop();
        Column.pop();
        Scroll.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithChild();
            Button.width('88%');
            Button.height(50);
            Button.linearGradient({
                angle: this.brandGradient.angle,
                colors: this.brandGradient.colors
            });
            Button.borderRadius(25);
            Button.shadow({ radius: 12, color: this.isTransferring ? '#209E9E9E' : '#406C5CE7', offsetY: 4 });
            Button.margin({ bottom: 20 });
            Button.enabled(!this.isTransferring && this.selectedFiles.length > 0 && this.selectedDevice !== null);
            Button.opacity(!this.isTransferring && this.selectedFiles.length > 0 && this.selectedDevice !== null ? 1.0 : 0.5);
            Button.onClick(() => { this.startTransfer(); });
        }, Button);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.isTransferring ? '传输中...' : '开始传输');
            Text.fontSize(16);
            Text.fontColor(Color.White);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        Button.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
