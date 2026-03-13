import { QuestionRepository } from '../data/QuestionRepository';
import { Chapter, KnowledgePoint } from '../model/ChapterModel';

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

  aboutToAppear(): void {
    const params = this.navPathStack.getParamByName('KnowledgeCardPage') as string[];
    if (params && params.length > 0) {
      const chapterId = params[0];
      this.chapter = QuestionRepository.getInstance().getChapter(chapterId);
    }
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

                    Row() {
                      Text(`${kp.questions.length} questions`)
                        .fontSize(12)
                        .fontColor('#4E6EF2')

                      Blank()

                      Button('Start Quiz →')
                        .fontSize(14)
                        .fontColor('#FFFFFF')
                        .backgroundColor('#4E6EF2')
                        .borderRadius(20)
                        .height(36)
                        .onClick(() => {
                          const params: string[] = [this.chapter?.id ?? '', kp.id];
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
            // Close button
            Row() {
              Blank()
              Button({ type: ButtonType.Circle }) {
                Text('✕')
                  .fontSize(20)
                  .fontColor('#FFFFFF')
              }
              .width(40)
              .height(40)
              .backgroundColor('rgba(0,0,0,0.5)')
              .onClick(() => {
                this.showImagePreview = false;
              })
            }
            .width('100%')
            .padding({ right: 20, top: 50 })

            // Zoomable image
            if ((this.selectedKP?.image?.length ?? 0) > 0) {
              Image($rawfile(`images/${this.selectedKP?.image ?? ''}`))
                .width('100%')
                .layoutWeight(1)
                .objectFit(ImageFit.Contain)
                .scale({ x: this.imageScale, y: this.imageScale })
                .gesture(
                  PinchGesture({ fingers: 2 })
                    .onActionUpdate((event: GestureEvent) => {
                      this.imageScale = Math.max(0.5, Math.min(3.0, event.scale));
                    })
                    .onActionEnd(() => {
                      if (this.imageScale < 1) {
                        this.imageScale = 1;
                      }
                    })
                )
            }

            // Title overlay
            Column() {
              Text(`${this.selectedKP?.id ?? ''} ${this.selectedKP?.title ?? ''}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text(this.selectedKP?.titleCn ?? '')
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.8)')
                .margin({ top: 4 })
            }
            .width('100%')
            .padding(20)
          }
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.95)')
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }
}
