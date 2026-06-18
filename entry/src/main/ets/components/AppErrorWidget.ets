import { AppTheme } from '../theme/AppTheme';
import { AppColors } from '../theme/AppColors';

@Component
export struct AppErrorWidget {
  @Prop title: string = '出错了';
  @Prop message: string = '发生了未知错误';
  @Prop showRetry: boolean = true;
  @Prop onRetry: () => void = () => {};
  @Prop isDark: boolean = false;

  build() {
    Column() {
      Text('\u26A0')
        .fontSize(64)
        .margin({ bottom: 16 })

      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.ERROR)
        .margin({ bottom: 8 })

      Text(this.message)
        .fontSize(14)
        .fontColor(AppTheme.getTextSecondary(this.isDark))
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })

      if (this.showRetry) {
        Button('重试')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor(AppColors.ERROR)
          .borderRadius(20)
          .height(40)
          .padding({ left: 24, right: 24 })
          .onClick(() => {
            this.onRetry();
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(32)
  }
}
