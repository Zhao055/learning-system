import { QuestionRepository } from '../data/QuestionRepository';
import { Chapter, PaperInfo } from '../model/ChapterModel';
import { getPaper } from '../data/SubjectData';

@Builder
export function ChapterListPageBuilder() {
  ChapterListPage()
}

@Component
export struct ChapterListPage {
  @Consume navPathStack: NavPathStack;
  @State chapters: Chapter[] = [];
  @State paperId: string = '';
  @State paper: PaperInfo | undefined = undefined;

  private chapterIcons: string[] = ['📐', '🔗', '📍', '🔵', '📊', '📈', '🔺', '∫', '🧮', '📏', '🔢'];

  aboutToAppear(): void {
    const params = this.navPathStack.getParamByName('ChapterListPage') as Object[];
    if (params && params.length > 0) {
      const p = params[0] as string[];
      this.paperId = p[1];
      this.paper = getPaper(this.paperId);
      this.chapters = QuestionRepository.getInstance().getChapters(this.paperId);
    }
  }

  build() {
    NavDestination() {
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

          Column() {
            Text(this.paper?.name ?? 'Chapters')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.paper?.nameCn ?? '')
              .fontSize(12)
              .fontColor('#999999')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 16 })
          .layoutWeight(1)

          Text(`${this.chapters.length} chapters`)
            .fontSize(14)
            .fontColor('#999999')
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })

        // Chapter list
        List({ space: 12 }) {
          ForEach(this.chapters, (chapter: Chapter, index: number) => {
            ListItem() {
              Row() {
                Text(this.chapterIcons[index] ?? '📘')
                  .fontSize(36)
                  .margin({ right: 16 })

                Column() {
                  Text(`Ch ${index + 1}. ${chapter.title}`)
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                  Text(chapter.titleCn)
                    .fontSize(13)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                  Text(`${chapter.knowledgePoints.length} knowledge points`)
                    .fontSize(12)
                    .fontColor('#4E6EF2')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Image($r('sys.media.ohos_ic_public_arrow_right'))
                  .width(20)
                  .height(20)
                  .fillColor('#CCCCCC')
              }
              .width('100%')
              .padding(20)
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
              .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetX: 0, offsetY: 2 })
              .onClick(() => {
                const navParams: string[] = [this.paperId, chapter.id];
                this.navPathStack.pushPathByName('KnowledgeCardPage', navParams);
              })
            }
          }, (chapter: Chapter) => chapter.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 20, right: 20, bottom: 20 })
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
  }
}
