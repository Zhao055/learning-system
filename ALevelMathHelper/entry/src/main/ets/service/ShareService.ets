import { componentSnapshot } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';

export class ShareService {
  private static instance: ShareService;

  private constructor() {}

  static getInstance(): ShareService {
    if (!ShareService.instance) {
      ShareService.instance = new ShareService();
    }
    return ShareService.instance;
  }

  async captureComponent(componentId: string): Promise<image.PixelMap | null> {
    try {
      const pixelMap = await componentSnapshot.get(componentId);
      return pixelMap;
    } catch (e) {
      console.error('Snapshot failed: ' + JSON.stringify(e));
      return null;
    }
  }

  async saveToFile(context: Context, pixelMap: image.PixelMap): Promise<string> {
    try {
      const filesDir = context.filesDir;
      const fileName = `poster_${Date.now()}.png`;
      const filePath = `${filesDir}/${fileName}`;

      const packOpts: image.PackingOption = {
        format: 'image/png',
        quality: 100
      };
      const packer = image.createImagePacker();
      const data = await packer.packing(pixelMap, packOpts);

      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
      fileIo.writeSync(file.fd, data);
      fileIo.closeSync(file.fd);

      return filePath;
    } catch (e) {
      console.error('Save failed: ' + JSON.stringify(e));
      return '';
    }
  }

  async shareImage(context: Context, filePath: string): Promise<void> {
    try {
      const shareData: systemShare.SharedData = new systemShare.SharedData({
        utType: utd.UniformDataType.IMAGE,
        uri: `file://${filePath}`
      });
      const controller = new systemShare.ShareController(context);
      await controller.show(shareData);
    } catch (e) {
      console.error('Share failed: ' + JSON.stringify(e));
    }
  }
}
