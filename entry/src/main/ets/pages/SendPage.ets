/**
 * 发送文件页面——沉浸光效毛玻璃风格
 */

import { SelectableFile } from '../models/FileTransfer';
import { TransferHistory } from '../models/TransferSession';
import { TransferStatus } from '../models/Enums';
import { Device } from '../models/Device';
import { FilePickerService } from '../services/FilePickerService';
import { FileTransferService, TransferState, SendFileInfo, TransferStatusCallback } from '../services/FileTransferService';
import { HistoryRepository } from '../services/HistoryRepository';
import { FileSizeFormatter } from '../utils/FileSizeFormatter';
import { AppTheme, BrandGradient, HeaderGradient } from '../theme/AppTheme';
import { AppColors } from '../theme/AppColors';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'SendPage';

@Component
export struct SendPage {
  @State selectedFiles: SelectableFile[] = [];
  @State selectedDevice: Device | null = null;
  @State isTransferring: boolean = false;
  @State transferProgress: number = 0;
  @State transferSpeed: string = '';
  @State transferMessage: string = '';
  @State isDark: boolean = false;
  private filePicker: FilePickerService = FilePickerService.getInstance();
  private transferService: FileTransferService = FileTransferService.getInstance();
  private headerGradient: HeaderGradient = new HeaderGradient();
  private brandGradient: BrandGradient = new BrandGradient();
  private transferCb: TransferStatusCallback | null = null;

  aboutToAppear(): void {
    try {
      const dev = AppStorage.get<Device>('selectedDevice');
      if (dev !== undefined && dev !== null) {
        this.selectedDevice = dev;
      }
    } catch (err) {
      hilog.info(0x0001, TAG, 'no selected device');
    }
  }

  async pickFiles(): Promise<void> {
    const files: SelectableFile[] = await this.filePicker.pickFiles();
    this.selectedFiles = files;
  }

  async startTransfer(): Promise<void> {
    if (this.selectedFiles.length === 0 || this.selectedDevice === null) {
      return;
    }
    AppStorage.setOrCreate<Device>('selectedDevice', this.selectedDevice);
    this.isTransferring = true;
    this.transferProgress = 0;
    this.transferMessage = '正在准备...';
    this.transferSpeed = '';

    const sendFiles: SendFileInfo[] = [];
    for (let i = 0; i < this.selectedFiles.length; i++) {
      const f: SelectableFile = this.selectedFiles[i];
      sendFiles.push(new SendFileInfo(f.path, f.name, f.size));
    }

    this.transferCb = new TransferStatusCallback(
      (state: TransferState, message?: string, progress?: number, speed?: number): void => {
        this.transferMessage = message || '';
        if (progress !== undefined) {
          this.transferProgress = progress;
        }
        if (speed !== undefined && speed > 0) {
          this.transferSpeed = speed >= 1048576
            ? `${(speed / 1048576).toFixed(1)} MB/s`
            : `${(speed / 1024).toFixed(1)} KB/s`;
        }
        if (state === TransferState.COMPLETED) {
          this.transferProgress = 1.0;
          this.transferMessage = '全部发送完成!';
          this.isTransferring = false;
          this.saveSendHistory(TransferStatus.COMPLETED);
          this.cleanupCallback();
        } else if (state === TransferState.ERROR) {
          this.isTransferring = false;
          this.saveSendHistory(TransferStatus.FAILED);
          this.cleanupCallback();
        }
      }
    );
    this.transferService.addListener(this.transferCb);
    await this.transferService.startAsSenderMulti(sendFiles);
  }

  cancelTransfer(): void {
    this.transferService.stop();
    this.isTransferring = false;
    this.transferMessage = '已取消';
    this.cleanupCallback();
  }

  private cleanupCallback(): void {
    if (this.transferCb) {
      this.transferService.removeListener(this.transferCb);
      this.transferCb = null;
    }
  }

