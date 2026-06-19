/**
 * 热点模式页面——WiFi 热点文件传输界面
 * 沉浸光效毛玻璃风格
 */

import { HotspotService, HotspotEventCallback } from '../services/HotspotService';
import { HttpFileServer, HttpServerCallback, HttpServerResponseEvent } from '../services/HttpFileServer';
import { HotspotState, HotspotConfig, HotspotEvent, HotspotFileItem } from '../models/HotspotTypes';
import { FileSizeFormatter } from '../utils/FileSizeFormatter';
import { AppTheme, HeaderGradient } from '../theme/AppTheme';
import { AppColors } from '../theme/AppColors';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'HotspotPage';

@Component
export struct HotspotPage {
  @State hotspotState: HotspotState = HotspotState.DISABLED;
  @State serverRunning: boolean = false;
  @State serverPort: number = 24680;
  @State gatewayIp: string = '192.168.43.1';
  @State files: HotspotFileItem[] = [];
  @State uploadCount: number = 0;
  @State downloadCount: number = 0;
  @State isDark: boolean = false;
  @State statusText: string = '未启动';
  @State isActive: boolean = false;
  private hotspotService: HotspotService = HotspotService.getInstance();
  private httpServer: HttpFileServer = HttpFileServer.getInstance();
  private headerGradient: HeaderGradient = new HeaderGradient();
  private hotspotEventCallback: HotspotEventCallback = (event: HotspotEvent): void => {
    this.onHotspotEvent(event);
  };
  private httpEventCallback: HttpServerCallback = (event): void => {
    this.onHttpServerEvent(event);
  };

  aboutToAppear(): void {
    this.hotspotService.addListener(this.hotspotEventCallback);
    this.httpServer.addListener(this.httpEventCallback);
    this.loadGatewayIp();
  }

  aboutToDisappear(): void {
    this.hotspotService.removeListener(this.hotspotEventCallback);
    this.httpServer.removeListener(this.httpEventCallback);
  }

  private loadGatewayIp(): void {
    const config: HotspotConfig | null = this.hotspotService.config;
    if (config) {
      this.gatewayIp = config.gatewayIp;
      this.serverPort = config.port;
    }
  }

  private onHotspotEvent(event: HotspotEvent): void {
    if (event.type === 'stateChange') {
      this.hotspotState = this.hotspotService.state;
      this.statusText = event.message || '';
      this.updateUiState();
    } else if (event.type === 'info') {
      this.statusText = event.message || '';
    } else if (event.type === 'error') {
      this.hotspotState = HotspotState.ERROR;
      this.statusText = event.message || '';
    }
  }

  private onHttpServerEvent(event: HttpServerResponseEvent): void {
    if (event.type === 'fileReceived') {
      this.statusText = `已接收: ${event.fileName || ''}`;
      this.files = this.httpServer.fileList;
      this.updateFileCounts();
    } else if (event.type === 'error') {
      this.statusText = event.message || '';
    } else if (event.type === 'started') {
      this.serverRunning = true;
    } else if (event.type === 'stopped') {
      this.serverRunning = false;
    }
  }

  updateUiState(): void {
    this.isActive = this.hotspotState === HotspotState.ACTIVE;
    const config: HotspotConfig | null = this.hotspotService.config;
    if (config) {
      this.gatewayIp = config.gatewayIp;
      this.serverPort = config.port;
    }
    this.files = this.httpServer.fileList;
    this.updateFileCounts();
  }

  private updateFileCounts(): void {
    let u: number = 0;
    let d: number = 0;
    for (let i = 0; i < this.files.length; i++) {
      if (this.files[i].direction === 'upload') {
        u++;
      } else {
        d++;
      }
    }
    this.uploadCount = u;
    this.downloadCount = d;
  }

  async startService(): Promise<void> {
    const ok: boolean = await this.hotspotService.start(this.serverPort);
    if (ok && this.hotspotService.isActive) {
      await this.startHttpServer();
    }
  }

  async stopService(): Promise<void> {
    await this.httpServer.stop();
    this.hotspotService.stop();
    this.isActive = false;
    this.serverRunning = false;
    this.statusText = '已关闭';
  }

  async onHotspotDetected(): Promise<void> {
    const ok: boolean = await this.hotspotService.confirmHotspotActive();
    if (ok) {
      await this.startHttpServer();
    }
  }

