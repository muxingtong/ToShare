import { AppTheme } from '../theme/AppTheme';

@Component
export struct EmptyState {
  @Prop icon: string = '\uD83D\uDCC1';
  @Prop title: string = '暂无数据';
  @Prop subtitle: string = '';
  @Prop showAction: boolean = false;
  @Prop actionText: string = '';
  @Prop isDark: boolean = false;

  build() {
    Column() {
      Text(this.icon)
        .fontSize(64)
        .margin({ bottom: 16 })

      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppTheme.getTextPrimary(this.isDark))
        .margin({ bottom: 8 })

      if (this.subtitle !== '') {
        Text(this.subtitle)
          .fontSize(14)
          .fontColor(AppTheme.getTextSecondary(this.isDark))
          .textAlign(TextAlign.Center)
          .margin({ bottom: 16 })
      }

      if (this.showAction && this.actionText !== '') {
        Button(this.actionText)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#3F51B5')
          .borderRadius(20)
          .height(40)
          .padding({ left: 24, right: 24 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(32)
  }
}
