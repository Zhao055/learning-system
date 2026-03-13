import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { OcrService } from '../service/OcrService';

@Builder
export function PhotoPreviewPageBuilder() {
  PhotoPreviewPage()
}

@Component
export struct PhotoPreviewPage {
  @Consume navPathStack: NavPathStack;
  @State photoUri: string = '';
  @State ocrText: string = '';
  @State isRecognizing: boolean = true;
  @State isEditing: boolean = false;

  aboutToAppear(): void {
    const params = this.navPathStack.getParamByName('PhotoPreviewPage') as string[];
    if (params && params.length > 0) {
      this.photoUri = params[0];
      this.recognizeText();
    }
  }

  private async recognizeText(): Promise<void> {
    this.isRecognizing = true;
    try {
      // Create PixelMap from URI
      const file = fileIo.openSync(this.photoUri, fileIo.OpenMode.READ_ONLY);
      const imageSource = image.createImageSource(file.fd);
      const pixelMap = await imageSource.createPixelMap();
      fileIo.closeSync(file.fd);

      const text = await OcrService.getInstance().recognizeText(pixelMap);
      this.ocrText = text;
      pixelMap.release();
    } catch (e) {
      console.error('OCR failed: ' + JSON.stringify(e));
      this.ocrText = '';
    }
    this.isRecognizing = false;
  }

  build() {
    NavDestination() {
      Column() {
        // Header
        Row() {
          Button({ type: ButtonType.Circle }) {
            Image($r('sys.media.ohos_ic_public_arrow_left'))
              .width(24).height(24).fillColor('#333333')
          }
          .width(40).height(40).backgroundColor('#F0F0F0')
          .onClick(() => { this.navPathStack.pop(); })

          Text('Photo Preview')
            .fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 16 })

          Blank()

          Button('Retake')
            .fontSize(14).fontColor('#4E6EF2').backgroundColor('#E8EEFF')
            .borderRadius(16).height(32)
            .onClick(() => { this.navPathStack.replacePath({ name: 'CameraPage', param: null }); })
        }
        .width('100%').padding({ left: 20, right: 20, top: 12, bottom: 12 })

        Scroll() {
          Column({ space: 16 }) {
            // Photo preview
            Image(this.photoUri)
              .width('100%')
              .height(250)
              .objectFit(ImageFit.Contain)
              .borderRadius(12)
              .backgroundColor('#F0F0F0')

            // OCR Result
            Column({ space: 8 }) {
              Row() {
                Text('Recognized Text')
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333333')
                Blank()
                if (!this.isRecognizing) {
                  Button(this.isEditing ? 'Done' : 'Edit')
                    .fontSize(13).fontColor('#4E6EF2').backgroundColor('#E8EEFF')
                    .borderRadius(12).height(28)
                    .onClick(() => { this.isEditing = !this.isEditing; })
                }
              }
              .width('100%')

              if (this.isRecognizing) {
                Column() {
                  LoadingProgress().width(36).height(36)
                  Text('Recognizing text...').fontSize(14).fontColor('#999999').margin({ top: 8 })
                }
                .width('100%').padding(32).alignItems(HorizontalAlign.Center)
              } else if (this.isEditing) {
                TextArea({ text: this.ocrText, placeholder: 'Enter or edit the math problem...' })
                  .width('100%')
                  .height(200)
                  .fontSize(15)
                  .backgroundColor('#FAFAFA')
                  .borderRadius(12)
                  .onChange((value: string) => { this.ocrText = value; })
              } else {
                Text(this.ocrText.length > 0 ? this.ocrText : 'No text recognized. Tap Edit to enter manually.')
                  .fontSize(15)
                  .fontColor(this.ocrText.length > 0 ? '#333333' : '#999999')
                  .lineHeight(24)
                  .width('100%')
                  .padding(16)
                  .backgroundColor('#FAFAFA')
                  .borderRadius(12)
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)

            // Solve button
            Button('Solve with AI 🤖')
              .width('100%').height(52)
              .backgroundColor(this.ocrText.trim().length > 0 ? '#4E6EF2' : '#CCCCCC')
              .fontColor('#FFFFFF').fontSize(17).fontWeight(FontWeight.Medium)
              .borderRadius(14)
              .enabled(this.ocrText.trim().length > 0 && !this.isRecognizing)
              .onClick(() => {
                this.navPathStack.pushPathByName('SolutionPage', this.ocrText.trim());
              })
          }
          .padding({ left: 20, right: 20, bottom: 40 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%').height('100%').backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
  }
}
