/**
 * 设置页面——沉浸光效毛玻璃风格
 *
 * 提供:
 * - 设备信息（名称编辑）
 * - 传输偏好（自动接收、通知、协议、续传）
 * - 热点模式（端口配置）
 * - 外观（主题模式切换）
 * - 存储管理（历史保留周期、缓存清除）
 * - 关于（版本、构建号）
 */

import { ThemeModeType, HistoryRetentionDays, TransportProtocol } from '../models/Enums';
import { FileSizeFormatter } from '../utils/FileSizeFormatter';
import { AppColors } from '../theme/AppColors';
import { AppTheme, HeaderGradient } from '../theme/AppTheme';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'SettingsPage';

const PROTOCOL_LABELS: string[] = ['WiFi 直连', '蓝牙', 'NFC'];
const PROTOCOL_VALUES: string[] = [TransportProtocol.WIFI_DIRECT, TransportProtocol.BLUETOOTH, TransportProtocol.NFC];
const RETENTION_LABELS: string[] = ['7 天', '30 天', '90 天', '永久'];
const RETENTION_VALUES: number[] = [
  HistoryRetentionDays.DAYS_7, HistoryRetentionDays.DAYS_30,
  HistoryRetentionDays.DAYS_90, HistoryRetentionDays.PERMANENT
];
const THEME_LABELS: string[] = ['跟随系统', '浅色', '深色'];
const THEME_VALUES: string[] = [ThemeModeType.SYSTEM, ThemeModeType.LIGHT, ThemeModeType.DARK];

@Component
export struct SettingsPage {
  @State isDark: boolean = false;
  @State deviceName: string = '';
  @State autoReceive: boolean = true;
  @State showNotification: boolean = true;
  @State preferredProtocol: number = 0;
  @State enableResume: boolean = true;
  @State themeMode: number = 0;
  @State retentionDays: number = HistoryRetentionDays.DAYS_30;
  @State cacheSize: number = 0;
  @State hotspotPort: string = '24680';
  @State saveHint: string = '';
  private headerGradient: HeaderGradient = new HeaderGradient();

  aboutToAppear(): void {
    this.loadSettings();
  }

  private loadSettings(): void {
    try {
      const saved = AppStorage.get<string>('deviceName');
      if (saved !== undefined && saved !== null && saved.length > 0) {
        this.deviceName = saved;
      } else {
        this.deviceName = '我的设备';
        AppStorage.set<string>('deviceName', this.deviceName);
      }

      const autoRcv = AppStorage.get<boolean>('autoReceive');
      if (autoRcv !== undefined) {
        this.autoReceive = autoRcv;
      }

      const notif = AppStorage.get<boolean>('showNotification');
      if (notif !== undefined) {
        this.showNotification = notif;
      }

      const proto = AppStorage.get<number>('preferredProtocol');
      if (proto !== undefined) {
        this.preferredProtocol = proto;
      }

      const resume = AppStorage.get<boolean>('enableResume');
      if (resume !== undefined) {
        this.enableResume = resume;
      }

      const theme = AppStorage.get<number>('themeMode');
      if (theme !== undefined) {
        this.themeMode = theme;
      }

      const retention = AppStorage.get<number>('retentionDays');
      if (retention !== undefined) {
        this.retentionDays = retention;
      }

      const port = AppStorage.get<string>('hotspotPort');
      if (port !== undefined && port !== null && port.length > 0) {
        this.hotspotPort = port;
      } else {
        this.hotspotPort = '24680';
        AppStorage.set<string>('hotspotPort', this.hotspotPort);
      }
    } catch (err) {
      hilog.info(0x0001, TAG, 'init settings');
      this.deviceName = '我的设备';
    }
  }

  private save(key: string, value: Object): void {
    try {
      AppStorage.set<Object>(key, value);
      this.saveHint = '已保存';
      setTimeout((): void => {
        this.saveHint = '';
      }, 2000);
    } catch (err) {
      hilog.error(0x0001, TAG, 'save failed: %{public}s', JSON.stringify(err));
    }
  }

  private getThemeModeLabel(): string {
    if (this.themeMode >= 0 && this.themeMode < THEME_LABELS.length) {
      return THEME_LABELS[this.themeMode];
    }
    return '跟随系统';
  }

  private getProtocolLabel(): string {
    if (this.preferredProtocol >= 0 && this.preferredProtocol < PROTOCOL_LABELS.length) {
      return PROTOCOL_LABELS[this.preferredProtocol];
    }
    return 'WiFi 直连';
  }

  private getRetentionLabel(): string {
    const idx: number = RETENTION_VALUES.indexOf(this.retentionDays);
    if (idx >= 0) {
      return RETENTION_LABELS[idx];
    }
    return '30 天';
  }

  private clearCache(): void {
    this.cacheSize = 0;
    this.saveHint = '缓存已清除';
    setTimeout((): void => {
      this.saveHint = '';
    }, 2000);
  }

