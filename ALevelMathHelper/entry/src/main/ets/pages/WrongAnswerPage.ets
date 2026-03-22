import { ProgressService } from '../service/ProgressService';
import { QuestionRepository } from '../data/QuestionRepository';
import { ProgressRecord } from '../model/ChapterModel';
import { getPaper, getSubjectForPaper } from '../data/SubjectData';

interface WrongAnswerItem {
  record: ProgressRecord;
  questionStem: string;
  correctAnswer: string;
  userAnswer: string;
  explanation: string;
  paperName: string;
  chapterTitle: string;
  kpTitle: string;
  options: string[];
}

interface PaperGroup {
  paperId: string;
  paperName: string;
  subjectColor: string;
  items: WrongAnswerItem[];
}

@Builder
export function WrongAnswerPageBuilder() {
  WrongAnswerPage()
}

@Component
export struct WrongAnswerPage {
  @Consume navPathStack: NavPathStack;
  @State paperGroups: PaperGroup[] = [];
  @State expandedId: string = '';
  @State totalWrong: number = 0;

  aboutToAppear(): void {
    this.loadWrongAnswers();
  }

  private loadWrongAnswers(): void {
    const service = ProgressService.getInstance();
    const allWrong = service.getAllWrongAnswers();
    const repo = QuestionRepository.getInstance();

    // Group by paper
    const groupMap: Map<string, WrongAnswerItem[]> = new Map();
    for (const record of allWrong) {
      const kp = repo.getKnowledgePoint(record.paperId, record.chapterId, record.kpId);
      const chapter = repo.getChapter(record.paperId, record.chapterId);
      const question = kp?.questions.find(q => q.id === record.questionId);
      if (!question) continue;

      const paper = getPaper(record.paperId);
      const item: WrongAnswerItem = {
        record: record,
        questionStem: question.stem,
        correctAnswer: question.options[question.correctIndex] ?? '',
        userAnswer: question.options[record.selectedIndex] ?? '',
        explanation: question.explanation,
        paperName: paper?.name ?? record.paperId,
        chapterTitle: chapter?.title ?? '',
        kpTitle: kp?.title ?? '',
        options: question.options
      };

      const existing = groupMap.get(record.paperId);
      if (existing) {
        existing.push(item);
      } else {
        groupMap.set(record.paperId, [item]);
      }
    }

    const groups: PaperGroup[] = [];
    groupMap.forEach((items: WrongAnswerItem[], paperId: string) => {
      const subject = getSubjectForPaper(paperId);
      groups.push({
        paperId: paperId,
        paperName: getPaper(paperId)?.name ?? paperId,
        subjectColor: subject?.color ?? '#4E6EF2',
        items: items
      });
    });

    this.paperGroups = groups;
    this.totalWrong = allWrong.length;
  }

  private async removeItem(item: WrongAnswerItem): Promise<void> {
    const service = ProgressService.getInstance();
    await service.removeWrongAnswer(getContext(this), item.record.paperId, item.record.chapterId,
      item.record.kpId, item.record.questionId);
    this.loadWrongAnswers();
  }

  private async clearAll(): Promise<void> {
    const service = ProgressService.getInstance();
    await service.clearWrongAnswers(getContext(this), '');
    this.loadWrongAnswers();
  }

  private getItemUniqueId(item: WrongAnswerItem): string {
    return `${item.record.paperId}_${item.record.chapterId}_${item.record.kpId}_${item.record.questionId}`;
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

          Column() {
            Text('Wrong Answer Book')
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333333')
            Text(`${this.totalWrong} questions to review`)
              .fontSize(13).fontColor('#999999').margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 16 })
          .layoutWeight(1)

