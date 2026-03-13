import { MiniMaxService } from '../service/MiniMaxService';

@Component
export struct HomePage {
  @Consume navPathStack: NavPathStack;
  @State private greeting: string = '';

  aboutToAppear(): void {
    const hour = new Date().getHours();
    if (hour < 12) {
      this.greeting = 'Good Morning! ☀️';
    } else if (hour < 18) {
      this.greeting = 'Good Afternoon! 📚';
    } else {
      this.greeting = 'Good Evening! 🌙';
    }
    MiniMaxService.getInstance().loadApiKey(getContext(this));
  }

  build() {
    NavDestination() {
      Column() {
        // Header
        Row() {
          Column() {
            Text(this.greeting)
              .fontSize(16)
              .fontColor('#666666')
            Text('A-Level Math P1')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ top: 4 })
            Text('Cambridge 9709')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Button({ type: ButtonType.Circle }) {
            Image($r('sys.media.ohos_ic_public_settings'))
              .width(24)
              .height(24)
              .fillColor('#666666')
          }
          .width(44)
          .height(44)
          .backgroundColor('#F0F0F0')
          .onClick(() => {
            this.navPathStack.pushPathByName('SettingsPage', null);
          })
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 16 })

        // Feature Cards
        Column({ space: 20 }) {
          // Card 1: Knowledge & Quiz
          Column() {
            Row() {
              Text('📖')
                .fontSize(40)
              Column() {
                Text('Knowledge & Quiz')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                Text('知识点学习 + 答题')
                  .fontSize(14)
                  .fontColor('rgba(255,255,255,0.8)')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 16 })
            }
            .width('100%')

            Text('Browse 37 knowledge points with visual cards, test yourself with 185 practice questions, and get AI-powered explanations.')
              .fontSize(14)
              .fontColor('rgba(255,255,255,0.9)')
              .margin({ top: 16 })
              .lineHeight(22)

            Row() {
              Text('8 Chapters')
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.7)')
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor('rgba(255,255,255,0.2)')
                .borderRadius(12)
              Text('37 Topics')
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.7)')
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor('rgba(255,255,255,0.2)')
                .borderRadius(12)
                .margin({ left: 8 })
              Text('185 Questions')
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.7)')
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor('rgba(255,255,255,0.2)')
                .borderRadius(12)
                .margin({ left: 8 })
            }
            .width('100%')
            .margin({ top: 16 })

            Button('Start Learning →')
              .width('100%')
              .height(48)
              .backgroundColor('rgba(255,255,255,0.25)')
              .fontColor('#FFFFFF')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .borderRadius(12)
              .margin({ top: 20 })
              .onClick(() => {
                this.navPathStack.pushPathByName('ChapterListPage', null);
              })
          }
          .width('100%')
          .padding(24)
          .borderRadius(20)
          .linearGradient({
            angle: 135,
            colors: [['#4E6EF2', 0], ['#7B68EE', 1]]
          })

          // Card 2: Photo Solver
          Column() {
            Row() {
              Text('📷')
                .fontSize(40)
              Column() {
                Text('Photo Solver')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                Text('拍照解题')
                  .fontSize(14)
                  .fontColor('rgba(255,255,255,0.8)')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 16 })
            }
            .width('100%')

            Text('Take a photo of any A-Level math problem. AI will recognize the text and provide step-by-step solutions.')
              .fontSize(14)
              .fontColor('rgba(255,255,255,0.9)')
              .margin({ top: 16 })
              .lineHeight(22)

            Row() {
              Text('OCR Recognition')
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.7)')
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor('rgba(255,255,255,0.2)')
                .borderRadius(12)
              Text('AI Solution')
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.7)')
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor('rgba(255,255,255,0.2)')
                .borderRadius(12)
                .margin({ left: 8 })
            }
            .width('100%')
            .margin({ top: 16 })

            Button('Take Photo →')
              .width('100%')
              .height(48)
              .backgroundColor('rgba(255,255,255,0.25)')
              .fontColor('#FFFFFF')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .borderRadius(12)
              .margin({ top: 20 })
              .onClick(() => {
                this.navPathStack.pushPathByName('CameraPage', null);
              })
          }
          .width('100%')
          .padding(24)
          .borderRadius(20)
          .linearGradient({
            angle: 135,
            colors: [['#FF6B6B', 0], ['#FF8E53', 1]]
          })
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 32 })
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
  }
}
