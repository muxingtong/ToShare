import { TransferStatus } from '../models/Enums';
import { TransferHistory } from '../models/TransferSession';
import { TransferProgressRing } from '../components/TransferProgressRing';
import { FileSizeFormatter } from '../utils/FileSizeFormatter';
import { RelativeTime } from '../utils/RelativeTime';
import { HistoryRepository } from '../services/HistoryRepository';
import { AppColors } from '../theme/AppColors';
import { AccentGradient } from '../theme/AppTheme';

@Component
export struct ReceivePage {
  @State isReceiving: boolean = false;
  @State transferStatus: TransferStatus = TransferStatus.IDLE;
  @State progress: number = 0;
  @State speed: number = 0;
  @State eta: number = -1;
  @State fileName: string = '';
  @State fileSize: number = 0;
  @State isDark: boolean = false;
  private accentGradient: AccentGradient = new AccentGradient();

  simulateReceive(): void {
    this.isReceiving = true;
    this.transferStatus = TransferStatus.TRANSFERRING;
    this.fileName = 'document.pdf';
    this.fileSize = 15 * 1024 * 1024;

    let simulatedProgress = 0;
    const interval = setInterval(() => {
      simulatedProgress += 0.05;
      this.progress = Math.min(simulatedProgress, 1.0);
      this.speed = 2 * 1024 * 1024 + Math.random() * 1024 * 1024;
      if (simulatedProgress >= 1.0) {
        clearInterval(interval);
        this.transferStatus = TransferStatus.COMPLETED;
        this.progress = 1.0;
        this.saveReceiveHistory(TransferStatus.COMPLETED);
      }
    }, 300);
  }

  pauseTransfer(): void {
    this.transferStatus = TransferStatus.PAUSED;
  }

  resumeTransfer(): void {
    this.transferStatus = TransferStatus.TRANSFERRING;
  }

  cancelTransfer(): void {
    this.transferStatus = TransferStatus.CANCELLED;
    this.isReceiving = false;
    this.progress = 0;
    this.saveReceiveHistory(TransferStatus.CANCELLED);
  }

  private saveReceiveHistory(status: TransferStatus): void {
    if (!this.fileName) {
      return;
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

          Text('确保双方设备已连接\n即可接收来自附近设备的文件')
            .fontSize(14)
            .fontColor('#625B71')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 24 })

          Button('模拟接收')
            .fontSize(14)
            .fontColor(Color.White)
            .linearGradient({
              angle: this.accentGradient.angle,
              colors: this.accentGradient.colors
            })
            .borderRadius(20)
            .height(42)
            .padding({ left: 28, right: 28 })
            .shadow({ radius: 8, color: '#3000C9A7', offsetY: 3 })
            .onClick(() => { this.simulateReceive(); })
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
              status: this.transferStatus,
              ringSize: 120,
              strokeWidth: 8
            })
            .margin({ top: 48, bottom: 24 })

            Text(this.fileName)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1B1F')
              .margin({ bottom: 4 })

            Text(FileSizeFormatter.formatSize(this.fileSize))
              .fontSize(14)
              .fontColor('#625B71')
              .margin({ bottom: 16 })

            if (this.transferStatus === TransferStatus.TRANSFERRING) {
              Row() {
                Column()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor('#00C9A7')
                  .margin({ right: 6 })
                Text(`${FileSizeFormatter.formatSpeed(this.speed)}`)
                  .fontSize(14)
                  .fontColor('#625B71')
              }
              .margin({ bottom: 4 })

              Text(`剩余 ${RelativeTime.formatETA(this.eta)}`)
                .fontSize(13)
                .fontColor('#9E9E9E')
                .margin({ bottom: 24 })
            }

            Row({ space: 12 }) {
              if (this.transferStatus === TransferStatus.TRANSFERRING ||
                  this.transferStatus === TransferStatus.PREPARING) {
                Button('暂停')
                  .fontSize(14)
                  .fontColor('#6C5CE7')
                  .backgroundColor('#126C5CE7')
                  .borderRadius(20)
                  .height(40)
                  .padding({ left: 24, right: 24 })
                  .onClick(() => { this.pauseTransfer(); })
              }

              if (this.transferStatus === TransferStatus.PAUSED) {
                Button('继续')
                  .fontSize(14)
                  .fontColor('#00C9A7')
                  .backgroundColor('#1200C9A7')
                  .borderRadius(20)
                  .height(40)
                  .padding({ left: 24, right: 24 })
                  .onClick(() => { this.resumeTransfer(); })
              }

              Button('取消')
                .fontSize(14)
                .fontColor('#FF6B6B')
                .backgroundColor('#12FF6B6B')
                .borderRadius(20)
                .height(40)
                .padding({ left: 24, right: 24 })
                .onClick(() => { this.cancelTransfer(); })
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
