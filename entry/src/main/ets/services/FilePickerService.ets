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
    const result: string[] = await documentPicker.select();
    const files: SelectableFile[] = [];
    for (const uri of result) {
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

  async pickImages(): Promise<SelectableFile[]> {
    const photoPicker = new picker.PhotoViewPicker();
    const photoResult = await photoPicker.select();
    const files: SelectableFile[] = [];
    const photoUris: string[] = photoResult.photoUris as string[];
    for (const uri of photoUris) {
      try {
        const fileInfo = await fileIo.stat(uri);
        files.push(new SelectableFile(uri, uri.split('/').pop() || 'image', fileInfo.size, 'image/*'));
      } catch (err) {
        hilog.error(0x0001, 'ToShare', 'Failed to get image info: %{public}s', JSON.stringify(err));
      }
    }
    return files;
  }

  async pickVideos(): Promise<SelectableFile[]> {
    const videoPicker = new picker.AudioViewPicker();
    const uris: string[] = await videoPicker.select();
    const files: SelectableFile[] = [];
    for (const uri of uris) {
      try {
        const fileInfo = await fileIo.stat(uri);
        files.push(new SelectableFile(uri, uri.split('/').pop() || 'video', fileInfo.size, 'video/*'));
      } catch (err) {
        hilog.error(0x0001, 'ToShare', 'Failed to get video info: %{public}s', JSON.stringify(err));
      }
    }
    return files;
  }

  async pickDocuments(): Promise<SelectableFile[]> {
    const documentPicker = new picker.DocumentViewPicker();
    const result: string[] = await documentPicker.select();
    const files: SelectableFile[] = [];
    for (const uri of result) {
      try {
        const fileInfo = await fileIo.stat(uri);
        const name = uri.split('/').pop() || 'document';
        files.push(new SelectableFile(uri, name, fileInfo.size, this.getMimeType(name)));
      } catch (err) {
        hilog.error(0x0001, 'ToShare', 'Failed to get document info: %{public}s', JSON.stringify(err));
      }
    }
    return files;
  }

  private getMimeType(fileName: string): string {
    const ext = fileName.split('.').pop()?.toLowerCase() || '';
    if (ext === 'jpg' || ext === 'jpeg') {
      return 'image/jpeg';
    }
    if (ext === 'png') {
      return 'image/png';
    }
    if (ext === 'gif') {
      return 'image/gif';
    }
    if (ext === 'webp') {
      return 'image/webp';
    }
    if (ext === 'mp4') {
      return 'video/mp4';
    }
    if (ext === 'mkv') {
      return 'video/x-matroska';
    }
    if (ext === 'pdf') {
      return 'application/pdf';
    }
    if (ext === 'doc') {
      return 'application/msword';
    }
    if (ext === 'docx') {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (ext === 'zip') {
      return 'application/zip';
    }
    if (ext === 'rar') {
      return 'application/vnd.rar';
    }
    if (ext === 'txt') {
      return 'text/plain';
    }
    return 'application/octet-stream';
  }
}
