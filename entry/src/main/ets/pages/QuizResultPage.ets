import { QuizResult } from '../model/ChapterModel';
import { ShareService } from '../service/ShareService';

@Component
export struct QuizResultPage {
  @Consume navPathStack: NavPathStack;
  @State result: QuizResult | undefined = undefined;
  @State showPoster: boolean = false;

  aboutToAppear(): void {
    const params = this.navPathStack.getParamByName('QuizResultPage') as QuizResult[];
    if (params && params.length > 0) {
      this.result = params[0];
    }
  }

  private getScoreColor(): string {
    if (!this.result) return '#999999';
    const pct = this.result.correctCount / this.result.totalQuestions;
    if (pct >= 0.8) return '#4CAF50';
    if (pct >= 0.6) return '#FF9800';
    return '#F44336';
  }

  private getScoreEmoji(): string {
    if (!this.result) return '';
    const pct = this.result.correctCount / this.result.totalQuestions;
    if (pct === 1) return '🏆';
    if (pct >= 0.8) return '🌟';
    if (pct >= 0.6) return '👍';
    return '💪';
  }

  private getScoreMessage(): string {
    if (!this.result) return '';
    const pct = this.result.correctCount / this.result.totalQuestions;
    if (pct === 1) return 'Perfect Score! Outstanding!';
    if (pct >= 0.8) return 'Great Job! Keep it up!';
    if (pct >= 0.6) return 'Good Effort! Room to improve.';
    return 'Keep Practicing! You\'ll get there!';
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
          .onClick(() => {
            // Pop back to chapter list
            this.navPathStack.popToName('KnowledgeCardPage');
          })

          Text('Quiz Results').fontSize(22).fontWeight(FontWeight.Bold).margin({ left: 16 })
        }
        .width('100%').padding({ left: 20, right: 20, top: 12, bottom: 12 })

        Scroll() {
          Column({ space: 20 }) {
            // Score card
            Column({ space: 8 }) {
              Text(this.getScoreEmoji())
                .fontSize(64)
              Text(`${this.result?.correctCount ?? 0} / ${this.result?.totalQuestions ?? 0}`)
                .fontSize(48)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getScoreColor())
              Text(this.getScoreMessage())
                .fontSize(18)
                .fontColor('#666666')
              Text(`${Math.round(((this.result?.correctCount ?? 0) / (this.result?.totalQuestions ?? 1)) * 100)}%`)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getScoreColor())
                .margin({ top: 4 })
            }
            .width('100%')
            .padding(32)
            .backgroundColor('#FFFFFF')
            .borderRadius(20)
            .alignItems(HorizontalAlign.Center)
            .shadow({ radius: 8, color: 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: 4 })

            // Details
            Column() {
              Text('Details').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333333')
              Column({ space: 0 }) {
                Row() {
                  Text('Topic').fontSize(14).fontColor('#999999')
                  Blank()
                  Text(this.result?.knowledgePointTitle ?? '').fontSize(14).fontColor('#333333')
                    .constraintSize({ maxWidth: '60%' }).textAlign(TextAlign.End)
                }
                .width('100%').padding({ top: 12, bottom: 12 })

                Divider().color('#F0F0F0')

                Row() {
                  Text('Chapter').fontSize(14).fontColor('#999999')
                  Blank()
                  Text(this.result?.chapterTitle ?? '').fontSize(14).fontColor('#333333')
                }
                .width('100%').padding({ top: 12, bottom: 12 })

                Divider().color('#F0F0F0')

                Row() {
                  Text('Correct').fontSize(14).fontColor('#999999')
                  Blank()
                  Text(`${this.result?.correctCount ?? 0}`).fontSize(14).fontColor('#4CAF50')
                }
                .width('100%').padding({ top: 12, bottom: 12 })

                Divider().color('#F0F0F0')

                Row() {
                  Text('Incorrect').fontSize(14).fontColor('#999999')
                  Blank()
                  Text(`${(this.result?.totalQuestions ?? 0) - (this.result?.correctCount ?? 0)}`)
                    .fontSize(14).fontColor('#F44336')
                }
                .width('100%').padding({ top: 12, bottom: 12 })
              }
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)

            // Action buttons
            Column({ space: 12 }) {
              Button('Share Poster 📤')
                .width('100%').height(48)
                .backgroundColor('#4E6EF2').fontColor('#FFFFFF')
                .fontSize(16).borderRadius(12)
                .onClick(async () => {
                  this.showPoster = true;
                })

              Button('Back to Home')
                .width('100%').height(48)
                .backgroundColor('#FFFFFF').fontColor('#4E6EF2')
                .fontSize(16).borderRadius(12)
                .border({ width: 1.5, color: '#4E6EF2' })
                .onClick(() => {
                  this.navPathStack.clear();
                })
            }
            .width('100%')
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
