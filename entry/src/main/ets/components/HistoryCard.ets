/**
 * 历史记录卡片——统一主题风格
 */

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
      // ====== 方向图标 ======
      Column()
        .width(44)
        .height(44)
        .borderRadius(16)
        .linearGradient({
          angle: 135,
          colors: this.history.isSender ?
            [['#6C5CE7', 0.0], ['#A29BFE', 1.0]] :
            [['#00A383', 0.0], ['#00C9A7', 1.0]]
        })
        .justifyContent(FlexAlign.Center)
        .margin({ right: 14 })

      // ====== 中间信息 ======
      Column() {
        Text(this.history.peerDeviceName)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.getTextPrimary(this.isDark))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row() {
          Text(this.history.isSender ? '📤 发出' : '📥 收到')
            .fontSize(11)
            .fontColor(AppTheme.getTextSecondary(this.isDark))
            .margin({ right: 8 })

          Text(`${this.history.fileCount} 个文件`)
            .fontSize(11)
            .fontColor(AppTheme.getTextSecondary(this.isDark))
            .margin({ right: 8 })

          Text(FileSizeFormatter.formatSize(this.history.totalSize))
            .fontSize(11)
            .fontColor(AppTheme.getTextSecondary(this.isDark))
        }
        .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // ====== 状态标签 ======
      Text(this.getStatusText())
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getStatusColor())
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .borderRadius(8)
        .backgroundColor(this.getStatusBg())
    }
    .padding(16)
    .borderRadius(20)
    .backgroundColor(AppTheme.frostCardBg(this.isDark))
    .shadow({ radius: 6, color: '#0A000000', offsetY: 1 })
    .margin({ bottom: 8 })
  }

  getStatusText(): string {
    switch (this.history.status) {
      case TransferStatus.COMPLETED:
        return '✓ 已完成';
      case TransferStatus.FAILED:
        return '✗ 失败';
      case TransferStatus.CANCELLED:
        return '○ 已取消';
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
