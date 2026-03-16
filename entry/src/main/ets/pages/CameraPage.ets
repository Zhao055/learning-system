import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { MiniMaxService } from '../service/MiniMaxService';

@Builder
export function CameraPageBuilder() {
  CameraPage()
}

@Component
export struct CameraPage {
  @Consume navPathStack: NavPathStack;
  @State inputText: string = '';
  @State showTextInput: boolean = false;

  private async openPhotoPicker(): Promise<void> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const result = await picker.select(options);
      if (result.photoUris && result.photoUris.length > 0) {
        this.navPathStack.pushPathByName('PhotoPreviewPage', result.photoUris[0]);
      }
    } catch (e) {
      console.error('PhotoPicker failed: ' + JSON.stringify(e));
    }
  }

  private checkApiKeyAndSolve(): void {
    if (!MiniMaxService.getInstance().hasApiKey()) {
      AlertDialog.show({
        title: 'API Key Required',
        message: 'Please configure your MiniMax API Key in Settings first.',
        primaryButton: {
          value: 'Go to Settings',
          action: () => {
            this.navPathStack.pushPathByName('SettingsPage', null);
          }
        },
        secondaryButton: {
          value: 'Cancel',
          action: () => {}
        }
      });
      return;
    }
    this.navPathStack.pushPathByName('SolutionPage', this.inputText.trim());
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

          Text('Photo Solver')
            .fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 16 })
        }
        .width('100%').padding({ left: 20, right: 20, top: 12, bottom: 12 })

        Column({ space: 20 }) {
          // Photo picker button (primary)
          Column({ space: 12 }) {
            Image($r('sys.media.ohos_ic_public_albums'))
              .width(56).height(56).fillColor('#4E6EF2')

            Text('Select from Album')
              .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#333333')

            Text('Choose a photo of a math problem to solve')
              .fontSize(14).fontColor('#999999').textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding(32)
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .alignItems(HorizontalAlign.Center)
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetX: 0, offsetY: 2 })
          .onClick(() => { this.openPhotoPicker(); })

          // Divider
          Row() {
            Column().height(1).layoutWeight(1).backgroundColor('#E0E0E0')
            Text('OR').fontSize(13).fontColor('#999999').margin({ left: 16, right: 16 })
            Column().height(1).layoutWeight(1).backgroundColor('#E0E0E0')
          }
          .width('100%')

          // Text input toggle
          if (!this.showTextInput) {
            Button('Type Problem Manually')
              .width('100%').height(44)
              .backgroundColor('#F5F5F5').fontColor('#4E6EF2')
              .fontSize(15).borderRadius(12)
              .onClick(() => { this.showTextInput = true; })
          }

          // Text input area (secondary)
          if (this.showTextInput) {
            Column({ space: 12 }) {
              Text('Enter or paste the problem:')
                .fontSize(15).fontColor('#666666')

              TextArea({
                placeholder: 'Type or paste the problem here...\n\nExample: Find the vertex of y = x^2 - 6x + 11',
                text: this.inputText
              })
                .width('100%')
                .height(160)
                .fontSize(15)
                .backgroundColor('#FFFFFF')
                .borderRadius(12)
                .onChange((value: string) => { this.inputText = value; })

              Button('Solve with AI')
                .width('100%').height(48)
                .backgroundColor(this.inputText.trim().length > 0 ? '#4E6EF2' : '#CCCCCC')
                .fontColor('#FFFFFF').fontSize(16).borderRadius(12)
                .enabled(this.inputText.trim().length > 0)
                .onClick(() => { this.checkApiKeyAndSolve(); })
            }
            .width('100%')
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 20 })
        .layoutWeight(1)
      }
      .width('100%').height('100%').backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
  }
}
