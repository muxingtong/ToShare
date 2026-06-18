import { TransportProtocol } from '../models/Enums';
import { AppColors } from '../theme/AppColors';

@Component
export struct ProtocolBadge {
  @Prop protocol: TransportProtocol = TransportProtocol.WIFI_DIRECT;

  build() {
    Row() {
      Text(this.getLabel())
        .fontSize(12)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Medium)
    }
    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
    .borderRadius(12)
    .backgroundColor(this.getColor())
  }

  getLabel(): string {
    switch (this.protocol) {
      case TransportProtocol.WIFI_DIRECT:
        return 'WiFi';
      case TransportProtocol.BLUETOOTH:
        return 'BLE';
      case TransportProtocol.NFC:
        return 'NFC';
      default:
        return '';
    }
  }

  getColor(): ResourceColor {
    switch (this.protocol) {
      case TransportProtocol.WIFI_DIRECT:
        return AppColors.WIFI_COLOR;
      case TransportProtocol.BLUETOOTH:
        return AppColors.BLE_COLOR;
      case TransportProtocol.NFC:
        return AppColors.NFC_COLOR;
      default:
        return Color.Gray;
    }
  }
}
