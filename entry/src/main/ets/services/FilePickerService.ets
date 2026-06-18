import { SelectableFile } from '../models/FileTransfer';
import { picker } from '@kit.CoreFileKit';
import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class FilePickerService {
  private static instance: FilePickerService;

  static getInstance(): FilePickerService {
    if (!FilePickerService.instance) {
      FilePickerService.instance = new FilePickerService();
    }
    return FilePickerService.instance;
  }

  async pickFiles(): Promise<SelectableFile[]> {
    const documentPicker = new picker.DocumentViewPicker();
    try {
      const result: string[] = await documentPicker.select();
      return await this.resolveUris(result);
    } catch (err) {
      hilog.error(0x0001, 'ToShare', 'Pick files failed: %{public}s', JSON.stringify(err));
      return [];
    }
  }

  /**
   * 选择图片 — 使用 picker.PhotoViewPicker（API 23 兼容）
   * 注: PhotoViewPicker 在 API 23 标记为 deprecated，推荐使用 photoAccessHelper，
   * 但当前 SDK 中 photoAccessHelper 的 getPhotoViewPicker() 尚不可用，
   * 此处继续使用 picker 方案，功能完全正常。
   */
  async pickImages(maxCount: number = 1): Promise<SelectableFile[]> {
    try {
      const photoOptions = new picker.PhotoSelectOptions();
      photoOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoOptions.maxSelectNumber = maxCount;
      const photoPicker = new picker.PhotoViewPicker();
      const result = await photoPicker.select(photoOptions);
      const uris: string[] = result.photoUris as string[];
      return await this.resolveUris(uris);
    } catch (err) {
      hilog.error(0x0001, 'ToShare', 'Pick images failed: %{public}s', JSON.stringify(err));
      return [];
    }
  }

  async pickVideos(): Promise<SelectableFile[]> {
    try {
      const audioPicker = new picker.AudioViewPicker();
      const uris: string[] = await audioPicker.select();
      return await this.resolveUris(uris);
    } catch (err) {
      hilog.error(0x0001, 'ToShare', 'Pick videos failed: %{public}s', JSON.stringify(err));
      return [];
    }
  }

  async pickDocuments(): Promise<SelectableFile[]> {
    return await this.pickFiles();
  }

  private async resolveUris(uris: string[]): Promise<SelectableFile[]> {
    const files: SelectableFile[] = [];
    for (const uri of uris) {
      try {
        const fileInfo = await fileIo.stat(uri);
        const name = uri.split('/').pop() || 'unknown';
        files.push(new SelectableFile(uri, name, fileInfo.size, this.getMimeType(name)));
      } catch (err) {
        hilog.error(0x0001, 'ToShare', 'Failed to get file info: %{public}s', JSON.stringify(err));
      }
    }
    return files;
  }

  private getMimeType(fileName: string): string {
    const ext = fileName.split('.').pop()?.toLowerCase() || '';
    const mimeMap: Record<string, string> = {
      'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png',
      'gif': 'image/gif', 'webp': 'image/webp', 'mp4': 'video/mp4',
      'mkv': 'video/x-matroska', 'pdf': 'application/pdf',
      'doc': 'application/msword', 'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'zip': 'application/zip', 'rar': 'application/vnd.rar', 'txt': 'text/plain'
    };
    return mimeMap[ext] || 'application/octet-stream';
  }
}
