import { MiniMaxService } from '../service/MiniMaxService';
import { ChatMessage } from '../model/ChatModel';

@Builder
export function SolutionPageBuilder() {
  SolutionPage()
}

@Component
export struct SolutionPage {
  @Consume navPathStack: NavPathStack;
  @State problemText: string = '';
  @State chatMessages: ChatMessage[] = [];
  @State chatInput: string = '';
  @State isStreaming: boolean = false;
  private sessionId: string = '';

  aboutToAppear(): void {
    const params = this.navPathStack.getParamByName('SolutionPage') as string[];
    if (params && params.length > 0) {
      this.problemText = params[0];
      this.sessionId = `photo_${Date.now()}`;
      this.startSolving();
    }
  }

  private startSolving(): void {
    const service = MiniMaxService.getInstance();
    service.initPhotoSolveSession(this.sessionId, this.problemText);
    this.isStreaming = true;

    service.sendMessageStream(this.sessionId, '',
      (chunk: string) => {
        const msgs = [...this.chatMessages];
        if (msgs.length === 0 || msgs[msgs.length - 1].role !== 'assistant' || !msgs[msgs.length - 1].isStreaming) {
          msgs.push({
            id: `ai_${Date.now()}`, role: 'assistant',
            content: chunk, timestamp: Date.now(), isStreaming: true
          });
        } else {
          const last = msgs[msgs.length - 1];
          msgs[msgs.length - 1] = {
            id: last.id, role: last.role, content: last.content + chunk,
            timestamp: last.timestamp, isStreaming: true
          };
        }
        this.chatMessages = msgs;
      },
      () => {
        this.isStreaming = false;
        const msgs = [...this.chatMessages];
        if (msgs.length > 0) {
          const last = msgs[msgs.length - 1];
          msgs[msgs.length - 1] = {
            id: last.id, role: last.role, content: last.content,
            timestamp: last.timestamp, isStreaming: false
          };
          this.chatMessages = msgs;
        }
      },
      (err: string) => {
        this.isStreaming = false;
        this.chatMessages = [...this.chatMessages, {
          id: `err_${Date.now()}`, role: 'assistant',
          content: `Error: ${err}`, timestamp: Date.now()
        }];
      }
    );
  }

  private sendMessage(): void {
    if (!this.chatInput.trim() || this.isStreaming) return;
    const userMsg: ChatMessage = {
      id: `user_${Date.now()}`, role: 'user',
      content: this.chatInput.trim(), timestamp: Date.now()
    };
    this.chatMessages = [...this.chatMessages, userMsg];
    const message = this.chatInput.trim();
    this.chatInput = '';
    this.isStreaming = true;

    MiniMaxService.getInstance().sendMessageStream(this.sessionId, message,
      (chunk: string) => {
        const msgs = [...this.chatMessages];
        if (msgs.length === 0 || msgs[msgs.length - 1].role !== 'assistant' || !msgs[msgs.length - 1].isStreaming) {
          msgs.push({
            id: `ai_${Date.now()}`, role: 'assistant',
            content: chunk, timestamp: Date.now(), isStreaming: true
          });
        } else {
          const last = msgs[msgs.length - 1];
          msgs[msgs.length - 1] = {
            id: last.id, role: last.role, content: last.content + chunk,
            timestamp: last.timestamp, isStreaming: true
          };
        }
        this.chatMessages = msgs;
      },
      () => {
        this.isStreaming = false;
        const msgs = [...this.chatMessages];
        if (msgs.length > 0) {
          const last = msgs[msgs.length - 1];
          msgs[msgs.length - 1] = {
            id: last.id, role: last.role, content: last.content,
            timestamp: last.timestamp, isStreaming: false
          };
          this.chatMessages = msgs;
        }
      },
      (err: string) => {
        this.isStreaming = false;
        this.chatMessages = [...this.chatMessages, {
          id: `err_${Date.now()}`, role: 'assistant',
          content: `Error: ${err}`, timestamp: Date.now()
        }];
      }
    );
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

          Text('AI Solution')
            .fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 16 })
        }
        .width('100%').padding({ left: 20, right: 20, top: 12, bottom: 8 })

        // Problem text (collapsed)
        Column() {
          Text('Problem:')
            .fontSize(12).fontColor('#999999')
          Text(this.problemText)
            .fontSize(13).fontColor('#666666').maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis }).margin({ top: 4 })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 8, bottom: 8 })
        .backgroundColor('#FAFAFA')

        // Messages
        List() {
          ForEach(this.chatMessages, (msg: ChatMessage) => {
            ListItem() {
              Column() {
                if (msg.role === 'user') {
                  Row() {
                    Blank()
                    Text(msg.content)
                      .fontSize(15).fontColor('#FFFFFF').lineHeight(24)
                      .padding(14).backgroundColor('#4E6EF2')
                      .borderRadius({ topLeft: 16, topRight: 16, bottomLeft: 16, bottomRight: 4 })
                      .constraintSize({ maxWidth: '85%' })
                  }.width('100%')
                } else {
                  Row() {
                    Text(msg.content + (msg.isStreaming ? '|' : ''))
                      .fontSize(15).fontColor('#333333').lineHeight(24)
                      .padding(14).backgroundColor('#FFFFFF')
                      .borderRadius({ topLeft: 16, topRight: 16, bottomLeft: 4, bottomRight: 16 })
                      .constraintSize({ maxWidth: '85%' })
                      .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetX: 0, offsetY: 2 })
                    Blank()
                  }.width('100%')
                }
              }.padding({ left: 16, right: 16, top: 6, bottom: 6 })
            }
          }, (msg: ChatMessage) => msg.id)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .backgroundColor('#F5F5F5')

        // Input bar
        Row() {
          TextInput({ placeholder: 'Ask a follow-up question...', text: this.chatInput })
            .layoutWeight(1).height(42).borderRadius(21)
            .backgroundColor('#F5F5F5').fontSize(14)
            .onChange((value: string) => { this.chatInput = value; })
            .onSubmit((enterKey: EnterKeyType) => { this.sendMessage(); })

          Button({ type: ButtonType.Circle }) {
            Text('→').fontSize(20).fontColor('#FFFFFF')
          }
          .width(42).height(42)
          .backgroundColor(this.chatInput.trim().length > 0 ? '#4E6EF2' : '#CCCCCC')
          .margin({ left: 8 })
          .enabled(this.chatInput.trim().length > 0 && !this.isStreaming)
          .onClick(() => { this.sendMessage(); })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 16 })
        .backgroundColor('#FFFFFF')
        .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetX: 0, offsetY: -2 })
      }
      .width('100%').height('100%').backgroundColor('#F5F5F5')
    }
    .hideTitleBar(true)
  }
}
