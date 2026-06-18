export class RelativeTime {
    static format(timestamp: number): string {
        const now = new Date().getTime();
        const diff = now - timestamp;
        const seconds = Math.floor(diff / 1000);
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);
        if (seconds < 60)
            return '刚刚';
        if (minutes < 60)
            return `${minutes}分钟前`;
        if (hours < 24)
            return `${hours}小时前`;
        const date = new Date(timestamp);
        const today = new Date();
        const yesterday = new Date(today);
        yesterday.setDate(yesterday.getDate() - 1);
        if (date.toDateString() === today.toDateString()) {
            return '今天';
        }
        if (date.toDateString() === yesterday.toDateString()) {
            return '昨天';
        }
        if (days < 7) {
            return `${days}天前`;
        }
        const year = date.getFullYear();
        const month = (date.getMonth() + 1).toString().padStart(2, '0');
        const day = date.getDate().toString().padStart(2, '0');
        return `${year}/${month}/${day}`;
    }
    static formatETA(seconds: number): string {
        if (seconds <= 0)
            return '--';
        if (seconds < 60)
            return `${Math.ceil(seconds)}秒`;
        if (seconds < 3600) {
            const m = Math.floor(seconds / 60);
            const s = Math.ceil(seconds % 60);
            return `${m}分${s}秒`;
        }
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        return `${h}小时${m}分`;
    }
}
