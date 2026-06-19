/**
 * 传输进度环——渐变色彩，沉浸光效
 */

import { TransferStatus } from '../models/Enums';
import { AppColors } from '../theme/AppColors';
import { AppTheme } from '../theme/AppTheme';

@Component
export struct TransferProgressRing {
  @Prop progress: number = 0;
  @Prop status: TransferStatus = TransferStatus.IDLE;
  @Prop ringSize: number = 100;
  @Prop strokeWidth: number = 8;
  @Prop isDark: boolean = false;

  build() {
    Stack() {
      // 底层辉光
      Column()
        .width(this.ringSize + 20)
        .height(this.ringSize + 20)
        .borderRadius((this.ringSize + 20) / 2)
        .backgroundColor(this.getGlowColor())
        .blur(20)
        .opacity(0.3)

      // 环形进度
      Progress({
        value: this.progress * 100,
        total: 100,
        type: ProgressType.Ring
      })
        .width(this.ringSize)
        .height(this.ringSize)
        .color(this.getProgressColor())
        .style({ strokeWidth: this.strokeWidth })

      // 中央内容
      Column() {
        Text(this.getCenterIcon())
          .fontSize(24)
          .margin({ bottom: 2 })

        // 传输中显示百分比
        if (this.status === TransferStatus.TRANSFERRING || this.status === TransferStatus.PAUSED) {
          Text(`${Math.round(this.progress * 100)}%`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppTheme.getTextPrimary(this.isDark))
        }
      }
    }
    .width(this.ringSize + 20)
    .height(this.ringSize + 20)
  }

  getProgressColor(): ResourceColor {
    switch (this.status) {
      case TransferStatus.COMPLETED:
        return AppColors.SUCCESS;
      case TransferStatus.FAILED:
      case TransferStatus.CANCELLED:
        return AppColors.ERROR;
      case TransferStatus.PAUSED:
        return AppColors.WARNING;
      default:
        return AppColors.PRIMARY;
    }
  }

  getGlowColor(): ResourceColor {
    switch (this.status) {
      case TransferStatus.COMPLETED:
        return AppColors.SUCCESS;
      case TransferStatus.FAILED:
      case TransferStatus.CANCELLED:
        return AppColors.ERROR;
      case TransferStatus.PAUSED:
        return AppColors.WARNING;
      default:
        return AppColors.PRIMARY;
    }
  }

  getCenterIcon(): string {
    switch (this.status) {
      case TransferStatus.COMPLETED:
        return '✅';
      case TransferStatus.FAILED:
        return '❌';
      case TransferStatus.PAUSED:
        return '⏸️';
      case TransferStatus.CANCELLED:
        return '🚫';
      default:
        return '';
    }
  }
}
