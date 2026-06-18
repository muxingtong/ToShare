import { DeviceDiscoveryService, DeviceDiscoveryCallback } from '../services/DeviceDiscoveryService';
import { ShareBroadcastService, BroadcastStatus, BroadcastStatusCallback } from '../services/ShareBroadcastService';
import { FileTransferService, TransferState, TransferStatusCallback } from '../services/FileTransferService';
import { Device } from '../models/Device';
import { DeviceDiscoveryStatus } from '../models/Enums';
import { DeviceCard } from '../components/DeviceCard';
import { MyDeviceCard } from '../components/MyDeviceCard';
import { SendPage } from './SendPage';
import { ReceivePage } from './ReceivePage';
import { HistoryPage } from './HistoryPage';
import { SettingsPage } from './SettingsPage';
import { AppTheme, HeaderGradient, BrandGradient, WarmGradient } from '../theme/AppTheme';
import { AppColors } from '../theme/AppColors';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { picker } from '@kit.CoreFileKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { HdsTabs, HdsTabsController, hdsMaterial } from '@kit.UIDesignKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';

@Entry
@Component
struct HomePage {
  @State devices: Device[] = [];
  @State isScanning: boolean = false;
  @State isBroadcasting: boolean = false;
  @State broadcastError: string = '';
  @State myDeviceName: string = '我的设备';
  @State isDark: boolean = false;
  @State transferStatus: TransferState = TransferState.IDLE;
  @State transferMessage: string = '';
  @State showTransferPanel: boolean = false;
  @State animScanPulse: number = 1;
  private tabsController: HdsTabsController = new HdsTabsController();
  private discoveryService: DeviceDiscoveryService = DeviceDiscoveryService.getInstance();
  private broadcastService: ShareBroadcastService = ShareBroadcastService.getInstance();
  private transferService: FileTransferService = FileTransferService.getInstance();
  @State materialLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.ADAPTIVE;

  aboutToAppear(): void {
    this.loadMyDeviceName();
    this.discoveryService.addListener(this.onDevicesDiscovered);
    this.broadcastService.addListener(this.onBroadcastStatusChange);
    this.transferService.addListener(this.onTransferStatusChange);

    const materialTypes = hdsMaterial.getSystemMaterialTypes();
    if (materialTypes.indexOf(hdsMaterial.MaterialType.IMMERSIVE) < 0) {
      this.materialLevel = hdsMaterial.MaterialLevel.SMOOTH;
    }
  }

  aboutToDisappear(): void {
    this.discoveryService.removeListener(this.onDevicesDiscovered);
    this.broadcastService.removeListener(this.onBroadcastStatusChange);
    this.transferService.removeListener(this.onTransferStatusChange);
    if (this.isScanning) {
      this.discoveryService.stopDiscovery();
    }
  }

  private onDevicesDiscovered: DeviceDiscoveryCallback = (devices: Device[]) => {
    this.devices = devices;
    if (this.discoveryService.status !== DeviceDiscoveryStatus.SCANNING) {
      this.isScanning = false;
    }
  };

  private onBroadcastStatusChange: BroadcastStatusCallback =
    new BroadcastStatusCallback((status: BroadcastStatus, message?: string) => {
    this.isBroadcasting = status === BroadcastStatus.BROADCASTING || status === BroadcastStatus.STARTING;
    if (status === BroadcastStatus.ERROR) {
      this.broadcastError = message || '广播启动失败';
      setTimeout(() => { this.broadcastError = ''; }, 4000);
    } else {
      this.broadcastError = '';
    }
  });

  private onTransferStatusChange: TransferStatusCallback =
    new TransferStatusCallback((state: TransferState, message?: string) => {
    this.transferStatus = state;
    this.transferMessage = message || '';
    if (state === TransferState.IDLE || state === TransferState.COMPLETED || state === TransferState.ERROR) {
      setTimeout(() => { this.showTransferPanel = false; }, 3000);
    }
  });

  loadMyDeviceName(): void {
    try {
      const saved = AppStorage.get<string>('deviceName');
      if (saved) {
        this.myDeviceName = saved;
      }
    } catch (err) {
      hilog.info(0x0001, 'ToShare', 'No saved device name');
    }
  }

  toggleScan(): void {
    if (this.isScanning) {
      this.discoveryService.stopDiscovery();
      this.isScanning = false;
      this.devices = [];
    } else {
      this.discoveryService.startDiscovery();
      this.isScanning = true;
    }
  }

  toggleBroadcast(): void {
    if (this.isBroadcasting) {
      this.broadcastService.stopBroadcast();
    } else {
      this.requestBluetoothPermissionAndBroadcast();
    }
  }

