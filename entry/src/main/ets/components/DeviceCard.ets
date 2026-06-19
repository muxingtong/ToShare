/**
 * 设备卡片——统一主题风格
 * 沉浸光效毛玻璃风格，设备列表展示
 */

import { Device } from '../models/Device';
import { TransportProtocol, DeviceType, DeviceStatus } from '../models/Enums';
import { ShareVendor } from '../utils/ShareProtocol';
import { ProtocolBadge } from './ProtocolBadge';
import { AppTheme } from '../theme/AppTheme';
import { AppColors } from '../theme/AppColors';

@Component
export struct DeviceCard {
  @Prop device: Device = new Device('', '', ShareVendor.UNKNOWN, '', DeviceType.MOBILE, [], 0, DeviceStatus.ONLINE, 0);
  @Prop isDark: boolean = false;

  build() {
    Row() {
      // ====== 左侧：设备图标 + 在线指示 ======
      Stack() {
        // 设备类型图标背景
        Column()
          .width(50)
          .height(50)
          .borderRadius(18)
          .linearGradient({
            angle: 135,
            colors: this.device.status === DeviceStatus.ONLINE ?
              [['#6C5CE7', 0.0], ['#A29BFE', 1.0]] :
              [['#CAC4D0', 0.0], ['#E6E1E5', 1.0]]
          })
          .opacity(this.device.status === DeviceStatus.ONLINE ? 1.0 : 0.5)

        Image($r('app.media.ic_avatar_placeholder'))
          .width(26)
          .height(26)
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
            .position({ x: 39, y: 39 })
            .shadow({ radius: 4, color: '#4000C9A7' })
        }
      }
      .margin({ right: 14 })

      // ====== 中间：设备信息 ======
      Column() {
        // 第一行：名称 + 厂商标签
        Row() {
          Text(this.device.displayName)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.device.status === DeviceStatus.ONLINE ?
              AppTheme.getTextPrimary(this.isDark) : AppTheme.getTextSecondary(this.isDark))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.device.vendor !== ShareVendor.UNKNOWN) {
            Text(this.getVendorLabel())
              .fontSize(10)
              .fontColor(AppColors.PRIMARY)
              .fontWeight(FontWeight.Medium)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor('#12' + AppColors.PRIMARY.substring(1))
              .borderRadius(6)
              .margin({ left: 6 })
          }
        }

        // 第二行：设备类型 + 协议 + 信号
        Row() {
          Text(this.getDeviceTypeLabel())
            .fontSize(12)
            .fontColor(AppTheme.getTextSecondary(this.isDark))
            .margin({ right: 6 })

          ForEach(this.device.supportedProtocols, (protocol: TransportProtocol) => {
            ProtocolBadge({ protocol: protocol })
              .margin({ right: 4 })
          })

          if (this.device.signalStrength > 0) {
            Text(this.getSignalLabel())
              .fontSize(11)
              .fontColor(AppTheme.getTextSecondary(this.isDark))
              .margin({ left: 4 })
          }
        }
        .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // ====== 右侧：发送按钮 ======
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
        colors: [['#6C5CE7', 0.0], ['#A29BFE', 1.0]]
      })
      .borderRadius(16)
      .height(34)
      .padding({ left: 14, right: 14 })
      .shadow({ radius: 6, color: '#306C5CE7', offsetY: 2 })
      .enabled(this.device.status === DeviceStatus.ONLINE)
      .opacity(this.device.status === DeviceStatus.ONLINE ? 1.0 : 0.35)
      .onClick(() => {
        AppStorage.set<Device>('selectedDevice', this.device);
      })
    }
    .padding(16)
    .borderRadius(20)
    .backgroundColor(AppTheme.frostCardBg(this.isDark))
    .shadow({ radius: 8, color: '#10000000', offsetY: 2 })
  }

  private getVendorLabel(): string {
    if (this.device.vendor === ShareVendor.OPPO) {
      return 'OPPO互传';
    }
    if (this.device.vendor === ShareVendor.XIAOMI) {
      return '小米互传';
    }
    if (this.device.vendor === ShareVendor.VIVO) {
      return 'VIVO互传';
    }
    if (this.device.vendor === ShareVendor.HUAWEI) {
      return '华为分享';
    }
    if (this.device.vendor === ShareVendor.SAMSUNG) {
      return '三星互传';
    }
    return '互传';
  }

  private getDeviceTypeLabel(): string {
    switch (this.device.type) {
      case DeviceType.MOBILE:
        return '📱 手机';
      case DeviceType.TABLET:
        return '📱 平板';
      case DeviceType.DESKTOP:
        return '💻 电脑';
      default:
        return '设备';
    }
  }

  private getSignalLabel(): string {
    const rssi = this.device.signalStrength;
    if (rssi >= -55) {
      return '📶 强';
    }
    if (rssi >= -75) {
      return '📶 中';
    }
    return '📶 弱';
  }
}
