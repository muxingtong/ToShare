import { Device } from '../models/Device';
import { TransportProtocol, DeviceType, DeviceStatus } from '../models/Enums';
import { ProtocolBadge } from './ProtocolBadge';
import { AppColors } from '../theme/AppColors';

@Component
export struct DeviceCard {
  @Prop device: Device = new Device('', '', '', DeviceType.MOBILE, [], 0, DeviceStatus.ONLINE, 0);

  build() {
    Row() {
      // 左侧：设备图标 + 在线指示
      Stack() {
        // 设备类型图标背景
        Column()
          .width(48)
          .height(48)
          .borderRadius(18)
          .linearGradient({
            angle: 135,
            colors: this.device.status === DeviceStatus.ONLINE ?
              [['#6C5CE7', 0.0], ['#A29BFE', 1.0]] :
              [['#CAC4D0', 0.0], ['#E6E1E5', 1.0]]
          })
          .opacity(this.device.status === DeviceStatus.ONLINE ? 1.0 : 0.5)

        Image($r('app.media.ic_avatar_placeholder'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
          .opacity(this.device.status === DeviceStatus.ONLINE ? 1.0 : 0.5)

        // 在线状态圆点
        if (this.device.status === DeviceStatus.ONLINE) {
          Column()
            .width(12)
            .height(12)
            .borderRadius(6)
            .backgroundColor(AppColors.STATUS_ONLINE)
            .border({ width: 2, color: Color.White })
            .position({ x: 38, y: 38 })
            .shadow({ radius: 4, color: '#4000C9A7' })
        }
      }
      .margin({ right: 14 })

      // 中间：设备信息
      Column() {
        Row() {
          Text(this.device.name)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.device.status === DeviceStatus.ONLINE ?
              AppColors.TEXT_PRIMARY_LIGHT : AppColors.TEXT_SECONDARY_LIGHT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          // 厂商标签（如果有的话）
          if (this.isShareDevice()) {
            Column()
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(6)
              .backgroundColor('#10A29BFE')
              .margin({ left: 6 })
            Text('互传')
              .fontSize(10)
              .fontColor('#6C5CE7')
              .fontWeight(FontWeight.Medium)
          }
        }

        Row() {
          Text(this.getDeviceTypeLabel())
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY_LIGHT)
            .margin({ right: 6 })

          ForEach(this.device.supportedProtocols, (protocol: TransportProtocol) => {
            ProtocolBadge({ protocol: protocol })
              .margin({ right: 4 })
          })

          if (this.device.signalStrength) {
            Text(this.getSignalLabel())
              .fontSize(11)
              .fontColor(AppColors.TEXT_SECONDARY_LIGHT)
              .margin({ left: 4 })
          }
        }
        .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 右侧：快捷发送
      Button() {
        Row() {
          Image($r('sys.symbol.paperplane'))
            .width(14)
            .height(14)
            .fillColor(Color.White)
            .margin({ right: 4 })
          Text('发送')
            .fontSize(12)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
      }
      .linearGradient({
        angle: 135,
        colors: [
          ['#6C5CE7', 0.0],
          ['#A29BFE', 1.0]
        ]
      })
      .borderRadius(16)
      .height(34)
      .padding({ left: 14, right: 14 })
      .shadow({ radius: 6, color: '#306C5CE7', offsetY: 2 })
      .enabled(this.device.status === DeviceStatus.ONLINE)
      .opacity(this.device.status === DeviceStatus.ONLINE ? 1.0 : 0.4)
      .onClick(() => {
        AppStorage.set<Device>('selectedDevice', this.device);
      })
    }
    .padding(16)
    .borderRadius(20)
    .backgroundColor('#F2FFFFFF')
    .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
    .shadow({ radius: 8, color: '#10000000', offsetY: 2 })
  }

  private isShareDevice(): boolean {
    return this.device.supportedProtocols.includes(TransportProtocol.WIFI_DIRECT);
  }

  private getDeviceTypeLabel(): string {
    switch (this.device.type) {
      case DeviceType.MOBILE:
        return '手机';
      case DeviceType.TABLET:
        return '平板';
      case DeviceType.DESKTOP:
        return '电脑';
      default:
        return '设备';
    }
  }

  private getSignalLabel(): string {
    const rssi = this.device.signalStrength;
    if (rssi >= -55) return '📶 强';
    if (rssi >= -75) return '📶 中';
    return '📶 弱';
  }
}
