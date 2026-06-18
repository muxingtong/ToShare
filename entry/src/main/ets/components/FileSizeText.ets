import { FileSizeFormatter } from '../utils/FileSizeFormatter';

@Component
export struct FileSizeText {
  @Prop size: number = 0;

  build() {
    Text(FileSizeFormatter.formatSize(this.size))
      .fontSize(14)
      .fontColor('#49454F')
  }
}