          if (this.totalWrong > 0) {
            Button('Clear All')
              .fontSize(13).fontColor('#F44336')
              .backgroundColor('#FFEBEE')
              .borderRadius(16).height(32)
              .onClick(() => {
                AlertDialog.show({
                  title: 'Clear All',
                  message: 'Remove all wrong answers from the book?',
                  primaryButton: {
                    value: 'Cancel',
                    action: () => {}
                  },
                  secondaryButton: {
                    value: 'Clear',
                    action: () => { this.clearAll(); }
                  }
                });
              })
          }
        }
        .width('100%').padding({ left: 20, right: 20, top: 12, bottom: 12 })

        if (this.totalWrong === 0) {
          // Empty state
          Column({ space: 12 }) {
            Text('🎉')
              .fontSize(64)
            Text('No Wrong Answers!')
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#333333')
            Text('Keep up the great work. All your answers are correct.')
              .fontSize(14).fontColor('#999999').textAlign(TextAlign.Center)
              .padding({ left: 40, right: 40 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          // Wrong answers grouped by paper
          List({ space: 16 }) {
            ForEach(this.paperGroups, (group: PaperGroup) => {
              ListItem() {
                Column({ space: 10 }) {
                  // Paper header
                  Row() {
                    Column()
                      .width(4).height(20).borderRadius(2)
                      .backgroundColor(group.subjectColor)
                    Text(group.paperName)
                      .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333333')
                      .margin({ left: 10 })
                    Blank()
                    Text(`${group.items.length} wrong`)
                      .fontSize(13).fontColor('#F44336')
                      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                      .backgroundColor('#FFEBEE').borderRadius(10)
                  }
                  .width('100%')

                  // Items in this paper group
                  ForEach(group.items, (item: WrongAnswerItem) => {
                    Column() {
                      // Collapsed view
                      Row() {
                        Column() {
                          Text(item.questionStem)
                            .fontSize(14).fontColor('#333333')
                            .maxLines(this.expandedId === this.getItemUniqueId(item) ? 100 : 2)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                          Row({ space: 8 }) {
                            Text(item.kpTitle)
                              .fontSize(11).fontColor('#4E6EF2')
                              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                              .backgroundColor('#E8EEFF').borderRadius(4)
                              .maxLines(1)
                              .constraintSize({ maxWidth: '60%' })
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                          }
                          .margin({ top: 6 })
                        }
                        .layoutWeight(1)

                        Image($r('sys.media.ohos_ic_public_arrow_right'))
                          .width(16).height(16).fillColor('#CCCCCC')
                          .rotate({ angle: this.expandedId === this.getItemUniqueId(item) ? 90 : 0 })
                      }
                      .width('100%')
                      .onClick(() => {
                        if (this.expandedId === this.getItemUniqueId(item)) {
                          this.expandedId = '';
                        } else {
                          this.expandedId = this.getItemUniqueId(item);
                        }
                      })

                      // Expanded details
                      if (this.expandedId === this.getItemUniqueId(item)) {
                        Column({ space: 8 }) {
                          Divider().color('#F0F0F0').margin({ top: 8, bottom: 4 })

                          Row() {
                            Text('Your answer: ')
                              .fontSize(13).fontColor('#999999')
                            Text(item.userAnswer)
                              .fontSize(13).fontColor('#F44336').fontWeight(FontWeight.Medium)
                          }
                          .width('100%')

                          Row() {
                            Text('Correct answer: ')
                              .fontSize(13).fontColor('#999999')
                            Text(item.correctAnswer)
                              .fontSize(13).fontColor('#4CAF50').fontWeight(FontWeight.Medium)
                          }
                          .width('100%')

                          // Explanation
                          Column() {
                            Text('Explanation')
                              .fontSize(12).fontWeight(FontWeight.Bold).fontColor('#4E6EF2')
                            Text(item.explanation)
                              .fontSize(13).fontColor('#333333').lineHeight(20).margin({ top: 4 })
                          }
                          .width('100%')
                          .padding(10)
                          .backgroundColor('#F0F4FF')
                          .borderRadius(8)

                          // Action buttons
                          Row({ space: 10 }) {
                            Button('Re-quiz this KP')
                              .fontSize(13).fontColor('#FFFFFF')
                              .backgroundColor('#4E6EF2').borderRadius(16).height(32)
                              .layoutWeight(1)
                              .onClick(() => {
                                const params: string[] = [
                                  item.record.paperId,
                                  item.record.chapterId,
                                  item.record.kpId
                                ];
                                this.navPathStack.pushPathByName('QuizPage', params);
                              })
                            Button('Remove')
                              .fontSize(13).fontColor('#F44336')
                              .backgroundColor('#FFEBEE').borderRadius(16).height(32)
                              .onClick(() => { this.removeItem(item); })
                          }
                          .width('100%')
                          .margin({ top: 4 })
                        }
                        .width('100%')
                      }
                    }
                    .width('100%')
                    .padding(14)
                    .backgroundColor('#FFFFFF')
                    .borderRadius(12)
                    .shadow({ radius: 2, color: 'rgba(0,0,0,0.04)', offsetX: 0, offsetY: 1 })
                  }, (item: WrongAnswerItem) => this.getItemUniqueId(item))
                }
                .width('100%')
              }
            }, (group: PaperGroup) => group.paperId)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 20, right: 20, bottom: 20 })
          .scrollBar(BarState.Off)
        }
      }
      .width('100%').height('100%').backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
  }
}
