export class FileSizeFormatter {
    static formatSize(bytes: number): string {
        if (bytes <= 0)
            return '0 B';
        const units = ['B', 'KB', 'MB', 'GB'];
        const k = 1024;
        const i = Math.min(Math.floor(Math.log(bytes) / Math.log(k)), units.length - 1);
        const value = bytes / Math.pow(k, i);
        return `${value.toFixed(i === 0 ? 0 : 1)} ${units[i]}`;
    }
    static formatSpeed(bytesPerSecond: number): string {
        if (bytesPerSecond <= 0)
            return '0 B/s';
        return `${FileSizeFormatter.formatSize(bytesPerSecond)}/s`;
    }
}