  private async requestBluetoothPermissionAndBroadcast(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const permissions: Array<Permissions> = [
      'ohos.permission.ACCESS_BLUETOOTH',
      'ohos.permission.USE_BLUETOOTH'
    ];
    const atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(context, permissions).then(async (data) => {
      if (data.authResults.length >= 2 &&
        data.authResults[0] === 0 && data.authResults[1] === 0) {
        this.broadcastService.setDeviceName(this.myDeviceName);
        await this.broadcastService.startBroadcast();
      } else {
        this.broadcastError = '需要蓝牙权限才能开启广播';
        setTimeout(() => { this.broadcastError = ''; }, 3000);
      }
    }).catch((err: Error) => {
      this.broadcastError = `权限请求失败: ${err.message}`;
      setTimeout(() => { this.broadcastError = ''; }, 3000);
    });
  }

  async sendImageToDevice(device: Device): Promise<void> {
    try {
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      const photoPicker = new picker.PhotoViewPicker();
      const result = await photoPicker.select(photoSelectOptions);
      if (result.photoUris.length === 0) {
        return;
      }
      const fileUri = result.photoUris[0];
      const fileName = fileUri.split('/').pop() || 'image.jpg';
      if (!this.isBroadcasting) {
        this.requestBluetoothPermissionAndBroadcast();
        await this.delay(1000);
      }
      this.showTransferPanel = true;
      this.transferService.startAsSender(fileUri, fileName);
    } catch (err) {
      hilog.error(0x0001, 'ToShare', 'Select photo failed: %{public}s', JSON.stringify(err));
    }
  }

  private delay(ms: number): Promise<void> {
    return new Promise<void>((resolve) => { setTimeout(resolve, ms); });
  }

