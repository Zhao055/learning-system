import { textRecognition } from '@kit.CoreVisionKit';
import { image } from '@kit.ImageKit';

export class OcrService {
  private static instance: OcrService;

  private constructor() {}

  static getInstance(): OcrService {
    if (!OcrService.instance) {
      OcrService.instance = new OcrService();
    }
    return OcrService.instance;
  }

  async recognizeText(pixelMap: image.PixelMap): Promise<string> {
    try {
      const request: textRecognition.VisionInfo = {
        pixelMap: pixelMap
      };
      const result = await textRecognition.recognizeText(request);
      if (result && result.value) {
        return result.value;
      }
      return '';
    } catch (e) {
      console.error('OCR failed: ' + JSON.stringify(e));
      return '';
    }
  }
}