  build() {
    Column() {
      // ====== 标题栏 ======
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
          if (this.saveHint.length > 0) {
            Text(this.saveHint)
              .fontSize(12)
              .fontColor('#CCFFFFFF')
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor('#33FFFFFF')
              .borderRadius(12)
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 4, bottom: 4 })
      }
      .width('100%')
      .height(80)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // ====== 列表 ======
      List() {
        // ———— 设备信息 ————
        ListItem() {
          Column() {
            this.sectionHeader('设备信息', AppColors.PRIMARY)

            Row() {
              Text('设备名称')
                .fontSize(14)
                .fontColor(AppTheme.getTextSecondary(this.isDark))
                .layoutWeight(1)
              TextInput({ placeholder: '输入设备名称', text: this.deviceName })
                .fontSize(14)
                .textAlign(TextAlign.End)
                .width(160)
                .backgroundColor(Color.Transparent)
                .onChange((value: string): void => {
                  this.deviceName = value;
                  this.save('deviceName', value);
                })
            }
            .padding({ top: 6, bottom: 6 })
          }
          .padding(16)
          .borderRadius(18)
          .backgroundColor(AppTheme.frostCardBg(this.isDark))
          .shadow({ radius: 4, color: '#0A000000', offsetY: 1 })
          .margin({ left: 20, right: 20, bottom: 8 })
        }

        // ———— 传输偏好 ————
        ListItem() {
          Column() {
            this.sectionHeader('传输偏好', AppColors.SECONDARY)

            this.settingToggle('自动接收', this.autoReceive, (v: boolean): void => {
              this.autoReceive = v;
              this.save('autoReceive', v);
            })
            this.settingDivider()

            this.settingToggle('传输通知', this.showNotification, (v: boolean): void => {
              this.showNotification = v;
              this.save('showNotification', v);
            })
            this.settingDivider()

            Row() {
              Text('首选协议')
                .fontSize(14)
                .fontColor(AppTheme.getTextSecondary(this.isDark))
                .layoutWeight(1)
              Text(this.getProtocolLabel())
                .fontSize(14)
                .fontColor(AppTheme.getTextPrimary(this.isDark))
            }
            .padding({ top: 12, bottom: 12 })
            .onClick((): void => {
              const next: number = (this.preferredProtocol + 1) % PROTOCOL_VALUES.length;
              this.preferredProtocol = next;
              this.save('preferredProtocol', next);
            })
            this.settingDivider()

            this.settingToggle('断点续传', this.enableResume, (v: boolean): void => {
              this.enableResume = v;
              this.save('enableResume', v);
            })
          }
          .padding(16)
          .borderRadius(18)
          .backgroundColor(AppTheme.frostCardBg(this.isDark))
          .shadow({ radius: 4, color: '#0A000000', offsetY: 1 })
          .margin({ left: 20, right: 20, bottom: 8 })
        }

        // ———— 热点模式 ————
        ListItem() {
          Column() {
            this.sectionHeader('热点模式', AppColors.TERTIARY)

            Row() {
              Text('HTTP 端口')
                .fontSize(14)
                .fontColor(AppTheme.getTextSecondary(this.isDark))
                .layoutWeight(1)
              TextInput({ placeholder: '24680', text: this.hotspotPort })
                .fontSize(14)
                .textAlign(TextAlign.End)
                .width(120)
                .backgroundColor(Color.Transparent)
                .onChange((value: string): void => {
                  this.hotspotPort = value;
                  this.save('hotspotPort', value);
                })
            }
            .padding({ top: 6, bottom: 6 })

            Text('其他设备连接热点后，通过浏览器访问 192.168.43.1:{端口} 传输文件')
              .fontSize(12)
              .fontColor(AppColors.TEXT_TERTIARY_LIGHT)
              .margin({ top: 6 })
          }
          .padding(16)
          .borderRadius(18)
          .backgroundColor(AppTheme.frostCardBg(this.isDark))
          .shadow({ radius: 4, color: '#0A000000', offsetY: 1 })
          .margin({ left: 20, right: 20, bottom: 8 })
        }

        // ———— 外观 ————
        ListItem() {
          Column() {
            this.sectionHeader('外观', AppColors.INFO)

            Row() {
              Text('主题模式')
                .fontSize(14)
                .fontColor(AppTheme.getTextSecondary(this.isDark))
                .layoutWeight(1)
              Text(this.getThemeModeLabel())
                .fontSize(14)
                .fontColor(AppTheme.getTextPrimary(this.isDark))
            }
            .padding({ top: 6, bottom: 6 })
            .onClick((): void => {
              this.themeMode = (this.themeMode + 1) % THEME_VALUES.length;
              this.save('themeMode', this.themeMode);
            })
          }
          .padding(16)
          .borderRadius(18)
          .backgroundColor(AppTheme.frostCardBg(this.isDark))
          .shadow({ radius: 4, color: '#0A000000', offsetY: 1 })
          .margin({ left: 20, right: 20, bottom: 8 })
        }

        // ———— 存储管理 ————
        ListItem() {
          Column() {
            this.sectionHeader('存储管理', AppColors.SUCCESS)

            Row() {
              Text('历史记录保留')
                .fontSize(14)
                .fontColor(AppTheme.getTextSecondary(this.isDark))
                .layoutWeight(1)
              Text(this.getRetentionLabel())
                .fontSize(14)
                .fontColor(AppTheme.getTextPrimary(this.isDark))
            }
            .padding({ top: 6, bottom: 6 })
            .onClick((): void => {
              const currentIdx: number = RETENTION_VALUES.indexOf(this.retentionDays);
              const nextIdx: number = (currentIdx + 1) % RETENTION_VALUES.length;
              this.retentionDays = RETENTION_VALUES[nextIdx];
              this.save('retentionDays', this.retentionDays);
            })
            this.settingDivider()

            Row() {
              Text('缓存大小')
                .fontSize(14)
                .fontColor(AppTheme.getTextSecondary(this.isDark))
                .layoutWeight(1)
              Text(FileSizeFormatter.formatSize(this.cacheSize))
                .fontSize(14)
                .fontColor(AppColors.TEXT_TERTIARY_LIGHT)
                .margin({ right: 8 })
              Button('清除')
                .fontSize(12)
                .fontColor(AppColors.ERROR)
                .backgroundColor('#12' + AppColors.ERROR.substring(1))
                .borderRadius(14)
                .height(28)
                .padding({ left: 14, right: 14 })
                .onClick((): void => { this.clearCache(); })
            }
            .padding({ top: 6, bottom: 6 })
          }
          .padding(16)
          .borderRadius(18)
          .backgroundColor(AppTheme.frostCardBg(this.isDark))
          .shadow({ radius: 4, color: '#0A000000', offsetY: 1 })
          .margin({ left: 20, right: 20, bottom: 8 })
        }

        // ———— 关于 ————
        ListItem() {
          Column() {
            this.sectionHeader('关于', AppColors.PRIMARY_LIGHT)

            Row() {
              Text('应用版本')
                .fontSize(14)
                .fontColor(AppTheme.getTextSecondary(this.isDark))
                .layoutWeight(1)
              Text('1.1.0')
                .fontSize(14)
                .fontColor(AppTheme.getTextPrimary(this.isDark))
            }
            .padding({ top: 4, bottom: 4 })
            this.settingDivider()

            Row() {
              Text('构建版本')
                .fontSize(14)
                .fontColor(AppTheme.getTextSecondary(this.isDark))
                .layoutWeight(1)
              Text('2026.6')
                .fontSize(14)
                .fontColor(AppTheme.getTextPrimary(this.isDark))
            }
            .padding({ top: 4, bottom: 4 })
            this.settingDivider()

            Row() {
              Text('界面引擎')
                .fontSize(14)
                .fontColor(AppTheme.getTextSecondary(this.isDark))
                .layoutWeight(1)
              Text('HarmonyOS ArkUI')
                .fontSize(14)
                .fontColor(AppTheme.getTextPrimary(this.isDark))
            }
            .padding({ top: 4, bottom: 4 })
            this.settingDivider()

            Row() {
              Text('开源协议')
                .fontSize(14)
                .fontColor(AppTheme.getTextSecondary(this.isDark))
                .layoutWeight(1)
              Text('MIT')
                .fontSize(14)
                .fontColor(AppTheme.getTextPrimary(this.isDark))
            }
            .padding({ top: 4, bottom: 4 })
          }
          .padding(16)
          .borderRadius(18)
          .backgroundColor(AppTheme.frostCardBg(this.isDark))
          .shadow({ radius: 4, color: '#0A000000', offsetY: 1 })
          .margin({ left: 20, right: 20, bottom: 8 })
        }

        // 底部占位
        ListItem() {
          Row()
            .width('100%')
            .height(20)
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.getBackground(this.isDark))
  }

  @Builder
  sectionHeader(label: string, accentColor: ResourceColor) {
    Row() {
      Row()
        .width(4)
        .height(16)
        .borderRadius(2)
        .backgroundColor(accentColor)
        .margin({ right: 8 })
      Text(label)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.getTextPrimary(this.isDark))
    }
    .width('100%')
    .margin({ bottom: 8 })
  }

  @Builder
  settingToggle(label: string, isOn: boolean, onChange: (v: boolean) => void) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(AppTheme.getTextSecondary(this.isDark))
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .onChange(onChange)
    }
    .padding({ top: 10, bottom: 10 })
  }

  @Builder
  settingDivider() {
    Row()
      .width('100%')
      .height(1)
      .backgroundColor(AppColors.DIVIDER_LIGHT)
      .margin({ left: 4, right: 4 })
  }
}
