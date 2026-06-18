import { TransferHistory } from '../models/TransferSession';
import { TransferStatus } from '../models/Enums';
import { FileSizeFormatter } from '../utils/FileSizeFormatter';
import { AppTheme } from '../theme/AppTheme';
import { AppColors } from '../theme/AppColors';

@Component
export struct HistoryCard {
  @Prop history: TransferHistory = new TransferHistory('', '', true, 0, 0, 0, TransferStatus.COMPLETED, []);
  @Prop isDark: boolean = false;

  build() {
    Row() {
      Column()
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor(this.history.isSender ? '#126C5CE7' : '#1200C9A7')
        .justifyContent(FlexAlign.Center)
        .margin({ right: 12 })

      Column() {
        Text(this.history.peerDeviceName)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.getTextPrimary(this.isDark))
        Text(`${this.history.fileCount}个文件 · ${FileSizeFormatter.formatSize(this.history.totalSize)}`)
          .fontSize(13)
          .fontColor(AppTheme.getTextSecondary(this.isDark))
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(this.getStatusText())
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getStatusColor())
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .borderRadius(10)
        .backgroundColor(this.getStatusBg())
    }
    .padding(16)
    .borderRadius(18)
    .backgroundColor('#F2FFFFFF')
    .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
    .shadow({ radius: 4, color: '#0A000000', offsetY: 1 })
    .margin({ bottom: 8 })
  }

  getStatusText(): string {
    switch (this.history.status) {
      case TransferStatus.COMPLETED:
        return '已完成';
      case TransferStatus.FAILED:
        return '失败';
      case TransferStatus.CANCELLED:
        return '已取消';
      default:
        return '';
    }
  }

  getStatusColor(): ResourceColor {
    switch (this.history.status) {
      case TransferStatus.COMPLETED:
        return '#00A383';
      case TransferStatus.FAILED:
        return '#FF6B6B';
      case TransferStatus.CANCELLED:
        return '#FF9F43';
      default:
        return '#9E9E9E';
    }
  }

  getStatusBg(): ResourceColor {
    switch (this.history.status) {
      case TransferStatus.COMPLETED:
        return '#1000C9A7';
      case TransferStatus.FAILED:
        return '#10FF6B6B';
      case TransferStatus.CANCELLED:
        return '#10FF9F43';
      default:
        return '#109E9E9E';
    }
  }
}
