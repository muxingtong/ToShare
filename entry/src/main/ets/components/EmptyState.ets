/**
 * 空状态组件——统一主题适配
 * 沉浸光效毛玻璃风格
 */

import { AppTheme } from '../theme/AppTheme';
import { AppColors } from '../theme/AppColors';

@Component
export struct EmptyState {
  @Prop icon: string = '\uD83D\uDCC1';
  @Prop title: string = '暂无数据';
  @Prop subtitle: string = '';
  @Prop showAction: boolean = false;
  @Prop actionText: string = '';
  @Prop actionColor: ResourceColor = AppColors.PRIMARY;
  @Prop isDark: boolean = false;

  build() {
    Column() {
      // 图标区
      Column()
        .width(80)
        .height(80)
        .borderRadius(40)
        .backgroundColor('#12' + AppColors.PRIMARY.substring(1))
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 20 })
      Text(this.icon)
        .fontSize(36)

      // 标题
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.getTextPrimary(this.isDark))
        .margin({ bottom: 8 })

      // 副标题
      if (this.subtitle !== '') {
        Text(this.subtitle)
          .fontSize(13)
          .fontColor(AppTheme.getTextSecondary(this.isDark))
          .textAlign(TextAlign.Center)
          .margin({ bottom: 20 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      // 操作按钮
      if (this.showAction && this.actionText !== '') {
        Button(this.actionText)
          .fontSize(14)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.actionColor)
          .borderRadius(20)
          .height(40)
          .padding({ left: 28, right: 28 })
          .shadow({ radius: 8, color: '#30' + this.actionColor.toString().substring(1), offsetY: 2 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(32)
  }
}
