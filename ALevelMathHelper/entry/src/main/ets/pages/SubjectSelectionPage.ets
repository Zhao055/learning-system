import { SubjectInfo } from '../model/ChapterModel';
import { SUBJECTS } from '../data/SubjectData';

@Builder
export function SubjectSelectionPageBuilder() {
  SubjectSelectionPage()
}

@Component
export struct SubjectSelectionPage {
  @Consume navPathStack: NavPathStack;

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

          Text('Choose Subject')
            .fontSize(22).fontWeight(FontWeight.Bold).margin({ left: 16 })

          Blank()

          Text(`${SUBJECTS.length} subjects`)
            .fontSize(14).fontColor('#999999')
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })

        // Subject cards
        List({ space: 16 }) {
          ForEach(SUBJECTS, (subject: SubjectInfo) => {
            ListItem() {
              Column() {
                Row() {
                  Text(subject.icon)
                    .fontSize(40)
                  Column() {
                    Text(subject.name)
                      .fontSize(20)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FFFFFF')
                    Text(`${subject.nameCn} | ${subject.code}`)
                      .fontSize(14)
                      .fontColor('rgba(255,255,255,0.8)')
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .margin({ left: 16 })
                }
                .width('100%')

                Text(`${subject.papers.length} Papers`)
                  .fontSize(13)
                  .fontColor('rgba(255,255,255,0.7)')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .backgroundColor('rgba(255,255,255,0.2)')
                  .borderRadius(12)
                  .margin({ top: 16 })

                Button('Select →')
                  .width('100%')
                  .height(44)
                  .backgroundColor('rgba(255,255,255,0.25)')
                  .fontColor('#FFFFFF')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .borderRadius(12)
                  .margin({ top: 16 })
                  .onClick(() => {
                    this.navPathStack.pushPathByName('PaperSelectionPage', subject.id);
                  })
              }
              .width('100%')
              .padding(24)
              .borderRadius(20)
              .linearGradient({
                angle: 135,
                colors: [[subject.gradientColors[0], 0], [subject.gradientColors[1], 1]]
              })
            }
          }, (subject: SubjectInfo) => subject.id)
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
