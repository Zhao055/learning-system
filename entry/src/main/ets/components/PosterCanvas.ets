import { QuizResult } from '../model/ChapterModel';

@Component
export struct PosterCanvas {
  @Prop result: QuizResult = {
    chapterId: '',
    chapterTitle: '',
    knowledgePointId: '',
    knowledgePointTitle: '',
    totalQuestions: 1,
    correctCount: 0,
    answers: [],
    timestamp: 0
  };

  private getScoreColor(): string {
    const pct = this.result.correctCount / this.result.totalQuestions;
    if (pct >= 0.8) return '#4CAF50';
    if (pct >= 0.6) return '#FF9800';
    return '#F44336';
  }

  private getScoreEmoji(): string {
    const pct = this.result.correctCount / this.result.totalQuestions;
    if (pct === 1) return '🏆';
    if (pct >= 0.8) return '🌟';
    if (pct >= 0.6) return '👍';
    return '💪';
  }

  private getScoreMessage(): string {
    const pct = this.result.correctCount / this.result.totalQuestions;
    if (pct === 1) return 'Perfect Score!';
    if (pct >= 0.8) return 'Great Job!';
    if (pct >= 0.6) return 'Good Effort!';
    return 'Keep Practicing!';
  }

  build() {
    Column() {
      // Poster content
      Column({ space: 0 }) {
        // Header gradient
        Column() {
          Text('A-Level Math P1')
            .fontSize(14)
            .fontColor('rgba(255,255,255,0.8)')
          Text('Cambridge 9709')
            .fontSize(11)
            .fontColor('rgba(255,255,255,0.6)')
            .margin({ top: 2 })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 12 })
        .linearGradient({
          angle: 135,
          colors: [['#4E6EF2', 0], ['#7B68EE', 1]]
        })

        // Score section
        Column({ space: 6 }) {
          Text(this.getScoreEmoji())
            .fontSize(48)
          Text(`${this.result.correctCount} / ${this.result.totalQuestions}`)
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getScoreColor())
          Text(this.getScoreMessage())
            .fontSize(16)
            .fontColor('#666666')
          Text(`${Math.round((this.result.correctCount / this.result.totalQuestions) * 100)}% Correct`)
            .fontSize(14)
            .fontColor(this.getScoreColor())
            .margin({ top: 2 })
        }
        .width('100%')
        .padding({ top: 24, bottom: 20 })
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#FFFFFF')

        // Details
        Column({ space: 4 }) {
          Row() {
            Text('Topic').fontSize(12).fontColor('#999999')
            Blank()
            Text(this.result.knowledgePointTitle).fontSize(12).fontColor('#333333')
              .constraintSize({ maxWidth: '65%' }).textAlign(TextAlign.End)
          }.width('100%')

          Row() {
            Text('Chapter').fontSize(12).fontColor('#999999')
            Blank()
            Text(this.result.chapterTitle).fontSize(12).fontColor('#333333')
          }.width('100%').margin({ top: 4 })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })
        .backgroundColor('#F8F8F8')

        // Footer
        Row() {
          Text('A-Level Math P1 Helper')
            .fontSize(10)
            .fontColor('#AAAAAA')
          Blank()
          Text(new Date().toLocaleDateString())
            .fontSize(10)
            .fontColor('#AAAAAA')
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 8 })
        .backgroundColor('#FFFFFF')
      }
      .width(300)
      .borderRadius(16)
      .clip(true)
      .shadow({ radius: 12, color: 'rgba(0,0,0,0.1)', offsetX: 0, offsetY: 4 })
    }
    .id('posterCanvas')
  }
}
