import { MiniMaxService } from '../service/MiniMaxService';

@Builder
export function SettingsPageBuilder() {
  SettingsPage()
}

@Component
export struct SettingsPage {
  @Consume navPathStack: NavPathStack;
  @State apiKey: string = '';
  @State showKey: boolean = false;
  @State saved: boolean = false;

  aboutToAppear(): void {
    this.apiKey = MiniMaxService.getInstance().getApiKey();
  }

  private async saveApiKey(): Promise<void> {
    await MiniMaxService.getInstance().saveApiKey(getContext(this), this.apiKey.trim());
    this.saved = true;
    setTimeout(() => { this.saved = false; }, 2000);
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

          Text('Settings')
            .fontSize(22).fontWeight(FontWeight.Bold).margin({ left: 16 })
        }
        .width('100%').padding({ left: 20, right: 20, top: 12, bottom: 20 })

        Scroll() {
          Column({ space: 20 }) {
            // API Key section
            Column({ space: 12 }) {
              Text('MiniMax API Key')
                .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333333')
              Text('Required for AI tutoring and photo solving features. Get your API key from minimax.io')
                .fontSize(13).fontColor('#999999').lineHeight(20)

              Row() {
                TextInput({ placeholder: 'Enter your MiniMax API key', text: this.apiKey })
                  .layoutWeight(1).height(44).fontSize(14)
                  .type(this.showKey ? InputType.Normal : InputType.Password)
                  .onChange((value: string) => { this.apiKey = value; this.saved = false; })

                Button(this.showKey ? '🙈' : '👁️')
                  .fontSize(20).backgroundColor(Color.Transparent)
                  .onClick(() => { this.showKey = !this.showKey; })
              }
              .width('100%')

              Button(this.saved ? 'Saved ✓' : 'Save API Key')
                .width('100%').height(44)
                .backgroundColor(this.saved ? '#4CAF50' : '#4E6EF2')
                .fontColor('#FFFFFF').fontSize(15).borderRadius(12)
                .onClick(() => { this.saveApiKey(); })
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)

            // About section
            Column({ space: 8 }) {
              Text('About')
                .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#333333')

              Row() {
                Text('App').fontSize(14).fontColor('#999999')
                Blank()
                Text('A-Level Helper').fontSize(14).fontColor('#333333')
              }.width('100%').padding({ top: 8 })

              Divider().color('#F0F0F0')

              Row() {
                Text('Subjects').fontSize(14).fontColor('#999999')
                Blank()
                Text('Math, Bio, Psych').fontSize(14).fontColor('#333333')
              }.width('100%').padding({ top: 8 })

              Divider().color('#F0F0F0')

              Row() {
                Text('AI Model').fontSize(14).fontColor('#999999')
                Blank()
                Text('MiniMax M2.5').fontSize(14).fontColor('#333333')
              }.width('100%').padding({ top: 8 })

              Divider().color('#F0F0F0')

              Row() {
                Text('Version').fontSize(14).fontColor('#999999')
                Blank()
                Text('2.0.0').fontSize(14).fontColor('#333333')
              }.width('100%').padding({ top: 8 })
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
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
