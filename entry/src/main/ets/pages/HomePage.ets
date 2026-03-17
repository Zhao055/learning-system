import { MiniMaxService } from '../service/MiniMaxService';
import { ProgressService } from '../service/ProgressService';

@Builder
export function HomePageBuilder() {
  HomePage()
}

@Component
export struct HomePage {
  @Consume navPathStack: NavPathStack;
  @State greeting: string = '';
  @State totalAnswered: number = 0;
  @State totalCorrect: number = 0;
  @State accuracy: number = 0;
  @State wrongCount: number = 0;

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
    this.refreshStats();
  }

  onPageShow(): void {
    this.refreshStats();
  }

  private refreshStats(): void {
    const service = ProgressService.getInstance();
    const stats = service.getTotalStats();
    this.totalAnswered = stats.totalAnswered;
    this.totalCorrect = stats.totalCorrect;
    this.accuracy = stats.accuracy;
    this.wrongCount = service.getWrongAnswerCount();
  }

  build() {
    NavDestination() {
      Column() {
        // Header
        Row() {
          Image($rawfile('logo.jpeg'))
            .width(52)
            .height(52)
            .borderRadius(12)
            .objectFit(ImageFit.Cover)

          Column() {
            Text(this.greeting)
              .fontSize(14)
              .fontColor('#666666')
            Text('A-Level Helper')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ top: 2 })
            Text('Cambridge International')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 1 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })

          Blank()

          Button({ type: ButtonType.Circle }) {
            Text('⚙')
              .fontSize(22)
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

        Scroll() {
        Column({ space: 20 }) {
          // Stats summary bar
          if (this.totalAnswered > 0) {
            Row() {
              Column() {
                Text(`${this.totalAnswered}`)
                  .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#4E6EF2')
                Text('Answered')
                  .fontSize(11).fontColor('#999999').margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)

              Column()
                .width(1).height(30).backgroundColor('#E0E0E0')

              Column() {
                Text(`${this.totalCorrect}`)
                  .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#4CAF50')
                Text('Correct')
                  .fontSize(11).fontColor('#999999').margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)

              Column()
                .width(1).height(30).backgroundColor('#E0E0E0')

              Column() {
                Text(`${this.accuracy}%`)
                  .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#FF9800')
                Text('Accuracy')
                  .fontSize(11).fontColor('#999999').margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)

              Column()
                .width(1).height(30).backgroundColor('#E0E0E0')

              Column() {
                Text(`${this.wrongCount}`)
                  .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#F44336')
                Text('Wrong')
                  .fontSize(11).fontColor('#999999').margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Center)
            }
            .width('100%')
            .padding({ top: 16, bottom: 16 })
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetX: 0, offsetY: 2 })
          }

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

            Text('Browse knowledge points with visual cards, test yourself with practice questions, and get AI-powered explanations across 3 subjects.')
              .fontSize(14)
              .fontColor('rgba(255,255,255,0.9)')
              .margin({ top: 16 })
              .lineHeight(22)

            Row() {
              Text('Math 9709')
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.7)')
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor('rgba(255,255,255,0.2)')
                .borderRadius(12)
              Text('Bio 9700')
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.7)')
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor('rgba(255,255,255,0.2)')
                .borderRadius(12)
                .margin({ left: 8 })
              Text('Psych 9990')
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
                this.navPathStack.pushPathByName('SubjectSelectionPage', null);
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

            Text('Take a photo of any A-Level problem. AI will recognize the text and provide step-by-step solutions.')
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

          // Card 3: Wrong Answer Book
          Column() {
            Row() {
              Text('📝')
                .fontSize(40)
              Column() {
                Text('Wrong Answer Book')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                Text('Review & re-practice mistakes')
                  .fontSize(14)
                  .fontColor('rgba(255,255,255,0.8)')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 16 })

              Blank()

              if (this.wrongCount > 0) {
                Text(`${this.wrongCount}`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#F44336')
                  .width(32).height(32)
                  .textAlign(TextAlign.Center)
                  .backgroundColor('#FFFFFF')
                  .borderRadius(16)
              }
            }
            .width('100%')

            Text('Review questions you got wrong, see explanations, and re-quiz to strengthen weak areas.')
              .fontSize(14)
              .fontColor('rgba(255,255,255,0.9)')
              .margin({ top: 16 })
              .lineHeight(22)

            Button('Open Wrong Answer Book →')
              .width('100%')
              .height(48)
              .backgroundColor('rgba(255,255,255,0.25)')
              .fontColor('#FFFFFF')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .borderRadius(12)
              .margin({ top: 20 })
              .onClick(() => {
                this.navPathStack.pushPathByName('WrongAnswerPage', null);
              })
          }
          .width('100%')
          .padding(24)
          .borderRadius(20)
          .linearGradient({
            angle: 135,
            colors: [['#7B1FA2', 0], ['#E040FB', 1]]
          })
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 32, bottom: 40 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
  }
}
