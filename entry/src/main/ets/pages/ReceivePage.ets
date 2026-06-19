/**
 * 接收文件页面——沉浸光效毛玻璃风格
 */

import { TransferStatus } from '../models/Enums';
import { TransferHistory } from '../models/TransferSession';
import { TransferProgressRing } from '../components/TransferProgressRing';
import { FileTransferService, TransferState, TransferStatusCallback } from '../services/FileTransferService';
import { FileSizeFormatter } from '../utils/FileSizeFormatter';
import { HistoryRepository } from '../services/HistoryRepository';
import { AppTheme, AccentGradient } from '../theme/AppTheme';
import { AppColors } from '../theme/AppColors';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ReceivePage';

@Component
export struct ReceivePage {
  @State isReceiving: boolean = false;
  @State transferStatus: TransferStatus = TransferStatus.IDLE;
  @State progress: number = 0;
  @State speed: number = 0;
  @State eta: number = -1;
  @State fileName: string = '';
  @State fileSize: number = 0;
  @State statusMessage: string = '';
  @State isDark: boolean = false;
  private accentGradient: AccentGradient = new AccentGradient();
  private transferService: FileTransferService = FileTransferService.getInstance();
  private transferCallback: TransferStatusCallback | null = null;

  aboutToDisappear(): void {
    if (this.transferCallback) {
      this.transferService.removeListener(this.transferCallback);
      this.transferCallback = null;
    }
  }

  startReceiving(): void {
    if (!this.transferCallback) {
      this.transferCallback = new TransferStatusCallback(
        (state: TransferState, message?: string, progress?: number, speed?: number): void => {
          this.onTransferState(state, message, progress, speed);
        }
      );
      this.transferService.addListener(this.transferCallback);
    }

    this.isReceiving = true;
    this.transferStatus = TransferStatus.PREPARING;
    this.progress = 0;
    this.fileName = '';
    this.fileSize = 0;
    this.statusMessage = '正在准备接收...';
    this.transferService.startAsReceiver();
  }

  private onTransferState(state: TransferState, message?: string, progress?: number, speed?: number): void {
    this.statusMessage = message || '';

    if (speed !== undefined && speed > 0) {
      this.speed = speed;
      if (this.fileSize > 0 && this.progress > 0) {
        const remaining: number = this.fileSize * (1 - this.progress);
        this.eta = remaining / speed;
      }
    }

    switch (state) {
      case TransferState.CREATING_GROUP:
      case TransferState.GROUP_CREATED:
      case TransferState.P2P_CONNECTING:
      case TransferState.P2P_CONNECTED:
      case TransferState.SOCKET_LISTENING:
        this.transferStatus = TransferStatus.PREPARING;
        break;
      case TransferState.TRANSFERRING:
        this.transferStatus = TransferStatus.TRANSFERRING;
        if (progress !== undefined && progress > 0) {
          this.progress = progress;
        }
        break;
      case TransferState.COMPLETED:
        this.transferStatus = TransferStatus.COMPLETED;
        this.progress = 1.0;
        this.speed = 0;
        this.eta = -1;
        if (message) {
          this.fileName = message.replace('已保存: ', '');
        }
        this.saveReceiveHistory(TransferStatus.COMPLETED);
        break;
      case TransferState.ERROR:
        this.transferStatus = TransferStatus.FAILED;
        this.saveReceiveHistory(TransferStatus.FAILED);
        break;
      default:
        break;
    }
  }

  cancelReceiving(): void {
    this.transferService.stop();
    this.isReceiving = false;
    this.transferStatus = TransferStatus.CANCELLED;
    this.statusMessage = '已取消';
  }

  resetState(): void {
    this.transferService.stop();
    this.isReceiving = false;
    this.transferStatus = TransferStatus.IDLE;
    this.progress = 0;
    this.fileName = '';
    this.fileSize = 0;
    this.statusMessage = '';
    this.speed = 0;
    this.eta = -1;
  }

