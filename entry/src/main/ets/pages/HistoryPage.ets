import { TransferHistory } from '../models/TransferSession';
import { TransferStatus } from '../models/Enums';
import { HistoryCard } from '../components/HistoryCard';
import { EmptyState } from '../components/EmptyState';
import { FileSizeFormatter } from '../utils/FileSizeFormatter';
import { HistoryRepository } from '../services/HistoryRepository';
import { AppColors } from '../theme/AppColors';
import { HeaderGradient } from '../theme/AppTheme';

class TodayStats {
  sent: number;
  received: number;
  total: number;

  constructor(sent: number = 0, received: number = 0, total: number = 0) {
    this.sent = sent;
    this.received = received;
    this.total = total;
  }
}

@Component
export struct HistoryPage {
  @State transferHistory: TransferHistory[] = [];
  @State todayStats: TodayStats = new TodayStats();
  @State isDark: boolean = false;
  private headerGradient: HeaderGradient = new HeaderGradient();
  private historyRepo: HistoryRepository = HistoryRepository.getInstance();

  aboutToAppear(): void {
    this.loadHistory();
  }

  onPageShow(): void {
    this.loadHistory();
  }

  async loadHistory(): Promise<void> {
    const list = await this.historyRepo.getAllHistory();
    this.transferHistory = list;
    this.computeTodayStats();
  }

  computeTodayStats(): void {
    const today = new Date().toDateString();
    const todayHistory = this.transferHistory.filter(h => {
      return new Date(h.timestamp).toDateString() === today;
    });
    const stats = new TodayStats();
    stats.sent = todayHistory.filter(h => h.isSender).length;
    stats.received = todayHistory.filter(h => !h.isSender).length;
    stats.total = todayHistory.length;
    this.todayStats = stats;
  }

  get totalSentSize(): number {
    return this.transferHistory
      .filter(h => h.status === TransferStatus.COMPLETED)
      .reduce((sum, h) => sum + h.totalSize, 0);
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
          Text('传输历史')
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

      // 统计面板
      Row() {
        Column() {
          Text(`${this.todayStats.sent}`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#6C5CE7')
          Text('今日发送')
            .fontSize(11)
            .fontColor('#625B71')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text(`${this.todayStats.received}`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00C9A7')
          Text('今日接收')
            .fontSize(11)
            .fontColor('#625B71')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text(`${this.todayStats.total}`)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9F43')
          Text('今日总计')
            .fontSize(11)
            .fontColor('#625B71')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Text(FileSizeFormatter.formatSize(this.totalSentSize))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1B1F')
          Text('累计传输')
            .fontSize(11)
            .fontColor('#625B71')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .padding({ top: 16, bottom: 16 })
      .margin({ left: 20, right: 20, top: 12 })
      .borderRadius(18)
      .backgroundColor('#F2FFFFFF')
      .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
      .shadow({ radius: 6, color: '#0C000000', offsetY: 1 })

      if (this.transferHistory.length === 0) {
        EmptyState({
          icon: '📋',
          title: '暂无传输记录',
          subtitle: '发送或接收文件后，记录将显示在这里'
        })
      } else {
        List() {
          ForEach(this.transferHistory, (item: TransferHistory) => {
            ListItem() {
              HistoryCard({ history: item })
            }
          }, (item: TransferHistory) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
      }

      Column()
        .width('100%')
        .height(80)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0EFF5')
  }
}
