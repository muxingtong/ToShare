import { TransferStatus } from '../models/Enums';
import { AppColors } from '../theme/AppColors';

@Component
export struct TransferProgressRing {
  @Prop progress: number = 0;
  @Prop status: TransferStatus = TransferStatus.IDLE;
  @Prop ringSize: number = 80;
  @Prop strokeWidth: number = 6;

  build() {
    Stack() {
      Progress({
        value: this.progress * 100,
        total: 100,
        type: ProgressType.Ring
      })
        .width(this.ringSize)
        .height(this.ringSize)
        .color(this.getProgressColor())
        .style({ strokeWidth: this.strokeWidth })

      Column() {
        Text(`${Math.round(this.progress * 100)}%`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        if (this.getStatusIcon() !== '') {
          Text(this.getStatusIcon())
            .fontSize(16)
        }
      }
    }
    .width(this.ringSize)
    .height(this.ringSize)
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

  getStatusIcon(): string {
    switch (this.status) {
      case TransferStatus.COMPLETED:
        return '\u2713';
      case TransferStatus.FAILED:
        return '\u2717';
      case TransferStatus.PAUSED:
        return '\u23F8';
      default:
        return '';
    }
  }
}
