import dataPreferences from "@ohos:data.preferences";
import { TransferHistory } from "@normalized:N&&&entry/src/main/ets/models/TransferSession&";
import type { TransferStatus } from '../models/Enums';
import { AppConstants } from "@normalized:N&&&entry/src/main/ets/utils/AppConstants&";
import hilog from "@ohos:hilog";
const TAG = 'HistoryRepository';
const PREF_NAME = 'toshare_history';
interface HistoryPlain {
    id: string;
    peerDeviceName: string;
    isSender: boolean;
    fileCount: number;
    totalSize: number;
    timestamp: number;
    status: TransferStatus;
    fileNames: string[];
}
/**
 * 传输历史持久化仓库
 * 基于 @ohos.data.preferences 实现历史的增删查
 */
export class HistoryRepository {
    private static instance: HistoryRepository;
    private pref: dataPreferences.Preferences | null = null;
    private context: Context | null = null;
    static getInstance(): HistoryRepository {
        if (!HistoryRepository.instance) {
            HistoryRepository.instance = new HistoryRepository();
        }
        return HistoryRepository.instance;
    }
    /**
     * 初始化，必须在有 Context 的环境调用一次
     */
    async init(context: Context): Promise<void> {
        this.context = context;
        try {
            this.pref = await dataPreferences.getPreferences(context, PREF_NAME);
            hilog.info(0x0001, TAG, 'HistoryRepository initialized');
        }
        catch (err) {
            hilog.error(0x0001, TAG, 'Init failed: %{public}s', JSON.stringify(err));
        }
    }
    /**
     * 获取全部传输历史，按时间倒序
     */
    async getAllHistory(): Promise<TransferHistory[]> {
        if (!this.pref) {
            hilog.warn(0x0001, TAG, 'Preferences not initialized');
            return [];
        }
        try {
            const jsonStr = await this.pref.get(AppConstants.HISTORY_STORAGE_KEY, '[]') as string;
            const rawList: object[] = JSON.parse(jsonStr);
            const result: TransferHistory[] = [];
            for (let i = 0; i < rawList.length; i++) {
                const item = rawList[i] as Record<string, Object>;
                result.push(new TransferHistory(item['id'] as string, item['peerDeviceName'] as string, item['isSender'] as boolean, item['fileCount'] as number, item['totalSize'] as number, item['timestamp'] as number, item['status'] as TransferStatus, item['fileNames'] as string[]));
            }
            return result;
        }
        catch (err) {
            hilog.error(0x0001, TAG, 'Read history failed: %{public}s', JSON.stringify(err));
            return [];
        }
    }
    /**
     * 添加一条传输历史记录
     */
    async addHistory(history: TransferHistory): Promise<void> {
        if (!this.pref) {
            hilog.warn(0x0001, TAG, 'Preferences not initialized');
            return;
        }
        try {
            const existing = await this.getAllHistory();
            existing.unshift(history);
            await this.saveList(existing);
        }
        catch (err) {
            hilog.error(0x0001, TAG, 'Add history failed: %{public}s', JSON.stringify(err));
        }
    }
    /**
     * 清除全部历史记录
     */
    async clearAll(): Promise<void> {
        if (!this.pref) {
            return;
        }
        try {
            await this.pref.put(AppConstants.HISTORY_STORAGE_KEY, '[]');
            await this.pref.flush();
            hilog.info(0x0001, TAG, 'History cleared');
        }
        catch (err) {
            hilog.error(0x0001, TAG, 'Clear history failed: %{public}s', JSON.stringify(err));
        }
    }
    /**
     * 根据保留天数清理过期记录
     */
    async cleanupByRetentionDays(days: number): Promise<void> {
        if (days <= 0) {
            return;
        }
        try {
            const all = await this.getAllHistory();
            const cutoff = Date.now() - days * 24 * 3600 * 1000;
            const filtered = all.filter(h => h.timestamp >= cutoff);
            await this.saveList(filtered);
            hilog.info(0x0001, TAG, 'Cleanup completed, kept %{public}d records', filtered.length);
        }
        catch (err) {
            hilog.error(0x0001, TAG, 'Cleanup failed: %{public}s', JSON.stringify(err));
        }
    }
    private async saveList(list: TransferHistory[]): Promise<void> {
        if (!this.pref) {
            return;
        }
        const plainList: HistoryPlain[] = [];
        for (let i = 0; i < list.length; i++) {
            const h = list[i];
            const plain: HistoryPlain = {
                id: h.id,
                peerDeviceName: h.peerDeviceName,
                isSender: h.isSender,
                fileCount: h.fileCount,
                totalSize: h.totalSize,
                timestamp: h.timestamp,
                status: h.status,
                fileNames: h.fileNames
            };
            plainList.push(plain);
        }
        await this.pref.put(AppConstants.HISTORY_STORAGE_KEY, JSON.stringify(plainList));
        await this.pref.flush();
    }
}
