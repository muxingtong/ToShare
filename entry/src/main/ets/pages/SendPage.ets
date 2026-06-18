import { SelectableFile } from '../models/FileTransfer';
import { TransferHistory } from '../models/TransferSession';
import { TransferStatus } from '../models/Enums';
import { Device } from '../models/Device';
import { FilePickerService } from '../services/FilePickerService';
import { FileTransferService, TransferState, TransferStatusCallback } from '../services/FileTransferService';
import { HistoryRepository } from '../services/HistoryRepository';
import { FileSizeFormatter } from '../utils/FileSizeFormatter';
import { AppTheme, BrandGradient, HeaderGradient } from '../theme/AppTheme';
import { AppColors } from '../theme/AppColors';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Component
export struct SendPage {
  @State selectedFiles: SelectableFile[] = [];
  @State selectedDevice: Device | null = null;
  @State isTransferring: boolean = false;
  @State transferProgress: number = 0;
  @State transferMessage: string = '';
  @State isDark: boolean = false;
  private filePicker: FilePickerService = FilePickerService.getInstance();
  private transferService: FileTransferService = FileTransferService.getInstance();
  private headerGradient: HeaderGradient = new HeaderGradient();
  private brandGradient: BrandGradient = new BrandGradient();

  aboutToAppear(): void {
    try {
      const dev = AppStorage.get<Device>('selectedDevice');
      if (dev) {
        this.selectedDevice = dev;
      }
    } catch (err) {
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
        } else {
          hilog.error(0x0001, 'ToShare', 'Transfer failed for: %{public}s', file.name);
          break;
        }
      } catch (err) {
        hilog.error(0x0001, 'ToShare', 'Transfer error: %{public}s', JSON.stringify(err));
        break;
      }
    }

    this.isTransferring = false;
    if (this.transferProgress >= 1.0) {
      this.transferMessage = '全部发送完成!';
      this.saveSendHistory(TransferStatus.COMPLETED);
    } else if (this.transferProgress > 0) {
      this.transferMessage = '部分发送完成';
      this.saveSendHistory(TransferStatus.COMPLETED);
    } else {
      this.transferMessage = '发送失败';
      this.saveSendHistory(TransferStatus.FAILED);
    }
  }

  private saveSendHistory(status: TransferStatus): void {
    const deviceName = this.selectedDevice?.name || '未知设备';
    const fileNames = this.selectedFiles.map(f => f.name);
    const entry = new TransferHistory(
      `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      deviceName,
      true,
      this.selectedFiles.length,
      this.totalSize,
      Date.now(),
      status,
      fileNames
    );
    HistoryRepository.getInstance().addHistory(entry);
  }

  private waitForTransferComplete(): Promise<boolean> {
    return new Promise<boolean>((resolve) => {
      const callback = new TransferStatusCallback((state: TransferState, message?: string) => {
        this.transferMessage = message || '';
        if (state === TransferState.COMPLETED) {
          this.transferService.removeListener(callback);
          resolve(true);
        } else if (state === TransferState.ERROR) {
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

  get totalSize(): number {
    return this.selectedFiles.reduce((sum, f) => sum + f.size, 0);
  }

  build() {
    Column() {
      // 渐变标题
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: this.headerGradient.angle,
            colors: this.headerGradient.colors
          })
        Row() {
          Text('发送文件')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Blank()
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 4, bottom: 4 })
      }
      .width('100%')
      .height(80)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      Scroll() {
        Column() {
          Row() {
            Text('选择接收设备')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppTheme.getTextPrimary(this.isDark))
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 8 })

          if (this.selectedDevice) {
            Row() {
              Text(this.selectedDevice.name)
                .fontSize(15)
                .fontColor(AppTheme.getTextPrimary(this.isDark))
                .layoutWeight(1)
              Text('更换')
                .fontSize(13)
                .fontColor('#6C5CE7')
                .onClick(() => { this.selectedDevice = null; })
            }
            .padding(14)
            .borderRadius(14)
            .backgroundColor('#F2FFFFFF')
            .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
            .shadow({ radius: 6, color: '#0C000000', offsetY: 1 })
            .margin({ left: 20, right: 20, bottom: 4 })
          } else {
            Row() {
              Text('请先在首页选择目标设备')
                .fontSize(14)
                .fontColor('#9E97AA')
            }
            .padding(14)
            .margin({ left: 20, right: 20, bottom: 4 })
          }

          Row() {
            Text('已选文件')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppTheme.getTextPrimary(this.isDark))
            Blank()
            Button('选择文件')
              .fontSize(13)
              .fontColor('#6C5CE7')
              .backgroundColor('#126C5CE7')
              .borderRadius(16)
              .height(32)
              .padding({ left: 14, right: 14 })
              .onClick(() => { this.pickFiles(); })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 12, bottom: 8 })

          if (this.selectedFiles.length === 0) {
            Column() {
              Text('📂')
                .fontSize(40)
                .margin({ bottom: 8 })
              Text('请选择要发送的文件')
                .fontSize(14)
                .fontColor('#9E97AA')
            }
            .width('100%')
            .padding({ top: 24, bottom: 24 })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            List() {
              ForEach(this.selectedFiles, (file: SelectableFile) => {
                ListItem() {
                  Row() {
                    Text(file.name)
                      .fontSize(14)
                      .fontColor(AppTheme.getTextPrimary(this.isDark))
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(FileSizeFormatter.formatSize(file.size))
                      .fontSize(12)
                      .fontColor(AppTheme.getTextSecondary(this.isDark))
                      .margin({ left: 8 })
                  }
                  .padding({ top: 10, bottom: 10, left: 14, right: 14 })
                  .borderRadius(10)
                  .backgroundColor('#F8FFFFFF')
                  .margin({ left: 20, right: 20, bottom: 4 })
                }
              })
            }
            .width('100%')
            .height(220)

            Row() {
              Text(`共 ${this.selectedFiles.length} 个文件`)
                .fontSize(12)
                .fontColor(AppTheme.getTextSecondary(this.isDark))
              Text(' · ')
                .fontSize(12)
                .fontColor('#9E97AA')
              Text(FileSizeFormatter.formatSize(this.totalSize))
                .fontSize(12)
                .fontColor(AppTheme.getTextSecondary(this.isDark))
            }
            .padding({ left: 20, right: 20, top: 8 })
          }

          if (this.isTransferring && this.transferMessage !== '') {
            Row() {
              Text(this.transferMessage)
                .fontSize(13)
                .fontColor('#6C5CE7')
                .margin({ right: 6 })
              if (this.transferProgress > 0 && this.transferProgress < 1) {
                LoadingProgress()
                  .width(16)
                  .height(16)
                  .color('#6C5CE7')
              }
            }
            .padding({ top: 12, bottom: 4, left: 20 })
          }

          Column()
            .width('100%')
            .height(100)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)

      Button() {
        Text(this.isTransferring ? '传输中...' : '开始传输')
          .fontSize(16)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .width('88%')
      .height(50)
      .linearGradient({
        angle: this.brandGradient.angle,
        colors: this.brandGradient.colors
      })
      .borderRadius(25)
      .shadow({ radius: 12, color: this.isTransferring ? '#209E9E9E' : '#406C5CE7', offsetY: 4 })
      .margin({ bottom: 20 })
      .enabled(!this.isTransferring && this.selectedFiles.length > 0 && this.selectedDevice !== null)
      .opacity(!this.isTransferring && this.selectedFiles.length > 0 && this.selectedDevice !== null ? 1.0 : 0.5)
      .onClick(() => { this.startTransfer(); })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.getBackground(this.isDark))
  }
}
