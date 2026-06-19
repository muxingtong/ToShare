/**
 * 历史记录页面——沉浸光效毛玻璃风格
 */

import { TransferHistory } from '../models/TransferSession';
import { TransferStatus } from '../models/Enums';
import { HistoryCard } from '../components/HistoryCard';
import { EmptyState } from '../components/EmptyState';
import { FileSizeFormatter } from '../utils/FileSizeFormatter';
import { HistoryRepository } from '../services/HistoryRepository';
import { AppTheme, HeaderGradient } from '../theme/AppTheme';
import { AppColors } from '../theme/AppColors';

class TodayStats {
  sent: number = 0;
  received: number = 0;
  total: number = 0;
}

@Component
export struct HistoryPage {
  @State transferHistory: TransferHistory[] = [];
  @State todayStats: TodayStats = new TodayStats();
  @State totalTransferred: number = 0;
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
    const list: TransferHistory[] = await this.historyRepo.getAllHistory();
    this.transferHistory = list;
    this.computeTodayStats();
    this.totalTransferred = this.transferHistory
      .filter((h: TransferHistory): boolean => h.status === TransferStatus.COMPLETED)
      .reduce((sum: number, h: TransferHistory): number => sum + h.totalSize, 0);
  }

  computeTodayStats(): void {
    const today: string = new Date().toDateString();
    const todayHistory: TransferHistory[] = [];
    for (let i = 0; i < this.transferHistory.length; i++) {
      if (new Date(this.transferHistory[i].timestamp).toDateString() === today) {
        todayHistory.push(this.transferHistory[i]);
      }
    }
    let sent: number = 0;
    let received: number = 0;
    for (let i = 0; i < todayHistory.length; i++) {
      if (todayHistory[i].isSender) {
        sent++;
      } else {
        received++;
      }
    }
    const stats: TodayStats = new TodayStats();
    stats.sent = sent;
    stats.received = received;
    stats.total = todayHistory.length;
    this.todayStats = stats;
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
          Image($r('sys.symbol.clock'))
            .width(22)
            .height(22)
            .fillColor(Color.White)
            .margin({ right: 10 })
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

      // ====== 统计面板 ======
      Column() {
        // 上排：三个统计
        Row() {
          Column() {
            Text(`${this.todayStats.sent}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.PRIMARY)
            Text('今日发送')
              .fontSize(11)
              .fontColor(AppTheme.getTextSecondary(this.isDark))
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text(`${this.todayStats.received}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.SUCCESS)
            Text('今日接收')
              .fontSize(11)
              .fontColor(AppTheme.getTextSecondary(this.isDark))
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text(`${this.todayStats.total}`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.WARNING)
            Text('今日总计')
              .fontSize(11)
              .fontColor(AppTheme.getTextSecondary(this.isDark))
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }

        // 分隔线
        Row()
          .width('100%')
          .height(1)
          .backgroundColor(AppColors.DIVIDER_LIGHT)
          .margin({ top: 12, bottom: 10 })

        // 下排：累计传输 + 记录数
        Row() {
          Column() {
            Text(FileSizeFormatter.formatSize(this.totalTransferred))
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppTheme.getTextPrimary(this.isDark))
            Text('累计传输')
              .fontSize(11)
              .fontColor(AppTheme.getTextSecondary(this.isDark))
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text(`${this.transferHistory.length}`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppTheme.getTextPrimary(this.isDark))
            Text('总记录数')
              .fontSize(11)
              .fontColor(AppTheme.getTextSecondary(this.isDark))
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .padding(18)
      .margin({ left: 20, right: 20, top: 12 })
      .borderRadius(20)
      .backgroundColor(AppTheme.frostCardBg(this.isDark))
      .shadow({ radius: 8, color: '#0C000000', offsetY: 1 })

      // ====== 历史列表 ======
      if (this.transferHistory.length === 0) {
        EmptyState({
          icon: '📋',
          title: '暂无传输记录',
          subtitle: '发送或接收文件后，记录将显示在这里',
          isDark: this.isDark
        })
      } else {
        List() {
          ForEach(this.transferHistory, (item: TransferHistory) => {
            ListItem() {
              HistoryCard({ history: item, isDark: this.isDark })
            }
          }, (item: TransferHistory) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16, top: 8 })
        .edgeEffect(EdgeEffect.Spring)
      }

      Column()
        .width('100%')
        .height(80)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.getBackground(this.isDark))
  }
}
