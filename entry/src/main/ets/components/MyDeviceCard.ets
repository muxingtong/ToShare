import { AppTheme } from '../theme/AppTheme';
import { AppColors } from '../theme/AppColors';

@Component
export struct MyDeviceCard {
  @Prop deviceName: string = '我的设备';
  @Prop isBroadcasting: boolean = false;

  build() {
    Column() {
      Row() {
        // 设备头像 —— 渐变圆形 + 符号图标
        Stack() {
          Column()
            .width(56)
            .height(56)
            .borderRadius(28)
            .linearGradient({
              angle: 135,
              colors: [
                ['#6C5CE7', 0.0],
                ['#A29BFE', 1.0]
              ]
            })
            .shadow({ radius: 12, color: '#406C5CE7' })

          Image($r('app.media.ic_device'))
            .width(30)
            .height(30)
            .fillColor(Color.White)

          // 广播状态指示器
          if (this.isBroadcasting) {
            Column()
              .width(16)
              .height(16)
              .borderRadius(8)
              .backgroundColor(AppColors.STATUS_ONLINE)
              .border({ width: 2.5, color: Color.White })
              .position({ x: 42, y: 42 })
              .shadow({ radius: 4, color: '#4000C9A7' })
          }
        }
        .margin({ right: 14 })

        // 设备信息
        Column() {
          Text(this.deviceName)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY_LIGHT)

          Row() {
            Text(this.isBroadcasting ? '● 互传广播已开启' : '○ 未广播')
              .fontSize(12)
              .fontColor(this.isBroadcasting ? '#00A383' : AppColors.TEXT_SECONDARY_LIGHT)
              .fontWeight(FontWeight.Medium)
          }
          .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        // 右侧操作区
        Column() {
          // 二维码入口
          Row() {
            Image($r('sys.symbol.qrcode'))
              .width(22)
              .height(22)
              .fillColor('#6C5CE7')
          }
          .width(44)
          .height(44)
          .borderRadius(22)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#E8FFFFFF')
          .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
          .onClick(() => {
            AppStorage.set<string>('showQrCode', 'true');
          })

          Text('二维码')
            .fontSize(10)
            .fontColor(AppColors.TEXT_SECONDARY_LIGHT)
            .margin({ top: 4 })
        }
      }
      .width('100%')
    }
    .padding(18)
    .borderRadius(24)
    .backgroundColor('#F4FFFFFF')
    .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
    .shadow({ radius: 14, color: '#14000000', offsetY: 4 })
  }
}
