import { TransferStatus } from '../models/Enums';
import { TransferHistory } from '../models/TransferSession';
import { TransferProgressRing } from '../components/TransferProgressRing';
import { FileTransferService, TransferState, TransferStatusCallback } from '../services/FileTransferService';
import { FileSizeFormatter } from '../utils/FileSizeFormatter';
import { HistoryRepository } from '../services/HistoryRepository';
import { AppColors } from '../theme/AppColors';
import { AccentGradient } from '../theme/AppTheme';
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
        (state: TransferState, message?: string, progress?: number, speed?: number) => {
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
        const remaining = this.fileSize * (1 - this.progress);
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
    this.transferStatus = TransferStatus.FAILED;
    this.statusMessage = '已取消';
  }

  stopReceiving(): void {
    this.transferService.stop();
    this.isReceiving = false;
    this.transferStatus = TransferStatus.IDLE;
    this.progress = 0;
    this.fileName = '';
    this.fileSize = 0;
    this.statusMessage = '';
  }

  private saveReceiveHistory(status: TransferStatus): void {
    if (!this.fileName) {
      this.fileName = 'unknown_file';
    }
    const entry = new TransferHistory(
      `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
      '附近设备',
      false,
      1,
      this.fileSize,
      Date.now(),
      status,
      [this.fileName]
    );
    HistoryRepository.getInstance().addHistory(entry);
  }

  build() {
    Column() {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: this.accentGradient.angle,
            colors: this.accentGradient.colors
          })
        Row() {
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

      if (!this.isReceiving) {
        Column() {
          Column()
            .width(100)
            .height(100)
            .borderRadius(50)
            .backgroundColor('#1200C9A7')
            .justifyContent(FlexAlign.Center)
            .margin({ bottom: 20 })

          Text('等待接收文件')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1B1F')
            .margin({ bottom: 8 })

          Text('双方设备需同时打开 ToShare\n点击下方按钮开始接收')
            .fontSize(14)
            .fontColor('#625B71')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 24 })

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
                .fontWeight(FontWeight.Medium)
            }
          }
          .linearGradient({
            angle: this.accentGradient.angle,
            colors: this.accentGradient.colors
          })
          .borderRadius(24)
          .height(48)
          .padding({ left: 32, right: 32 })
          .shadow({ radius: 10, color: '#4000C9A7', offsetY: 4 })
          .onClick(() => { this.startReceiving(); })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(32)
      } else {
        Scroll() {
          Column() {
            TransferProgressRing({
              progress: this.progress,
              status: this.transferStatus === TransferStatus.COMPLETED ? TransferStatus.COMPLETED :
                this.transferStatus === TransferStatus.FAILED ? TransferStatus.FAILED :
                TransferStatus.TRANSFERRING,
              ringSize: 120,
              strokeWidth: 8
            })
            .margin({ top: 48, bottom: 24 })

            Text(this.fileName || '正在建立连接...')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1B1F')
              .margin({ bottom: 4 })

            if (this.fileSize > 0) {
              Text(FileSizeFormatter.formatSize(this.fileSize))
                .fontSize(14)
                .fontColor('#625B71')
                .margin({ bottom: 16 })
            }

            Text(this.statusMessage)
              .fontSize(13)
              .fontColor('#6C5CE7')
              .margin({ bottom: 16 })

            if (this.transferStatus === TransferStatus.TRANSFERRING) {
              Column() {
                Row() {
                  Text(`${Math.round(this.progress * 100)}%`)
                    .fontSize(14)
                    .fontColor('#625B71')
                  if (this.speed > 0) {
                    Text(' · ')
                      .fontSize(14)
                      .fontColor('#625B71')
                    Text(this.speed >= 1024 * 1024
                      ? `${(this.speed / (1024 * 1024)).toFixed(1)} MB/s`
                      : `${(this.speed / 1024).toFixed(1)} KB/s`)
                      .fontSize(14)
                      .fontColor('#6C5CE7')
                  }
                }
                .margin({ bottom: 4 })
                if (this.eta > 0) {
                  Text(`剩余 ${Math.round(this.eta)} 秒`)
                    .fontSize(12)
                    .fontColor('#9E97AA')
                    .margin({ bottom: 8 })
                }
              }
              .margin({ bottom: 24 })
              .alignItems(HorizontalAlign.Center)
            }

            if (this.transferStatus === TransferStatus.PREPARING) {
              Row() {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .color('#00C9A7')
                  .margin({ right: 8 })
                Text('正在创建连接...')
                  .fontSize(14)
                  .fontColor('#625B71')
              }
              .margin({ bottom: 24 })
            }

            Row() {
              if (this.transferStatus === TransferStatus.TRANSFERRING ||
                  this.transferStatus === TransferStatus.PREPARING) {
                Button('取消')
                  .fontSize(14)
                  .fontColor('#FF6B6B')
                  .backgroundColor('#12FF6B6B')
                  .borderRadius(20)
                  .height(40)
                  .padding({ left: 24, right: 24 })
                  .onClick(() => { this.cancelReceiving(); })
              }

              if (this.transferStatus === TransferStatus.COMPLETED ||
                  this.transferStatus === TransferStatus.FAILED) {
                Button('返回')
                  .fontSize(14)
                  .fontColor('#6C5CE7')
                  .backgroundColor('#126C5CE7')
                  .borderRadius(20)
                  .height(40)
                  .padding({ left: 24, right: 24 })
                  .onClick(() => { this.stopReceiving(); })
              }
            }
            .margin({ top: 24 })
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
    .backgroundColor('#F0EFF5')
  }
}