  private saveReceiveHistory(status: TransferStatus): void {
    if (!this.fileName) {
      this.fileName = 'unknown_file';
    }
    const entry: TransferHistory = new TransferHistory(
      `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      '附近设备', false, 1, this.fileSize,
      Date.now(), status, [this.fileName]
    );
    HistoryRepository.getInstance().addHistory(entry);
  }

  private formatSpeed(bytesPerSecond: number): string {
    if (bytesPerSecond <= 0) {
      return '';
    }
    if (bytesPerSecond >= 1048576) {
      return `${(bytesPerSecond / 1048576).toFixed(1)} MB/s`;
    }
    return `${(bytesPerSecond / 1024).toFixed(1)} KB/s`;
  }

  build() {
    Column() {
      // ====== 标题栏 ======
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: this.accentGradient.angle,
            colors: this.accentGradient.colors
          })
        Row() {
          Image($r('sys.symbol.arrow_down'))
            .width(22)
            .height(22)
            .fillColor(Color.White)
            .margin({ right: 10 })
          Text('接收文件')
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
      if (!this.isReceiving) {
        // 待接收状态
        Column() {
          Column()
            .width(100)
            .height(100)
            .borderRadius(50)
            .backgroundColor('#1200C9A7')
            .justifyContent(FlexAlign.Center)
            .margin({ bottom: 24 })
          Image($r('sys.symbol.arrow_down'))
            .width(48)
            .height(48)
            .fillColor('#00C9A7')

          Text('等待接收文件')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.getTextPrimary(this.isDark))
            .margin({ top: 8, bottom: 8 })

          Text('双方设备需同时打开 ToShare\n点击下方按钮开始接收')
            .fontSize(14)
            .fontColor(AppTheme.getTextSecondary(this.isDark))
            .textAlign(TextAlign.Center)
            .margin({ bottom: 32 })

          Button() {
            Row() {
              Image($r('sys.symbol.arrow_down'))
                .width(18)
                .height(18)
                .fillColor(Color.White)
                .margin({ right: 6 })
              Text('开始接收')
                .fontSize(15)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Bold)
            }
          }
          .linearGradient({
            angle: this.accentGradient.angle,
            colors: this.accentGradient.colors
          })
          .borderRadius(24)
          .height(50)
          .padding({ left: 36, right: 36 })
          .shadow({ radius: 12, color: '#4000C9A7', offsetY: 4 })
          .onClick(() => { this.startReceiving(); })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(32)
      } else {
        // 传输中/完成 状态
        Scroll() {
          Column() {
            // 进度环
            TransferProgressRing({
              progress: this.progress,
              status: this.transferStatus === TransferStatus.COMPLETED ? TransferStatus.COMPLETED :
                this.transferStatus === TransferStatus.FAILED ? TransferStatus.FAILED :
                this.transferStatus === TransferStatus.CANCELLED ? TransferStatus.CANCELLED :
                TransferStatus.TRANSFERRING,
              ringSize: 130,
              strokeWidth: 10,
              isDark: this.isDark
            })
            .margin({ top: 48, bottom: 24 })

            // 文件名
            if (this.fileName.length > 0) {
              Text(this.fileName)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppTheme.getTextPrimary(this.isDark))
                .margin({ bottom: 4 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .padding({ left: 32, right: 32 })
            } else {
              Text('正在建立连接...')
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor(AppTheme.getTextPrimary(this.isDark))
                .margin({ bottom: 4 })
            }

            // 文件大小
            if (this.fileSize > 0) {
              Text(FileSizeFormatter.formatSize(this.fileSize))
                .fontSize(14)
                .fontColor(AppTheme.getTextSecondary(this.isDark))
                .margin({ bottom: 16 })
            }

            // 状态消息
            Text(this.statusMessage)
              .fontSize(13)
              .fontColor(AppColors.PRIMARY)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 16 })

            // 传输中 - 进度详情
            if (this.transferStatus === TransferStatus.TRANSFERRING) {
              Column() {
                Row() {
                  Text(`${Math.round(this.progress * 100)}%`)
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(AppTheme.getTextPrimary(this.isDark))

                  if (this.speed > 0) {
                    Text(' · ')
                      .fontSize(14)
                      .fontColor(AppTheme.getTextSecondary(this.isDark))
                    Text(this.formatSpeed(this.speed))
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(AppColors.PRIMARY)
                  }
                }
                .margin({ bottom: 4 })

                if (this.eta > 0) {
                  Text(FileSizeFormatter.formatSize(this.progress * this.fileSize) +
                    ' / ' + FileSizeFormatter.formatSize(this.fileSize))
                    .fontSize(12)
                    .fontColor(AppTheme.getTextSecondary(this.isDark))
                    .margin({ bottom: 2 })
                  Text(`剩余约 ${Math.round(this.eta)} 秒`)
                    .fontSize(12)
                    .fontColor('#B0B0B0')
                }
              }
              .margin({ bottom: 24 })
              .alignItems(HorizontalAlign.Center)
            }

            // 准备中 - loading
            if (this.transferStatus === TransferStatus.PREPARING) {
              Row() {
                LoadingProgress()
                  .width(18)
                  .height(18)
                  .color('#00C9A7')
                  .margin({ right: 8})
                Text('正在创建连接...')
                  .fontSize(14)
                  .fontColor(AppTheme.getTextSecondary(this.isDark))
              }
              .margin({ bottom: 24 })
            }

            // 操作按钮
            Row() {
              if (this.transferStatus === TransferStatus.TRANSFERRING ||
                  this.transferStatus === TransferStatus.PREPARING) {
                Button() {
                  Text('取消')
                    .fontSize(14)
                    .fontColor('#FF6B6B')
                    .fontWeight(FontWeight.Medium)
                }
                .backgroundColor('#12FF6B6B')
                .borderRadius(22)
                .height(44)
                .padding({ left: 30, right: 30 })
                .onClick(() => { this.cancelReceiving(); })
              }

              if (this.transferStatus === TransferStatus.COMPLETED ||
                  this.transferStatus === TransferStatus.FAILED ||
                  this.transferStatus === TransferStatus.CANCELLED) {
                Button() {
                  Row() {
                    if (this.transferStatus === TransferStatus.COMPLETED) {
                      Text('✅ 已完成')
                        .fontSize(14)
                        .fontColor(Color.White)
                        .fontWeight(FontWeight.Medium)
                    } else {
                      Text('重新开始')
                        .fontSize(14)
                        .fontColor(Color.White)
                        .fontWeight(FontWeight.Medium)
                    }
                  }
                }
                .linearGradient({
                  angle: 135,
                  colors: this.transferStatus === TransferStatus.COMPLETED ?
                    [['#00C9A7', 0.0], ['#55EFC4', 1.0]] :
                    [['#6C5CE7', 0.0], ['#A29BFE', 1.0]]
                })
                .borderRadius(22)
                .height(44)
                .padding({ left: 30, right: 30 })
                .shadow({ radius: 8, color: '#30000000', offsetY: 2 })
                .onClick(() => {
                  if (this.transferStatus === TransferStatus.COMPLETED) {
                    this.resetState();
                  } else {
                    this.resetState();
                  }
                })

                Column().width(12)

                Button('关闭')
                  .fontSize(14)
                  .fontColor(AppTheme.getTextSecondary(this.isDark))
                  .backgroundColor('#F0F0F5')
                  .borderRadius(22)
                  .height(44)
                  .padding({ left: 24, right: 24 })
                  .onClick(() => { this.resetState(); })
              }
            }
            .margin({ top: 24 })

            Column()
              .width('100%')
              .height(40)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.getBackground(this.isDark))
  }
}
