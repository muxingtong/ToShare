import { ThemeModeType, HistoryRetentionDays } from '../models/Enums';
import { FileSizeFormatter } from '../utils/FileSizeFormatter';
import { AppColors } from '../theme/AppColors';
import { HeaderGradient } from '../theme/AppTheme';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Component
export struct SettingsPage {
  @State deviceName: string = '我的设备';
  @State autoReceive: boolean = true;
  @State showNotification: boolean = true;
  @State preferredProtocol: number = 0;
  @State enableResume: boolean = true;
  @State themeMode: number = 0;
  @State retentionDays: number = 30;
  @State cacheSize: number = 0;
  @State isDark: boolean = false;
  private headerGradient: HeaderGradient = new HeaderGradient();

  private protocols: string[] = ['WiFi直连', '蓝牙', 'NFC'];
  private retentionOptions: number[] = [7, 30, 90, -1];
  private retentionLabels: string[] = ['7天', '30天', '90天', '永久'];

  aboutToAppear(): void {
    try {
      const savedName = AppStorage.get<string>('deviceName');
      if (savedName) {
        this.deviceName = savedName;
      }
    } catch (err) {
      hilog.info(0x0001, 'ToShare', 'No saved settings');
    }
  }

  saveDeviceName(): void {
    AppStorage.set<string>('deviceName', this.deviceName);
  }

  clearCache(): void {
    this.cacheSize = 0;
  }

  build() {
    Column() {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .linearGradient({
            angle: this.headerGradient.angle,
            colors: this.headerGradient.colors
          })
        Row() {
          Text('设置')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Blank()
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 4, bottom: 4 })
      }
      .width('100%')
      .height(80)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      List() {
        // 设备信息
        ListItem() {
          Column() {
            Text('设备信息')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1B1F')
              .width('100%')
              .margin({ bottom: 10 })

            Row() {
              Text('设备名称')
                .fontSize(14)
                .fontColor('#625B71')
                .layoutWeight(1)
              TextInput({ placeholder: '输入设备名称', text: this.deviceName })
                .fontSize(14)
                .textAlign(TextAlign.End)
                .width(160)
                .onChange((value: string) => {
                  this.deviceName = value;
                  this.saveDeviceName();
                })
            }
          }
          .padding(16)
          .borderRadius(18)
          .backgroundColor('#F2FFFFFF')
          .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
          .shadow({ radius: 4, color: '#0A000000', offsetY: 1 })
          .margin({ left: 20, right: 20, bottom: 8 })
        }

        // 传输偏好
        ListItem() {
          Column() {
            Text('传输偏好')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1B1F')
              .width('100%')
              .margin({ bottom: 10 })

            this.settingToggle('自动接收', this.autoReceive, (v) => { this.autoReceive = v; })
            this.settingToggle('传输通知', this.showNotification, (v) => { this.showNotification = v; })

            Row() {
              Text('首选协议')
                .fontSize(14)
                .fontColor('#625B71')
                .layoutWeight(1)
              Select([{ value: 'WiFi直连' }, { value: '蓝牙' }, { value: 'NFC' }])
                .font({ size: 14 })
                .onSelect((index: number) => { this.preferredProtocol = index; })
            }
            .padding({ top: 10, bottom: 10 })

            this.settingToggle('断点续传', this.enableResume, (v) => { this.enableResume = v; })
          }
          .padding(16)
          .borderRadius(18)
          .backgroundColor('#F2FFFFFF')
          .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
          .shadow({ radius: 4, color: '#0A000000', offsetY: 1 })
          .margin({ left: 20, right: 20, bottom: 8 })
        }

        // 外观
        ListItem() {
          Column() {
            Text('外观')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1B1F')
              .width('100%')
              .margin({ bottom: 10 })

            Row() {
              Text('主题模式')
                .fontSize(14)
                .fontColor('#625B71')
                .layoutWeight(1)
              Select([{ value: '跟随系统' }, { value: '浅色' }, { value: '深色' }])
                .font({ size: 14 })
                .onSelect((index: number) => { this.themeMode = index; })
            }
            .padding({ top: 10, bottom: 10 })
          }
          .padding(16)
          .borderRadius(18)
          .backgroundColor('#F2FFFFFF')
          .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
          .shadow({ radius: 4, color: '#0A000000', offsetY: 1 })
          .margin({ left: 20, right: 20, bottom: 8 })
        }

        // 存储管理
        ListItem() {
          Column() {
            Text('存储管理')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1B1F')
              .width('100%')
              .margin({ bottom: 10 })

            Row() {
              Text('历史记录保留')
                .fontSize(14)
                .fontColor('#625B71')
                .layoutWeight(1)
              Select([{ value: '7天' }, { value: '30天' }, { value: '90天' }, { value: '永久' }])
                .font({ size: 14 })
                .onSelect((index: number) => { this.retentionDays = this.retentionOptions[index]; })
            }
            .padding({ top: 10, bottom: 10 })

            Row() {
              Text('缓存大小')
                .fontSize(14)
                .fontColor('#625B71')
                .layoutWeight(1)
              Text(FileSizeFormatter.formatSize(this.cacheSize))
                .fontSize(14)
                .fontColor('#625B71')
                .margin({ right: 8 })
              Button('清除')
                .fontSize(12)
                .fontColor('#FF6B6B')
                .backgroundColor('#12FF6B6B')
                .borderRadius(14)
                .height(28)
                .padding({ left: 14, right: 14 })
                .onClick(() => { this.clearCache(); })
            }
            .padding({ top: 10, bottom: 10 })
          }
          .padding(16)
          .borderRadius(18)
          .backgroundColor('#F2FFFFFF')
          .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
          .shadow({ radius: 4, color: '#0A000000', offsetY: 1 })
          .margin({ left: 20, right: 20, bottom: 8 })
        }

        // 关于
        ListItem() {
          Column() {
            Text('关于')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1B1F')
              .width('100%')
              .margin({ bottom: 10 })

            Row() {
              Text('应用版本')
                .fontSize(14)
                .fontColor('#625B71')
                .layoutWeight(1)
              Text('1.0.0')
                .fontSize(14)
                .fontColor('#625B71')
            }
            .padding({ top: 4, bottom: 4 })

            Row() {
              Text('构建版本')
                .fontSize(14)
                .fontColor('#625B71')
                .layoutWeight(1)
              Text('2024.1')
                .fontSize(14)
                .fontColor('#625B71')
            }
            .padding({ top: 4, bottom: 4 })
          }
          .padding(16)
          .borderRadius(18)
          .backgroundColor('#F2FFFFFF')
          .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
          .shadow({ radius: 4, color: '#0A000000', offsetY: 1 })
          .margin({ left: 20, right: 20, bottom: 8 })
        }

        // 底部占位
        ListItem() {
          Row()
            .width('100%')
            .height(80)
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0EFF5')
  }

  @Builder
  settingToggle(label: string, isOn: boolean, onChange: (v: boolean) => void) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#625B71')
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .onChange(onChange)
    }
    .padding({ top: 10, bottom: 10 })
  }

  getRetentionLabel(): string {
    const idx = this.retentionOptions.indexOf(this.retentionDays);
    return idx >= 0 ? this.retentionLabels[idx] : '30天';
  }
}
