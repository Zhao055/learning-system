import { SubjectInfo, PaperInfo } from '../model/ChapterModel';
import { getSubject } from '../data/SubjectData';
import { QuestionRepository } from '../data/QuestionRepository';

@Builder
export function PaperSelectionPageBuilder() {
  PaperSelectionPage()
}

@Component
export struct PaperSelectionPage {
  @Consume navPathStack: NavPathStack;
  @State subject: SubjectInfo | undefined = undefined;
  @State loadingPaperId: string = '';

  aboutToAppear(): void {
    const params = this.navPathStack.getParamByName('PaperSelectionPage') as string[];
    if (params && params.length > 0) {
      this.subject = getSubject(params[0]);
    }
  }

  private async onPaperClick(paper: PaperInfo): Promise<void> {
    const repo = QuestionRepository.getInstance();
    if (!repo.isPaperLoaded(paper.id)) {
      this.loadingPaperId = paper.id;
      await repo.loadPaper(getContext(this), paper.jsonFile, paper.id);
      this.loadingPaperId = '';
    }
    const params: string[] = [this.subject?.id ?? '', paper.id];
    this.navPathStack.pushPathByName('ChapterListPage', params);
  }

  private getPaperIcon(index: number): string {
    const icons: string[] = ['📘', '📗', '📙', '📕', '📒', '📓'];
    return icons[index % icons.length];
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
            Text(this.subject?.name ?? 'Papers')
              .fontSize(20).fontWeight(FontWeight.Bold)
            Text(`${this.subject?.code ?? ''} | ${this.subject?.nameCn ?? ''}`)
              .fontSize(13).fontColor('#999999').margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 16 })

          Blank()

          Text(`${this.subject?.papers.length ?? 0} papers`)
            .fontSize(14).fontColor('#999999')
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })

        // Paper list
        List({ space: 12 }) {
          ForEach(this.subject?.papers ?? [], (paper: PaperInfo, index: number) => {
            ListItem() {
              Row() {
                Text(this.getPaperIcon(index))
                  .fontSize(36)
                  .margin({ right: 16 })

                Column() {
                  Text(paper.name)
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                  Text(paper.nameCn)
                    .fontSize(13)
                    .fontColor('#999999')
                    .margin({ top: 4 })

                  Row({ space: 8 }) {
                    Text(`${paper.chapterCount} Ch`)
                      .fontSize(11)
                      .fontColor(this.subject?.color ?? '#4E6EF2')
                      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                      .backgroundColor('#F0F4FF')
                      .borderRadius(8)
                    Text(`${paper.questionCount} Q`)
                      .fontSize(11)
                      .fontColor(this.subject?.color ?? '#4E6EF2')
                      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                      .backgroundColor('#F0F4FF')
                      .borderRadius(8)
                  }
                  .margin({ top: 6 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                if (this.loadingPaperId === paper.id) {
                  LoadingProgress()
                    .width(24).height(24)
                    .color(this.subject?.color ?? '#4E6EF2')
                } else {
                  Image($r('sys.media.ohos_ic_public_arrow_right'))
                    .width(20).height(20).fillColor('#CCCCCC')
                }
              }
              .width('100%')
              .padding(20)
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
              .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetX: 0, offsetY: 2 })
              .onClick(() => {
                this.onPaperClick(paper);
              })
            }
          }, (paper: PaperInfo) => paper.id)
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