  @Builder
  homeTabContent() {
    Column() {
      // 头部区域
      this.buildHeader();

      Scroll() {
        Column() {
          // 我的设备卡片
          MyDeviceCard({
            deviceName: this.myDeviceName,
            isBroadcasting: this.isBroadcasting
          })
            .margin({ left: 16, right: 16, top: 16, bottom: 0 })

          // 操作卡片区 —— 核心交互
          this.buildActionCards()

          // 错误提示卡片
          if (this.broadcastError !== '') {
            this.buildErrorCard()
          }

          // 传输状态卡片
          if (this.showTransferPanel) {
            this.buildTransferCard()
          }

          // 设备列表区域
          this.buildDeviceList()
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
  }

  // ─── Header ─────────────────────────────────────────────
  @Builder
  buildHeader() {
    Stack() {
      // 渐变背景
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            ['#2D1B69', 0.0],
            ['#4834D4', 0.4],
            ['#6C5CE7', 0.75],
            ['#A29BFE', 1.0]
          ]
        })

      // 装饰光点
      Column()
        .width(100)
        .height(100)
        .borderRadius(50)
        .backgroundColor('#10FFFFFF')
        .position({ x: -30, y: -20 })

      Column()
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('#15FFFFFF')
        .position({ x: '80%', y: 20 })

      // 标题
      Row() {
        Image($r('sys.symbol.paperplane_fill'))
          .width(28)
          .height(28)
          .fillColor(Color.White)
          .margin({ right: 10 })
          .shadow({ radius: 8, color: '#40000000' })

        Column() {
          Text('ToShare')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .letterSpacing(1)
            .shadow({ radius: 4, color: '#30000000' })
          Text('跨平台文件互传')
            .fontSize(11)
            .fontColor('#C8C0FF')
            .letterSpacing(2)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        // 场景指示器
        Row() {
          Column()
            .width(7)
            .height(7)
            .borderRadius(4)
            .backgroundColor(this.isBroadcasting ?
              AppColors.STATUS_ONLINE : AppColors.STATUS_OFFLINE)
            .margin({ right: 5 })
          Text(this.isBroadcasting ? '可见' : '隐藏')
            .fontSize(11)
            .fontColor('#C8C0FF')
        }
        .padding({ left: 12, right: 12, top: 5, bottom: 5 })
        .borderRadius(12)
        .backgroundColor('#15FFFFFF')
      }
      .width('100%')
      .padding({ left: 18, right: 18, top: 4, bottom: 4 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(102)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  // ─── 操作卡片 ─────────────────────────────────────────
  @Builder
  buildActionCards() {
    Column() {
      // 操作卡片容器
      Column() {
        // 标题行
        Row() {
          Image($r('app.media.ic_scan'))
            .width(16)
            .height(16)
            .fillColor(AppColors.PRIMARY)
            .margin({ right: 6 })
          Text('快捷操作')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.PRIMARY)
        }
        .margin({ bottom: 12 })

        // 双卡并排
        Row() {
          // 卡片1: 让他人发现我
          Column() {
            Row() {
              Stack() {
                Column()
                  .width(44)
                  .height(44)
                  .borderRadius(22)
                  .linearGradient({
                    angle: 135,
                    colors: this.isBroadcasting ?
                      [['#FF6B6B', 0.0], ['#FF9F43', 1.0]] :
                      [['#6C5CE7', 0.0], ['#A29BFE', 1.0]]
                  })
                  .shadow({ radius: 10, color: this.isBroadcasting ? '#40FF6B6B' : '#406C5CE7' })

                Image($r('sys.symbol.wifi'))
                  .width(24)
                  .height(24)
                  .fillColor(Color.White)
                  .position({ x: 10, y: 10 })
              }

              Column()
                .width(1)
                .height(36)
                .backgroundColor('#12E6E1E5')
                .margin({ left: 6, right: 6 })
            }

            Text(this.isBroadcasting ? '已可见' : '让他人发现我')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isBroadcasting ? '#FF6B6B' : AppColors.TEXT_PRIMARY_LIGHT)
              .margin({ top: 12 })

            Text(this.isBroadcasting ? '点击停止广播' : '开启互传广播')
              .fontSize(11)
              .fontColor(AppColors.TEXT_SECONDARY_LIGHT)
              .margin({ top: 4 })
          }
          .width('47%')
          .padding(16)
          .borderRadius(20)
          .backgroundColor('#F8FFFFFF')
          .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
          .shadow({ radius: 8, color: '#10000000', offsetY: 2 })
          .alignItems(HorizontalAlign.Start)
          .onClick(() => { this.toggleBroadcast(); })

          Blank()

          // 卡片2: 扫描设备
          Column() {
            Row() {
              Stack() {
                Column()
                  .width(44)
                  .height(44)
                  .borderRadius(22)
                  .linearGradient({
                    angle: 135,
                    colors: this.isScanning ?
                      [['#00C9A7', 0.0], ['#55EFC4', 1.0]] :
                      [['#00A383', 0.0], ['#00C9A7', 1.0]]
                  })
                  .shadow({ radius: 10, color: '#4000C9A7' })

                Image($r('app.media.ic_scan'))
                  .width(24)
                  .height(24)
                  .fillColor(Color.White)
                  .position({ x: 10, y: 10 })
              }

              Column()
                .width(1)
                .height(36)
                .backgroundColor('#12E6E1E5')
                .margin({ left: 6, right: 6 })
            }

            Text(this.isScanning ? '扫描中' : '扫描设备')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isScanning ? '#00C9A7' : AppColors.TEXT_PRIMARY_LIGHT)
              .margin({ top: 12 })

            Text(this.isScanning ? `${this.devices.length} 台设备已发现` : '搜寻附近互传设备')
              .fontSize(11)
              .fontColor(AppColors.TEXT_SECONDARY_LIGHT)
              .margin({ top: 4 })
          }
          .width('47%')
          .padding(16)
          .borderRadius(20)
          .backgroundColor('#F8FFFFFF')
          .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
          .shadow({ radius: 8, color: '#10000000', offsetY: 2 })
          .alignItems(HorizontalAlign.Start)
          .onClick(() => { this.toggleScan(); })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .padding(18)
      .borderRadius(24)
      .backgroundColor('#EEFFFFFF')
      .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
      .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 8 })
    .width('100%')
  }

  // ─── 错误卡片 ─────────────────────────────────────────
  @Builder
  buildErrorCard() {
    Row() {
      Image($r('sys.symbol.exclamationmark_triangle'))
        .width(18)
        .height(18)
        .fillColor(AppColors.ERROR)
        .margin({ right: 10 })

      Text(this.broadcastError)
        .fontSize(13)
        .fontColor(AppColors.ERROR)
        .layoutWeight(1)

      Image($r('sys.symbol.xmark'))
        .width(16)
        .height(16)
        .fillColor('#A0FF6B6B')
        .onClick(() => { this.broadcastError = ''; })
    }
    .width('92%')
    .padding(14)
    .borderRadius(16)
    .backgroundColor('#0FFF6B6B')
    .border({ width: 1, color: '#20FF6B6B' })
    .margin({ top: 8, bottom: 4 })
  }

  // ─── 传输状态卡片 ─────────────────────────────────────
  @Builder
  buildTransferCard() {
    Row() {
      Stack() {
        Column()
          .width(48)
          .height(48)
          .borderRadius(24)
          .linearGradient({
            angle: 135,
            colors: this.transferStatus === TransferState.COMPLETED ?
              [['#00C9A7', 0.0], ['#55EFC4', 1.0]] :
            this.transferStatus === TransferState.ERROR ?
              [['#FF6B6B', 0.0], ['#FFBE76', 1.0]] :
              [['#6C5CE7', 0.0], ['#A29BFE', 1.0]]
          })

        Image(this.transferStatus === TransferState.COMPLETED ?
          $r('sys.symbol.checkmark') :
        this.transferStatus === TransferState.ERROR ?
          $r('sys.symbol.xmark') :
          $r('sys.symbol.paperplane'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
      }
      .margin({ right: 12 })

      Column() {
        Text(this.transferMessage || this.getTransferLabel())
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY_LIGHT)

        if (this.transferStatus === TransferState.TRANSFERRING) {
          Row() {
            LoadingProgress()
              .width(12)
              .height(12)
              .color('#6C5CE7')
              .margin({ right: 4 })
            Text('传输中...')
              .fontSize(11)
              .fontColor('#6C5CE7')
          }
          .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)

      Blank()
    }
    .width('92%')
    .padding(14)
    .borderRadius(18)
    .backgroundColor('#F2FFFFFF')
    .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
    .shadow({ radius: 10, color: '#12000000', offsetY: 2 })
    .margin({ top: 8, bottom: 6 })
  }

  private getTransferLabel(): string {
    switch (this.transferStatus) {
      case TransferState.CREATING_GROUP:
        return '正在创建连接通道...';
      case TransferState.P2P_CONNECTING:
        return '等待对方连接...';
      case TransferState.GROUP_CREATED:
        return '通道已创建';
      case TransferState.P2P_CONNECTED:
        return 'Wi-Fi Direct 已连接';
      case TransferState.SOCKET_LISTENING:
        return '等待文件传输...';
      case TransferState.TRANSFERRING:
        return '正在传输文件...';
      case TransferState.COMPLETED:
        return '传输完成!';
      case TransferState.ERROR:
        return '传输失败';
      default:
        return '';
    }
  }

  // ─── 设备列表区域 ─────────────────────────────────────
  @Builder
  buildDeviceList() {
    Column() {
      // 区域标题
      Row() {
        Image($r('sys.symbol.wifi'))
          .width(16)
          .height(16)
          .fillColor(AppColors.TEXT_SECONDARY_LIGHT)
          .margin({ right: 6 })

        Text('附近设备')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_SECONDARY_LIGHT)

        if (this.devices.length > 0) {
          Text(`· ${this.devices.length}`)
            .fontSize(13)
            .fontColor(AppColors.PRIMARY)
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 10 })

      // 扫描中 - 空状态
      if (this.isScanning && this.devices.length === 0) {
        this.buildSearchingState()
      }
      // 未扫描 - 空状态
      else if (!this.isScanning && this.devices.length === 0) {
        this.buildEmptyState()
      }
      // 有设备 - 列表
      else {
        Column() {
          ForEach(this.devices, (device: Device) => {
            DeviceCard({ device: device })
              .margin({ left: 16, right: 16, bottom: 8 })
              .onClick(() => { this.sendImageToDevice(device); })
          }, (device: Device) => device.id)
        }
        .width('100%')
      }

      // 底部安全间距
      Column()
        .width('100%')
        .height(88)
    }
    .width('100%')
  }

  @Builder
  buildSearchingState() {
    Column() {
      Column() {
        // 雷达动画
        Stack() {
          Column()
            .width(80)
            .height(80)
            .borderRadius(40)
            .border({ width: 2, color: '#30A29BFE' })
            .scale({ x: this.animScanPulse, y: this.animScanPulse })
            .opacity(0.5)
            .animation({
              duration: 1500,
              curve: Curve.EaseInOut,
              iterations: -1,
              playMode: PlayMode.Alternate
            })

          Column()
            .width(50)
            .height(50)
            .borderRadius(25)
            .border({ width: 1.5, color: '#20A29BFE' })
            .scale({ x: 1.5 - this.animScanPulse, y: 1.5 - this.animScanPulse })
            .opacity(0.4)
            .animation({
              duration: 1500,
              curve: Curve.EaseInOut,
              iterations: -1,
              playMode: PlayMode.AlternateReverse
            })

          Column()
            .width(36)
            .height(36)
            .borderRadius(18)
            .linearGradient({
              angle: 135,
              colors: [['#6C5CE7', 0.0], ['#A29BFE', 1.0]]
            })

          Image($r('app.media.ic_scan'))
            .width(20)
            .height(20)
            .fillColor(Color.White)
        }
        .margin({ bottom: 20 })

        Text('正在搜寻附近设备')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY_LIGHT)
          .margin({ bottom: 6 })

        Text('请确保对方也已开启互传广播')
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY_LIGHT)
      }
      .width('100%')
      .padding({ top: 30, bottom: 40 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('94%')
    .borderRadius(24)
    .backgroundColor('#F0FFFFFF')
    .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
    .shadow({ radius: 8, color: '#08000000', offsetY: 1 })
    .margin({ left: 16, right: 16 })
    .onAppear(() => {
      this.animScanPulse = 1.3;
    })
    .onDisAppear(() => {
      this.animScanPulse = 1;
    })
  }

  @Builder
  buildEmptyState() {
    Column() {
      Column() {
        Image($r('sys.symbol.shareplay'))
          .width(48)
          .height(48)
          .fillColor('#A29BFE')
          .margin({ bottom: 18 })

        Text('没有发现设备')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY_LIGHT)
          .margin({ bottom: 8 })

        Text('开启可见或扫描来发现附近设备')
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY_LIGHT)
          .textAlign(TextAlign.Center)
          .margin({ bottom: 20 })

        Row() {
          Button() {
            Text('让他人发现我')
              .fontSize(13)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
          }
          .linearGradient({
            angle: 135,
            colors: [['#6C5CE7', 0.0], ['#A29BFE', 1.0]]
          })
          .borderRadius(18)
          .height(38)
          .padding({ left: 20, right: 20 })
          .shadow({ radius: 8, color: '#306C5CE7' })
          .onClick(() => { this.toggleBroadcast(); })

          Column().width(12)

          Button() {
            Text('扫描设备')
              .fontSize(13)
              .fontColor('#6C5CE7')
              .fontWeight(FontWeight.Medium)
          }
          .backgroundColor('#15A29BFE')
          .borderRadius(18)
          .height(38)
          .padding({ left: 20, right: 20 })
          .onClick(() => { this.toggleScan(); })
        }
      }
      .width('100%')
      .padding({ top: 30, bottom: 40 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('94%')
    .borderRadius(24)
    .backgroundColor('#F0FFFFFF')
    .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
    .shadow({ radius: 8, color: '#08000000', offsetY: 1 })
    .margin({ left: 16, right: 16 })
  }

  build() {
    Column() {
      HdsTabs({ controller: this.tabsController }) {
        TabContent() {
          this.homeTabContent()
        }
        .tabBar(new BottomTabBarStyle({
          normal: new SymbolGlyphModifier($r('sys.symbol.house_fill'))
            .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
          selected: new SymbolGlyphModifier($r('sys.symbol.house_fill'))
            .fontColor([$r('sys.color.ohos_id_color_activated')])
        }, '首页'))

        TabContent() {
          SendPage()
        }
        .tabBar(new BottomTabBarStyle({
          normal: new SymbolGlyphModifier($r('sys.symbol.arrow_up'))
            .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
          selected: new SymbolGlyphModifier($r('sys.symbol.arrow_up'))
            .fontColor([$r('sys.color.ohos_id_color_activated')])
        }, '发送'))

        TabContent() {
          ReceivePage()
        }
        .tabBar(new BottomTabBarStyle({
          normal: new SymbolGlyphModifier($r('sys.symbol.arrow_down'))
            .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
          selected: new SymbolGlyphModifier($r('sys.symbol.arrow_down'))
            .fontColor([$r('sys.color.ohos_id_color_activated')])
        }, '接收'))

        TabContent() {
          HistoryPage()
        }
        .tabBar(new BottomTabBarStyle({
          normal: new SymbolGlyphModifier($r('sys.symbol.clock'))
            .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
          selected: new SymbolGlyphModifier($r('sys.symbol.clock'))
            .fontColor([$r('sys.color.ohos_id_color_activated')])
        }, '历史'))

        TabContent() {
          SettingsPage()
        }
        .tabBar(new BottomTabBarStyle({
          normal: new SymbolGlyphModifier($r('sys.symbol.gearshape'))
            .fontColor([$r('sys.color.ohos_id_color_bottom_tab_icon_off')]),
          selected: new SymbolGlyphModifier($r('sys.symbol.gearshape'))
            .fontColor([$r('sys.color.ohos_id_color_activated')])
        }, '设置'))
      }
      .barOverlap(true)
      .barPosition(BarPosition.End)
      .vertical(false)
      .barFloatingStyle({
        barBottomMargin: 24,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: this.materialLevel
        }
      })
      .scrollable(false)
      .barMode(BarMode.Fixed)
      .animationDuration(200)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.getBackground(this.isDark))
  }
}
