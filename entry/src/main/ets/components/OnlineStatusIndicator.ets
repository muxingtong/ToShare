import { DeviceStatus } from '../models/Enums';

@Component
export struct OnlineStatusIndicator {
  @Prop status: DeviceStatus = DeviceStatus.ONLINE;
  @Prop indicatorSize: number = 10;

  build() {
    Circle({ width: this.indicatorSize, height: this.indicatorSize })
      .fill(this.getStatusColor())
      .margin({ right: 6 })
  }

  getStatusColor(): ResourceColor {
    switch (this.status) {
      case DeviceStatus.ONLINE:
        return Color.Green;
      case DeviceStatus.AWAY:
        return Color.Orange;
      case DeviceStatus.OFFLINE:
        return Color.Gray;
      default:
        return Color.Gray;
    }
  }
}
