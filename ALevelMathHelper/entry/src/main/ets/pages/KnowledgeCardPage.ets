import { QuestionRepository } from '../data/QuestionRepository';
import { Chapter, KnowledgePoint, KpProgress } from '../model/ChapterModel';
import { ProgressService } from '../service/ProgressService';

@Builder
export function KnowledgeCardPageBuilder() {
  KnowledgeCardPage()
}

@Component
export struct KnowledgeCardPage {
  @Consume navPathStack: NavPathStack;
  @State chapter: Chapter | undefined = undefined;
  @State selectedKP: KnowledgePoint | undefined = undefined;
  @State showImagePreview: boolean = false;
  @State imageScale: number = 1;
  @State kpProgressMap: Map<string, KpProgress> = new Map();
  private paperId: string = '';

  aboutToAppear(): void {
    const params = this.navPathStack.getParamByName('KnowledgeCardPage') as Object[];
    if (params && params.length > 0) {
      const p = params[0] as string[];
      this.paperId = p[0];
      const chapterId = p[1];
      this.chapter = QuestionRepository.getInstance().getChapter(this.paperId, chapterId);
      this.refreshProgress();
    }
  }

  onPageShow(): void {
    this.refreshProgress();
  }

  private refreshProgress(): void {
    const service = ProgressService.getInstance();
    const chapterId = this.chapter?.id ?? '';
    const kps = this.chapter?.knowledgePoints ?? [];
    const newMap = new Map<string, KpProgress>();
    for (const kp of kps) {
      newMap.set(kp.id, service.getKpProgress(this.paperId, chapterId, kp.id));
    }
    this.kpProgressMap = newMap;
  }

  private getKpProgressText(kpId: string): string {
    const prog = this.kpProgressMap.get(kpId);
    if (!prog || prog.attempted === 0) return '';
    return `${prog.correct}/${prog.attempted} correct`;
  }

  build() {
    NavDestination() {
      Stack() {
        Column() {
          // Title bar
          Row() {
            Button({ type: ButtonType.Circle }) {
              Image($r('sys.media.ohos_ic_public_arrow_left'))
                .width(24)
                .height(24)
                .fillColor('#333333')
            }
            .width(40)
            .height(40)
            .backgroundColor('#F0F0F0')
            .onClick(() => {
              this.navPathStack.pop();
            })

            Text(this.chapter?.title ?? 'Knowledge Points')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .margin({ left: 16 })
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 12, bottom: 12 })

          // Knowledge point list
          List({ space: 12 }) {
            ForEach(this.chapter?.knowledgePoints ?? [], (kp: KnowledgePoint) => {
              ListItem() {
                Column() {
                  // KP image thumbnail
                  if (kp.image && kp.image.length > 0) {
                    Image($rawfile(`images/${kp.image}`))
                      .width('100%')
                      .height(180)
                      .borderRadius({ topLeft: 16, topRight: 16 })
                      .objectFit(ImageFit.Cover)
                      .onClick(() => {
                        this.selectedKP = kp;
                        this.showImagePreview = true;
                        this.imageScale = 1;
                      })
                  } else {
                    Column() {
                      Text('🖼️')
                        .fontSize(40)
                      Text('Image coming soon')
                        .fontSize(14)
                        .fontColor('#999999')
                        .margin({ top: 8 })
                    }
                    .width('100%')
                    .height(180)
                    .borderRadius({ topLeft: 16, topRight: 16 })
                    .backgroundColor('#F0F0F0')
                    .justifyContent(FlexAlign.Center)
                  }

                  // KP info
                  Column() {
                    Text(`${kp.id} ${kp.title}`)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#333333')
                    Text(kp.titleCn)
                      .fontSize(13)
                      .fontColor('#999999')
                      .margin({ top: 4 })

                    Row({ space: 8 }) {
                      Text(`${kp.questions.length} questions`)
                        .fontSize(12)
                        .fontColor('#4E6EF2')
                      if (this.getKpProgressText(kp.id).length > 0) {
                        Text(this.getKpProgressText(kp.id))
                          .fontSize(11)
                          .fontColor('#4CAF50')
                          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                          .backgroundColor('#E8F5E9')
                          .borderRadius(4)
                      }
                    }
                    .margin({ top: 6 })

                    Row() {
                      Blank()

                      Button('Start Quiz →')
                        .fontSize(14)
                        .fontColor('#FFFFFF')
                        .backgroundColor('#4E6EF2')
                        .borderRadius(20)
                        .height(36)
                        .onClick(() => {
                          const params: string[] = [this.paperId, this.chapter?.id ?? '', kp.id];
                          this.navPathStack.pushPathByName('QuizPage', params);
                        })
                    }
                    .width('100%')
                    .margin({ top: 12 })
                    .alignItems(VerticalAlign.Center)
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 12, bottom: 16 })
                }
                .width('100%')
                .backgroundColor('#FFFFFF')
                .borderRadius(16)
                .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetX: 0, offsetY: 2 })
              }
            }, (kp: KnowledgePoint) => kp.id)
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 20, right: 20, bottom: 20 })
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')

        // Full-screen image preview overlay
        if (this.showImagePreview && this.selectedKP) {
          Column() {
            // Top bar with close button
            Row() {
              Text(`${this.selectedKP?.id ?? ''} ${this.selectedKP?.title ?? ''}`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Button({ type: ButtonType.Circle }) {
                Text('✕')
                  .fontSize(18)
                  .fontColor('#FFFFFF')
              }
              .width(36)
              .height(36)
              .backgroundColor('rgba(255,255,255,0.2)')
              .onClick(() => {
                this.showImagePreview = false;
              })
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 8 })

            // Zoomable image - takes full remaining space
            if ((this.selectedKP?.image?.length ?? 0) > 0) {
              Image($rawfile(`images/${this.selectedKP?.image ?? ''}`))
                .width('100%')
                .layoutWeight(1)
                .objectFit(ImageFit.Contain)
                .scale({ x: this.imageScale, y: this.imageScale })
                .gesture(
                  GestureGroup(GestureMode.Exclusive,
                    PinchGesture({ fingers: 2 })
                      .onActionUpdate((event: GestureEvent) => {
                        this.imageScale = Math.max(0.5, Math.min(5.0, event.scale));
                      })
                      .onActionEnd(() => {
                        if (this.imageScale < 1) {
                          this.imageScale = 1;
                        }
                      }),
                    TapGesture({ count: 2 })
                      .onAction(() => {
                        if (this.imageScale > 1) {
                          this.imageScale = 1;
                        } else {
                          this.imageScale = 2.5;
                        }
                      }),
                    SwipeGesture({ direction: SwipeDirection.Vertical })
                      .onAction(() => {
                        this.showImagePreview = false;
                      })
                  )
                )
            }

            // Bottom info
            Text(this.selectedKP?.titleCn ?? '')
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.6)')
              .padding({ left: 20, right: 20, bottom: 16, top: 8 })
          }
          .width('100%')
          .height('100%')
          .backgroundColor('#000000')
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }
}
