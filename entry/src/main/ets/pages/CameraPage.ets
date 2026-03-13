@Builder
export function CameraPageBuilder() {
  CameraPage()
}

@Component
export struct CameraPage {
  @Consume navPathStack: NavPathStack;
  @State inputText: string = '';

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

        // Input area (camera integration to be added later)
        Column({ space: 12 }) {
          Text('Enter or paste the math problem:')
            .fontSize(15).fontColor('#666666')

          TextArea({
            placeholder: 'Type or paste the math problem here...\n\nExample: Find the vertex of y = x² - 6x + 11',
            text: this.inputText
          })
            .width('100%')
            .height(200)
            .fontSize(15)
            .backgroundColor('#FFFFFF')
            .borderRadius(12)
            .onChange((value: string) => { this.inputText = value; })

          Button('Solve with AI')
            .width('100%').height(48)
            .backgroundColor(this.inputText.trim().length > 0 ? '#4E6EF2' : '#CCCCCC')
            .fontColor('#FFFFFF').fontSize(16).borderRadius(12)
            .enabled(this.inputText.trim().length > 0)
            .onClick(() => {
              this.navPathStack.pushPathByName('SolutionPage', this.inputText.trim());
            })
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
