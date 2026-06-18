import type { TransferStatus } from './Enums';
import type { FileTransferItem } from './FileTransfer';
export class TransferSession {
    id: string;
    senderId: string;
    receiverId: string;
    files: FileTransferItem[];
    status: TransferStatus;
    createdAt: number;
    completedAt: number;
    totalBytes: number;
    transferredBytes: number;
    speed: number;
    constructor(id: string, senderId: string, receiverId: string, files: FileTransferItem[], status: TransferStatus, createdAt: number, completedAt: number, totalBytes: number, transferredBytes: number, speed: number) {
        this.id = id;
        this.senderId = senderId;
        this.receiverId = receiverId;
        this.files = files;
        this.status = status;
        this.createdAt = createdAt;
        this.completedAt = completedAt;
        this.totalBytes = totalBytes;
        this.transferredBytes = transferredBytes;
        this.speed = speed;
    }
    get progress(): number {
        if (this.totalBytes <= 0)
            return 0;
        return Math.min(this.transferredBytes / this.totalBytes, 1.0);
    }
    get eta(): number {
        if (this.speed <= 0)
            return -1;
        const remaining = this.totalBytes - this.transferredBytes;
        return remaining / this.speed;
    }
}
export class TransferHistory {
    id: string;
    peerDeviceName: string;
    isSender: boolean;
    fileCount: number;
    totalSize: number;
    timestamp: number;
    status: TransferStatus;
    fileNames: string[];
    constructor(id: string, peerDeviceName: string, isSender: boolean, fileCount: number, totalSize: number, timestamp: number, status: TransferStatus, fileNames: string[]) {
        this.id = id;
        this.peerDeviceName = peerDeviceName;
        this.isSender = isSender;
        this.fileCount = fileCount;
        this.totalSize = totalSize;
        this.timestamp = timestamp;
        this.status = status;
        this.fileNames = fileNames;
    }
}