  private saveSendHistory(status: TransferStatus): void {
    const deviceName: string = this.selectedDevice !== null ? this.selectedDevice.name : '未知设备';
    const fileNames: string[] = [];
    for (let i = 0; i < this.selectedFiles.length; i++) {
      fileNames.push(this.selectedFiles[i].name);
    }
    const entry: TransferHistory = new TransferHistory(
      `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      deviceName, true,
      this.selectedFiles.length,
      this.totalSize, Date.now(),
      status, fileNames
    );
    HistoryRepository.getInstance().addHistory(entry);
  }

  get totalSize(): number {
    let sum: number = 0;
    for (let i = 0; i < this.selectedFiles.length; i++) {
      sum += this.selectedFiles[i].size;
    }
    return sum;
  }

  private shouldEnableSend(): boolean {
    return this.selectedFiles.length > 0 && this.selectedDevice !== null;
  }

  private getFileEmoji(name: string): string {
    const ext: string = name.split('.').pop()?.toLowerCase() || '';
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].indexOf(ext) >= 0) {
      return '🖼️';
    }
    if (['mp4', 'mov', 'avi', 'mkv'].indexOf(ext) >= 0) {
      return '🎬';
    }
    if (['pdf'].indexOf(ext) >= 0) {
      return '📄';
    }
    if (['zip', 'rar', '7z', 'tar', 'gz'].indexOf(ext) >= 0) {
      return '🗜️';
    }
    if (['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'].indexOf(ext) >= 0) {
      return '📊';
    }
    if (['mp3', 'wav', 'flac', 'aac'].indexOf(ext) >= 0) {
      return '🎵';
    }
    return '📁';
  }

  build() {
    Column() {
      // ====== 标题栏 ======
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: this.headerGradient.angle,
            colors: this.headerGradient.colors
          })
        Row() {
          Image($r('sys.symbol.arrow_up'))
            .width(22)
            .height(22)
            .fillColor(Color.White)
            .margin({ right: 10 })
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

      // ====== 内容区 ======
      Scroll() {
        Column() {
          // 接收设备
          this.buildDeviceSection()
          // 已选文件
          this.buildFileSection()
          // 传输进度
          if (this.isTransferring && this.transferMessage !== '') {
            this.buildProgressSection()
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

      // ====== 底部操作栏 ======
      if (this.isTransferring) {
        Row() {
          Button() {
            Text('取消传输')
              .fontSize(15)
              .fontColor('#FF6B6B')
              .fontWeight(FontWeight.Medium)
          }
          .width('42%')
          .height(50)
          .backgroundColor('#12FF6B6B')
          .borderRadius(25)
          .onClick(() => { this.cancelTransfer(); })

          Button() {
            Text('传输中...')
              .fontSize(15)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
          }
          .width('42%')
          .height(50)
          .linearGradient({
            angle: this.brandGradient.angle,
            colors: this.brandGradient.colors
          })
          .borderRadius(25)
          .enabled(false)
          .opacity(0.5)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 20 })
      } else {
        Button() {
          Row() {
            Image($r('sys.symbol.arrow_up'))
              .width(16)
              .height(16)
              .fillColor(Color.White)
              .margin({ right: 6 })
            Text('开始传输')
              .fontSize(16)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Bold)
          }
        }
        .width('88%')
        .height(50)
        .linearGradient({
          angle: this.brandGradient.angle,
          colors: this.brandGradient.colors
        })
        .borderRadius(25)
        .shadow({ radius: 12, color: this.shouldEnableSend() ? '#406C5CE7' : '#209E9E9E', offsetY: 4 })
        .margin({ bottom: 20 })
        .enabled(this.shouldEnableSend())
        .opacity(this.shouldEnableSend() ? 1.0 : 0.45)
        .onClick(() => { this.startTransfer(); })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.getBackground(this.isDark))
  }

  @Builder
  buildDeviceSection(): void {
    Column() {
      Row() {
        Row()
          .width(4)
          .height(16)
          .borderRadius(2)
          .backgroundColor(AppColors.PRIMARY)
          .margin({ right: 8 })
        Text('接收设备')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.getTextPrimary(this.isDark))
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 8 })
    }

    if (this.selectedDevice !== null) {
      Row() {
        Column()
          .width(40)
          .height(40)
          .borderRadius(14)
          .linearGradient({
            angle: 135,
            colors: [['#6C5CE7', 0.0], ['#A29BFE', 1.0]]
          })
          .justifyContent(FlexAlign.Center)
          .margin({ right: 10 })
        Image($r('app.media.ic_avatar_placeholder'))
          .width(22)
          .height(22)
          .fillColor(Color.White)

        Column() {
          Text(this.selectedDevice.displayName)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.getTextPrimary(this.isDark))
          Text('已选择')
            .fontSize(11)
            .fontColor('#00A383')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text('更换')
          .fontSize(13)
          .fontColor(AppColors.PRIMARY)
          .fontWeight(FontWeight.Medium)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor('#12' + AppColors.PRIMARY.substring(1))
          .borderRadius(14)
          .onClick((): void => { this.selectedDevice = null; })
      }
      .padding(14)
      .borderRadius(18)
      .backgroundColor(AppTheme.frostCardBg(this.isDark))
      .shadow({ radius: 6, color: '#0C000000', offsetY: 1 })
      .margin({ left: 20, right: 20, bottom: 4 })
    } else {
      Row() {
        Image($r('sys.symbol.house_fill'))
          .width(18)
          .height(18)
          .fillColor('#C0C0C0')
          .margin({ right: 8 })
        Text('请先在首页选择目标设备')
          .fontSize(14)
          .fontColor(AppTheme.getTextSecondary(this.isDark))
          .fontWeight(FontWeight.Medium)
      }
      .padding(14)
      .width('100%')
      .backgroundColor('#F0F0F5')
      .borderRadius(14)
      .margin({ left: 20, right: 20, bottom: 4 })
    }
  }

  @Builder
  buildFileSection(): void {
    Row() {
      Row()
        .width(4)
        .height(16)
        .borderRadius(2)
        .backgroundColor(AppColors.SUCCESS)
        .margin({ right: 8 })
      Text('已选文件')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.getTextPrimary(this.isDark))

      Blank()

      Button() {
        Row() {
          Image($r('sys.symbol.plus'))
            .width(12)
            .height(12)
            .fillColor(Color.White)
            .margin({ right: 4 })
          Text('选择文件')
            .fontSize(12)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
      }
      .linearGradient({
        angle: 135,
        colors: [['#6C5CE7', 0.0], ['#A29BFE', 1.0]]
      })
      .borderRadius(16)
      .height(32)
      .padding({ left: 14, right: 14 })
      .onClick((): void => { this.pickFiles(); })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 8 })

    if (this.selectedFiles.length === 0) {
      Column() {
        Column()
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#12' + AppColors.PRIMARY.substring(1))
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 16 })
        Text('📂')
          .fontSize(36)

        Text('请选择要发送的文件')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppTheme.getTextSecondary(this.isDark))
          .margin({ bottom: 8 })

        Text('支持图片、文档、音视频等任意格式')
          .fontSize(12)
          .fontColor('#B0B0B0')
      }
      .width('100%')
      .padding({ top: 24, bottom: 24 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      // 文件列表
      List() {
        ForEach(this.selectedFiles, (file: SelectableFile) => {
          ListItem() {
            Row() {
              Text(this.getFileEmoji(file.name))
                .fontSize(20)
                .margin({ right: 10 })

              Column() {
                Text(file.name)
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(AppTheme.getTextPrimary(this.isDark))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(FileSizeFormatter.formatSize(file.size))
                  .fontSize(11)
                  .fontColor(AppTheme.getTextSecondary(this.isDark))
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .padding({ top: 10, bottom: 10, left: 14, right: 14 })
            .borderRadius(12)
            .backgroundColor('#F8FFFFFF')
            .margin({ left: 20, right: 20, bottom: 4 })
          }
        })
      }
      .width('100%')
      .height(220)

      // 统计行
      Row() {
        Column()
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor(AppColors.PRIMARY)
          .margin({ right: 6 })
        Text(`${this.selectedFiles.length} 个文件 · ${FileSizeFormatter.formatSize(this.totalSize)}`)
          .fontSize(12)
          .fontColor(AppTheme.getTextSecondary(this.isDark))
          .fontWeight(FontWeight.Medium)
      }
      .padding({ left: 20, right: 20, top: 8 })
    }
  }

  @Builder
  buildProgressSection(): void {
    Column() {
      Row() {
        LoadingProgress()
          .width(14)
          .height(14)
          .color(AppColors.PRIMARY)
          .margin({ right: 6 })
        Text(this.transferMessage)
          .fontSize(13)
          .fontColor(AppColors.PRIMARY)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)

        if (this.transferSpeed !== '') {
          Text(this.transferSpeed)
            .fontSize(12)
            .fontColor(AppTheme.getTextSecondary(this.isDark))
            .fontWeight(FontWeight.Medium)
            .margin({ left: 8 })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 8 })

      if (this.transferProgress > 0) {
        Row() {
          Progress({ value: this.transferProgress, total: 1, style: ProgressStyle.Linear })
            .width('100%')
            .height(6)
            .color(AppColors.PRIMARY)
            .backgroundColor('#1E' + AppColors.PRIMARY.substring(1))
            .borderRadius(3)
        }
        .padding({ left: 20, right: 20 })

        Text(`${Math.round(this.transferProgress * 100)}%`)
          .fontSize(12)
          .fontColor(AppTheme.getTextSecondary(this.isDark))
          .width('100%')
          .textAlign(TextAlign.End)
          .padding({ left: 20, right: 20, top: 4 })
      }
    }
    .padding({ top: 12 })
  }
}
