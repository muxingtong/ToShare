/**
 * 热点模式页面——WiFi 热点文件传输界面
 *
 * 1. 用户在系统控制中心开启"便携热点"
 * 2. App 检测到热点激活，自动启动 HTTP 服务器
 * 3. 对方连接热点后用浏览器访问 IP:端口
 * 4. 文件上传/下载均通过 Web UI 完成
 */

import { HotspotService, HotspotEventCallback } from '../services/HotspotService';
import { HttpFileServer, HttpServerCallback, HttpServerResponseEvent } from '../services/HttpFileServer';
import { HotspotState, HotspotConfig, HotspotEvent, HotspotFileItem } from '../models/HotspotTypes';
import { AppTheme } from '../theme/AppTheme';
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
  @State isDark: boolean = false;
  @State statusText: string = '未启动';
  @State isActive: boolean = false;
  @State connectingTo: string = '';
  private hotspotService: HotspotService = HotspotService.getInstance();
  private httpServer: HttpFileServer = HttpFileServer.getInstance();
  private hotspotEventCallback: HotspotEventCallback =
    (event: HotspotEvent): void => {
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
    const config = this.hotspotService.config;
    if (config) {
      this.gatewayIp = config.gatewayIp;
      this.serverPort = config.port;
    }
  }

  private onHotspotEvent(event: HotspotEvent): void {
    switch (event.type) {
      case 'stateChange':
        this.hotspotState = this.hotspotService.state;
        this.statusText = event.message || '';
        this.updateUiState();
        break;
      case 'info':
        this.statusText = event.message || '';
        break;
      case 'error':
        this.hotspotState = HotspotState.ERROR;
        this.statusText = event.message || '';
        break;
    }
  }

  private onHttpServerEvent(event: HttpServerResponseEvent): void {
    if (event.type === 'fileReceived') {
      this.statusText = `已接收: ${event.fileName || ''}`;
      this.files = this.httpServer.fileList;
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
    const config = this.hotspotService.config;
    if (config) {
      this.gatewayIp = config.gatewayIp;
      this.serverPort = config.port;
    }
    this.files = this.httpServer.fileList;
  }

  async startService(): Promise<void> {
    // 1. 启动热点检测服务 + 自动检测
    const ok = await this.hotspotService.start(this.serverPort);
    if (ok) {
      // 2. 如果热点已经激活，直接起 HTTP 服务器
      if (this.hotspotService.isActive) {
        await this.startHttpServer();
      }
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
    // 用户手动确认——热点已开启
    const ok = await this.hotspotService.confirmHotspotActive();
    if (ok) {
      await this.startHttpServer();
    }
  }

  private async startHttpServer(): Promise<void> {
    const config = this.hotspotService.config;
    if (!config) {
      return;
    }
    const ok = await this.httpServer.start(config.port);
    if (ok) {
      this.serverRunning = true;
      this.serverPort = config.port;
      this.gatewayIp = config.gatewayIp;
      this.statusText = `已就绪: http://${config.gatewayIp}:${config.port}`;
      this.files = this.httpServer.fileList;
    } else {
      this.statusText = 'HTTP 服务器启动失败';
    }
  }

  // ==================== UI ====================

  build() {
    Column() {
      this.buildHeader();

      Scroll() {
        Column() {
          this.buildStatusCard();

          if (this.isActive && this.serverRunning) {
            this.buildConnectionInfoCard();
            this.buildFileListCard();
          } else if (this.hotspotState === HotspotState.STARTING) {
            this.buildWaitingForHotspotCard();
          } else if (this.hotspotState === HotspotState.ERROR) {
            this.buildErrorCard();
          } else {
            this.buildWelcomeCard();
          }
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
    .backgroundColor(AppTheme.getBackground(this.isDark))
  }

  @Builder
  buildHeader(): void {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 180,
          colors: [
            ['#0C2461', 0.0],
            ['#1B1464', 0.4],
            ['#4834D4', 0.75],
            ['#6C5CE7', 1.0],
          ],
        });

      Row() {
        Image($r("sys.symbol.wifi"))
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
  }

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
                [['#A0A0A0', 0.0], ['#C0C0C0', 1.0]],
            })
            .shadow({ radius: 10, color: this.isActive ? '#4000C9A7' : '#306C5CE7' })

          Image($r("sys.symbol.wifi"))
            .width(28)
            .height(28)
            .fillColor(Color.White)
            .position({ x: 12, y: 12 })
        }
        .margin({ right: 14 })

        Column() {
          Text(this.statusText || (this.isActive ? '运行中' : '待启动'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isActive ? '#00C9A7' :
              this.hotspotState === HotspotState.STARTING ? '#6C5CE7' :
              AppColors.TEXT_SECONDARY_LIGHT)

          Text(this.isActive ? 'HTTP 文件服务器运行中' : '用户手动开启热点，App 自动检测')
            .fontSize(12)
            .fontColor(AppColors.TEXT_SECONDARY_LIGHT)
            .margin({ top: 4 })
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
            colors: [['#6C5CE7', 0.0], ['#A29BFE', 1.0]],
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
    .backgroundColor('#F8FFFFFF')
    .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
    .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
    .margin({ left: 16, right: 16, top: 16, bottom: 8 })
  }

  @Builder
  buildWelcomeCard(): void {
    Column() {
      Image($r("sys.symbol.wifi"))
        .width(52)
        .height(52)
        .fillColor('#A29BFE')
        .margin({ bottom: 16 })

      Text('WiFi 热点文件传输')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.TEXT_PRIMARY_LIGHT)
        .margin({ bottom: 8 })

      Text('无需对方安装 App，系统浏览器即可传文件')
        .fontSize(13)
        .fontColor(AppColors.TEXT_SECONDARY_LIGHT)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })
        .width('80%')

      // 三步提示
      Column() {
        Row() {
          Column() {
            Text('1')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .width(26)
          .height(26)
          .borderRadius(13)
          .backgroundColor('#6C5CE7')
          .margin({ right: 10 })
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)

          Text('点击上方"启动"按钮')
            .fontSize(14)
            .fontColor(AppColors.TEXT_PRIMARY_LIGHT)
        }
        .width('100%')
        .margin({ bottom: 12 })

        Row() {
          Column() {
            Text('2')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .width(26)
          .height(26)
          .borderRadius(13)
          .backgroundColor('#6C5CE7')
          .margin({ right: 10 })
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)

          Text('在系统控制中心开启"便携热点"')
            .fontSize(14)
            .fontColor(AppColors.TEXT_PRIMARY_LIGHT)
        }
        .width('100%')
        .margin({ bottom: 12 })

        Row() {
          Column() {
            Text('3')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
          }
          .width(26)
          .height(26)
          .borderRadius(13)
          .backgroundColor('#6C5CE7')
          .margin({ right: 10 })
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)

          Text('对方 WiFi 连接后浏览器传文件')
            .fontSize(14)
            .fontColor(AppColors.TEXT_PRIMARY_LIGHT)
        }
        .width('100%')
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#F5F0FF')
      .borderRadius(16)
    }
    .width('94%')
    .padding(32)
    .borderRadius(24)
    .backgroundColor('#F8FFFFFF')
    .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
    .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
    .margin({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildWaitingForHotspotCard(): void {
    Column() {
      Column() {
        LoadingProgress()
          .width(48)
          .height(48)
          .color('#6C5CE7')
          .margin({ bottom: 16 })

        Text('等待热点就绪...')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY_LIGHT)
          .margin({ bottom: 16 })

        Text('请下拉控制中心，点击"便携热点"开关')
          .fontSize(14)
          .fontColor('#6C5CE7')
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .margin({ bottom: 24 })

        Button() {
          Text('我已开启热点')
            .fontSize(14)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
        .linearGradient({
          angle: 135,
          colors: [['#00C9A7', 0.0], ['#55EFC4', 1.0]],
        })
        .borderRadius(20)
        .height(42)
        .padding({ left: 28, right: 28 })
        .shadow({ radius: 8, color: '#3000C9A7' })
        .onClick(() => { this.onHotspotDetected(); })
      }
    }
    .width('94%')
    .padding(36)
    .borderRadius(24)
    .backgroundColor('#F8FFFFFF')
    .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
    .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
    .margin({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildConnectionInfoCard(): void {
    Column() {
      Text('🔗 连接信息')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.PRIMARY)
        .width('100%')
        .margin({ bottom: 12 })

      Column() {
        Row() {
          Image($r('sys.symbol.shareplay'))
            .width(16)
            .height(16)
            .fillColor('#6C5CE7')
            .margin({ right: 8 })
          Text('浏览器访问')
            .fontSize(13)
            .fontColor(AppColors.TEXT_SECONDARY_LIGHT)
        }

        Text(`http://${this.gatewayIp}:${this.serverPort}`)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#6C5CE7')
          .width('100%')
          .margin({ top: 4 })
      }
      .padding(16)
      .width('100%')
      .borderRadius(16)
      .backgroundColor('#F5F0FF')

      Text('对方连接此 WiFi 后，用浏览器打开上方地址即可传文件')
        .fontSize(12)
        .fontColor(AppColors.TEXT_SECONDARY_LIGHT)
        .margin({ top: 12 })
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('94%')
    .padding(18)
    .borderRadius(24)
    .backgroundColor('#F8FFFFFF')
    .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
    .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
    .margin({ left: 16, right: 16, bottom: 8 })
  }

  @Builder
  buildFileListCard(): void {
    Column() {
      Row() {
        Image($r('sys.symbol.folder'))
          .width(16)
          .height(16)
          .fillColor(AppColors.PRIMARY)
          .margin({ right: 6 })

        Text('传输文件')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.PRIMARY)

        Blank()

        Text(`${this.files.length} 个`)
          .fontSize(12)
          .fontColor(AppColors.TEXT_SECONDARY_LIGHT)
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.files.length === 0) {
        Column() {
          Image($r('sys.symbol.folder'))
            .width(40)
            .height(40)
            .fillColor('#C0C0C0')
            .margin({ bottom: 10 })

          Text('暂无文件传输')
            .fontSize(14)
            .fontColor(AppColors.TEXT_SECONDARY_LIGHT)

          Text('等待对端设备连接并上传...')
            .fontSize(12)
            .fontColor('#B0B0B0')
            .margin({ top: 4 })
        }
        .width('100%')
        .padding(24)
        .alignItems(HorizontalAlign.Center)
      } else {
        List({ space: 8 }) {
          ForEach(this.files, (file: HotspotFileItem) => {
            ListItem() {
              Row() {
                Image($r('sys.symbol.doc'))
                  .width(20)
                  .height(20)
                  .fillColor(file.direction === 'upload' ? '#00C9A7' : '#6C5CE7')
                  .margin({ right: 10 })

                Column() {
                  Text(file.name)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(AppColors.TEXT_PRIMARY_LIGHT)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(this.formatFileSize(file.size))
                    .fontSize(11)
                    .fontColor(AppColors.TEXT_SECONDARY_LIGHT)
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text(file.direction === 'upload' ? '上传' : '下载')
                  .fontSize(11)
                  .fontColor(file.direction === 'upload' ? '#00C9A7' : '#6C5CE7')
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')
              .padding(12)
              .borderRadius(14)
              .backgroundColor('#F5F0FF')
            }
          }, (file: HotspotFileItem) => file.name + file.completedAt)
        }
        .width('100%')
        .height(Math.min(this.files.length * 64, 240))
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('94%')
    .padding(18)
    .borderRadius(24)
    .backgroundColor('#F8FFFFFF')
    .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
    .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
    .margin({ left: 16, right: 16, bottom: 8 })
  }

  @Builder
  buildErrorCard(): void {
    Column() {
      Image($r('sys.symbol.exclamationmark_triangle'))
        .width(48)
        .height(48)
        .fillColor('#FF6B6B')
        .margin({ bottom: 16 })

      Text('启动失败')
        .fontSize(17)
        .fontColor('#FF6B6B')
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 8 })

      Text(this.statusText)
        .fontSize(13)
        .fontColor('#FF6B6B')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 20 })
        .width('80%')

      Button() {
        Text('重试')
          .fontSize(14)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
      }
      .linearGradient({
        angle: 135,
        colors: [['#6C5CE7', 0.0], ['#A29BFE', 1.0]],
      })
      .borderRadius(18)
      .height(38)
      .padding({ left: 24, right: 24 })
      .onClick(() => { this.startService(); })
    }
    .width('94%')
    .padding(36)
    .borderRadius(24)
    .backgroundColor('#F8FFFFFF')
    .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
    .shadow({ radius: 12, color: '#12000000', offsetY: 3 })
    .margin({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Center)
  }

  private formatFileSize(bytes: number): string {
    if (bytes < 1024) {
      return bytes + ' B';
    } else if (bytes < 1048576) {
      return (bytes / 1024).toFixed(1) + ' KB';
    } else if (bytes < 1073741824) {
      return (bytes / 1048576).toFixed(1) + ' MB';
    }
    return (bytes / 1073741824).toFixed(2) + ' GB';
  }
}