  private async startHttpServer(): Promise<void> {
    const config: HotspotConfig | null = this.hotspotService.config;
    if (!config) {
      return;
    }
    const ok: boolean = await this.httpServer.start(config.port);
    if (ok) {
      this.serverRunning = true;
      this.serverPort = config.port;
      this.gatewayIp = config.gatewayIp;
      this.statusText = `已就绪: http://${config.gatewayIp}:${config.port}`;
      this.files = this.httpServer.fileList;
      this.updateFileCounts();
    } else {
      this.statusText = 'HTTP 服务器启动失败';
    }
  }

  private getFileIcon(name: string): string {
    const ext: string = name.split('.').pop()?.toLowerCase() || '';
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].indexOf(ext) >= 0) {
      return '🖼️';
    }
    if (['mp4', 'mov', 'avi', 'mkv'].indexOf(ext) >= 0) {
      return '🎬';
    }
    if (['pdf'].indexOf(ext) >= 0) {
      return '📄';
    }
    if (['zip', 'rar', '7z', 'tar', 'gz'].indexOf(ext) >= 0) {
      return '🗜️';
    }
    if (['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'].indexOf(ext) >= 0) {
      return '📊';
    }
    if (['mp3', 'wav', 'flac', 'aac'].indexOf(ext) >= 0) {
      return '🎵';
    }
    if (['apk'].indexOf(ext) >= 0) {
      return '🤖';
    }
    return '📁';
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
          Image($r('sys.symbol.wifi'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
            .margin({ right: 10 })

          Column() {
            Text('热点模式')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text('零安装 · 浏览器直传')
              .fontSize(11)
              .fontColor('#C8C0FF')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Row() {
            Column()
              .width(7)
              .height(7)
              .borderRadius(4)
              .backgroundColor(this.isActive ? AppColors.STATUS_ONLINE : AppColors.STATUS_OFFLINE)
              .margin({ right: 5 })
            Text(this.isActive ? '运行中' : '已停止')
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
      .height(90)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

      // ====== 内容区 ======
      Scroll() {
        Column() {
          // 状态卡片
          this.buildStatusCard()

          if (this.isActive && this.serverRunning) {
            this.buildConnectionInfoCard()
            this.buildFileListCard()
          } else if (this.hotspotState === HotspotState.STARTING) {
            this.buildWaitingForHotspotCard()
          } else if (this.hotspotState === HotspotState.ERROR) {
            this.buildErrorCard()
          } else {
            this.buildWelcomeCard()
          }

          Column()
            .width('100%')
            .height(80)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.getBackground(this.isDark))
  }

  // ─── 状态卡片 ─────────────────────────────
  @Builder
  buildStatusCard(): void {
    Column() {
      Row() {
        Stack() {
          Column()
            .width(52)
            .height(52)
            .borderRadius(26)
            .linearGradient({
              angle: 135,
              colors: this.isActive ?
                [['#00C9A7', 0.0], ['#55EFC4', 1.0]] :
              this.hotspotState === HotspotState.STARTING ?
                [['#6C5CE7', 0.0], ['#A29BFE', 1.0]] :
                [['#A0A0A0', 0.0], ['#C0C0C0', 1.0]]
            })
            .shadow({ radius: 10, color: this.isActive ? '#4000C9A7' : '#306C5CE7' })

          Image($r('sys.symbol.wifi'))
            .width(28)
            .height(28)
            .fillColor(Color.White)
        }
        .margin({ right: 14 })

        Column() {
          Text(this.statusText || (this.isActive ? '运行中' : '待启动'))
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.isActive ? '#00C9A7' :
              this.hotspotState === HotspotState.STARTING ? '#6C5CE7' :
              AppTheme.getTextSecondary(this.isDark))

          Text(this.isActive ? 'HTTP 文件服务器运行中' : '用户手动开启热点，App 自动检测')
            .fontSize(12)
            .fontColor(AppTheme.getTextSecondary(this.isDark))
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (this.isActive) {
          Button() {
            Text('关闭')
              .fontSize(13)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
          }
          .backgroundColor('#FF6B6B')
          .borderRadius(18)
          .height(36)
          .padding({ left: 18, right: 18 })
          .shadow({ radius: 6, color: '#40FF6B6B' })
          .onClick(() => { this.stopService(); })
        } else {
          Button() {
            Text('启动')
              .fontSize(13)
              .fontColor(Color.White)
              .fontWeight(FontWeight.Medium)
          }
          .linearGradient({
            angle: 135,
            colors: [['#6C5CE7', 0.0], ['#A29BFE', 1.0]]
          })
          .borderRadius(18)
          .height(36)
          .padding({ left: 18, right: 18 })
          .shadow({ radius: 8, color: '#306C5CE7' })
          .onClick(() => { this.startService(); })
        }
      }
      .width('100%')
    }
    .width('94%')
    .padding(18)
    .borderRadius(24)
    .backgroundColor(AppTheme.frostCardBg(this.isDark))
    .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
    .margin({ left: 16, right: 16, top: 16, bottom: 8 })
  }

  // ─── 欢迎卡片 ─────────────────────────────
  @Builder
  buildWelcomeCard(): void {
    Column() {
      Column()
        .width(80)
        .height(80)
        .borderRadius(40)
        .backgroundColor('#12' + AppColors.PRIMARY.substring(1))
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 20 })
      Image($r('sys.symbol.wifi'))
        .width(44)
        .height(44)
        .fillColor('#A29BFE')

      Text('WiFi 热点文件传输')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.getTextPrimary(this.isDark))
        .margin({ bottom: 6 })

      Text('无需对方安装 App，系统浏览器即可传文件')
        .fontSize(13)
        .fontColor(AppTheme.getTextSecondary(this.isDark))
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })
        .width('80%')

      // 三步指南
      Column() {
        this.guideStep('1', '点击上方"启动"按钮')
        this.guideStep('2', '在系统控制中心开启"便携热点"')
        this.guideStep('3', '对方连接 WiFi 后用浏览器传文件')
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#F5F0FF')
      .borderRadius(16)
    }
    .width('94%')
    .padding({ top: 32, bottom: 32, left: 24, right: 24 })
    .borderRadius(24)
    .backgroundColor(AppTheme.frostCardBg(this.isDark))
    .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
    .margin({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  guideStep(num: string, text: string): void {
    Row() {
      Column() {
        Text(num)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width(26)
      .height(26)
      .borderRadius(13)
      .backgroundColor(AppColors.PRIMARY)
      .margin({ right: 12 })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text(text)
        .fontSize(14)
        .fontColor(AppTheme.getTextPrimary(this.isDark))
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  // ─── 等待热点 ─────────────────────────────
  @Builder
  buildWaitingForHotspotCard(): void {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color(AppColors.PRIMARY)
        .margin({ bottom: 20 })

      Text('等待热点就绪...')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppTheme.getTextPrimary(this.isDark))
        .margin({ bottom: 12 })

      Text('请下拉控制中心，点击"便携热点"开关')
        .fontSize(14)
        .fontColor(AppColors.PRIMARY)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 28 })

      Button() {
        Text('我已开启热点')
          .fontSize(14)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .linearGradient({
        angle: 135,
        colors: [['#00C9A7', 0.0], ['#55EFC4', 1.0]]
      })
      .borderRadius(20)
      .height(42)
      .padding({ left: 28, right: 28 })
      .shadow({ radius: 8, color: '#3000C9A7' })
      .onClick(() => { this.onHotspotDetected(); })
    }
    .width('94%')
    .padding(36)
    .borderRadius(24)
    .backgroundColor(AppTheme.frostCardBg(this.isDark))
    .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
    .margin({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Center)
  }

  // ─── 连接信息 ─────────────────────────────
  @Builder
  buildConnectionInfoCard(): void {
    Column() {
      // 标题
      Row() {
        Row()
          .width(4)
          .height(16)
          .borderRadius(2)
          .backgroundColor(AppColors.PRIMARY)
          .margin({ right: 8 })
        Text('连接信息')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.getTextPrimary(this.isDark))
      }
      .width('100%')
      .margin({ bottom: 14 })

      // 地址大号展示
      Column() {
        Row() {
          Image($r('sys.symbol.shareplay'))
            .width(16)
            .height(16)
            .fillColor(AppColors.PRIMARY)
            .margin({ right: 8 })
          Text('浏览器访问')
            .fontSize(13)
            .fontColor(AppTheme.getTextSecondary(this.isDark))
        }

        Text(`http://${this.gatewayIp}:${this.serverPort}`)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.PRIMARY)
          .width('100%')
          .margin({ top: 6 })
      }
      .padding(16)
      .width('100%')
      .borderRadius(16)
      .backgroundColor('#F5F0FF')

      Text('对方连接此 WiFi 后，用浏览器打开上方地址即可传文件')
        .fontSize(12)
        .fontColor(AppTheme.getTextSecondary(this.isDark))
        .margin({ top: 12 })
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('94%')
    .padding(18)
    .borderRadius(24)
    .backgroundColor(AppTheme.frostCardBg(this.isDark))
    .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
    .margin({ left: 16, right: 16, bottom: 8 })
  }

  // ─── 文件列表 ─────────────────────────────
  @Builder
  buildFileListCard(): void {
    Column() {
      Row() {
        Row()
          .width(4)
          .height(16)
          .borderRadius(2)
          .backgroundColor(AppColors.SUCCESS)
          .margin({ right: 8 })
        Text('传输文件')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppTheme.getTextPrimary(this.isDark))

        Blank()

        Text(`${this.files.length} 个`)
          .fontSize(12)
          .fontColor(AppTheme.getTextSecondary(this.isDark))
          .fontWeight(FontWeight.Medium)
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .backgroundColor('#12' + AppColors.PRIMARY.substring(1))
          .borderRadius(10)
      }
      .width('100%')
      .margin({ bottom: 14 })

      if (this.files.length === 0) {
        Column() {
          Image($r('sys.symbol.folder'))
            .width(44)
            .height(44)
            .fillColor('#C0C0C0')
            .margin({ bottom: 12 })

          Text('暂无文件传输')
            .fontSize(14)
            .fontColor(AppTheme.getTextSecondary(this.isDark))

          Text('等待对端设备连接并上传...')
            .fontSize(12)
            .fontColor('#B0B0B0')
            .margin({ top: 4 })
        }
        .width('100%')
        .padding(28)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
      } else {
        Row() {
          if (this.uploadCount > 0) {
            Text(`📤 上传 ${this.uploadCount}`)
              .fontSize(11)
              .fontColor('#00A383')
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor('#1000C9A7')
              .borderRadius(8)
          }
          if (this.downloadCount > 0) {
            Text(`📥 下载 ${this.downloadCount}`)
              .fontSize(11)
              .fontColor('#6C5CE7')
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor('#126C5CE7')
              .borderRadius(8)
              .margin({ left: 6 })
          }
        }
        .width('100%')
        .margin({ bottom: 10 })

        List({ space: 6 }) {
          ForEach(this.files, (file: HotspotFileItem) => {
            ListItem() {
              Row() {
                // 文件 icon emoji
                Text(this.getFileIcon(file.name))
                  .fontSize(22)
                  .margin({ right: 10 })

                Column() {
                  Text(file.name)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(AppTheme.getTextPrimary(this.isDark))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(FileSizeFormatter.formatSize(file.size))
                    .fontSize(11)
                    .fontColor(AppTheme.getTextSecondary(this.isDark))
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // 方向标签
                Text(file.direction === 'upload' ? '⬆ 上传' : '⬇ 下载')
                  .fontSize(11)
                  .fontColor(file.direction === 'upload' ? '#00A383' : '#6C5CE7')
                  .fontWeight(FontWeight.Medium)
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .backgroundColor(file.direction === 'upload' ? '#1000C9A7' : '#126C5CE7')
                  .borderRadius(8)
              }
              .width('100%')
              .padding(12)
              .borderRadius(14)
              .backgroundColor('#F5F0FF')
            }
          }, (file: HotspotFileItem) => file.name + file.completedAt)
        }
        .width('100%')
        .height(Math.min(this.files.length * 66, 260))
      }
    }
    .width('94%')
    .padding(18)
    .borderRadius(24)
    .backgroundColor(AppTheme.frostCardBg(this.isDark))
    .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
    .margin({ left: 16, right: 16, bottom: 8 })
  }

  // ─── 错误卡片 ─────────────────────────────
  @Builder
  buildErrorCard(): void {
    Column() {
      Column()
        .width(80)
        .height(80)
        .borderRadius(40)
        .backgroundColor('#12FF6B6B')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 16 })
      Image($r('sys.symbol.exclamationmark_triangle'))
        .width(44)
        .height(44)
        .fillColor('#FF6B6B')

      Text('启动失败')
        .fontSize(17)
        .fontColor('#FF6B6B')
        .fontWeight(FontWeight.Bold)
        .margin({ top: 4, bottom: 8 })

      Text(this.statusText)
        .fontSize(13)
        .fontColor('#FF6B6B')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })
        .width('80%')

      Button() {
        Text('重试')
          .fontSize(14)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .linearGradient({
        angle: 135,
        colors: [['#6C5CE7', 0.0], ['#A29BFE', 1.0]]
      })
      .borderRadius(18)
      .height(38)
      .padding({ left: 28, right: 28 })
      .shadow({ radius: 8, color: '#306C5CE7' })
      .onClick(() => { this.startService(); })
    }
    .width('94%')
    .padding(36)
    .borderRadius(24)
    .backgroundColor(AppTheme.frostCardBg(this.isDark))
    .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
    .margin({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Center)
  }
}
