import type { TransferStatus } from './Enums';
export class FileTransferItem {
    id: string;
    fileName: string;
    fileSize: number;
    previewPath: string;
    transferredBytes: number;
    status: TransferStatus;
    constructor(id: string, fileName: string, fileSize: number, previewPath: string, transferredBytes: number, status: TransferStatus) {
        this.id = id;
        this.fileName = fileName;
        this.fileSize = fileSize;
        this.previewPath = previewPath;
        this.transferredBytes = transferredBytes;
        this.status = status;
    }
    get progress(): number {
        if (this.fileSize <= 0)
            return 0;
        return Math.min(this.transferredBytes / this.fileSize, 1.0);
    }
}
export class SelectableFile {
    path: string;
    name: string;
    size: number;
    mimeType: string;
    constructor(path: string, name: string, size: number, mimeType: string) {
        this.path = path;
        this.name = name;
        this.size = size;
        this.mimeType = mimeType;
    }
}
export class FileMetadata {
    name: string;
    size: number;
    mimeType: string;
    modifiedDate: number;
    hash: string;
    constructor(name: string, size: number, mimeType: string, modifiedDate: number, hash: string) {
        this.name = name;
        this.size = size;
        this.mimeType = mimeType;
        this.modifiedDate = modifiedDate;
        this.hash = hash;
    }
}
export class FilePreview {
    thumbnailPath: string;
    isImage: boolean;
    isVideo: boolean;
    isDocument: boolean;
    constructor(thumbnailPath: string, isImage: boolean, isVideo: boolean, isDocument: boolean) {
        this.thumbnailPath = thumbnailPath;
        this.isImage = isImage;
        this.isVideo = isVideo;
        this.isDocument = isDocument;
    }
}
