import { ChatMessage } from '../model/ChatModel';
import { ChatBubble } from './ChatBubble';

@Component
export struct ChatPanel {
  @Link chatMessages: ChatMessage[];
  @Link chatInput: string;
  @Link isStreaming: boolean;
  onSend: () => void = () => {};
  onClose: () => void = () => {};

  build() {
    Column() {
      // Dimmed background
      Column()
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('rgba(0,0,0,0.4)')
        .onClick(() => { this.onClose(); })

      // Panel
      Column() {
        // Handle bar
        Column()
          .width(40)
          .height(4)
          .borderRadius(2)
          .backgroundColor('#CCCCCC')
          .margin({ top: 8, bottom: 8 })

        // Title
        Row() {
          Text('Ask AI Tutor')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Blank()
          Button({ type: ButtonType.Circle }) {
            Text('✕').fontSize(16).fontColor('#666666')
          }
          .width(32)
          .height(32)
          .backgroundColor('#F0F0F0')
          .onClick(() => { this.onClose(); })
        }
        .width('100%')
        .padding({ left: 20, right: 20 })

        // Messages list
        List() {
          ForEach(this.chatMessages, (msg: ChatMessage) => {
            ListItem() {
              ChatBubble({ role: msg.role, content: msg.content, isStreaming: msg.isStreaming ?? false })
            }
          }, (msg: ChatMessage) => msg.id)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        // Input bar
        Row() {
          TextInput({ placeholder: 'Ask a question...', text: this.chatInput })
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .backgroundColor('#F5F5F5')
            .fontSize(14)
            .onChange((value: string) => { this.chatInput = value; })
            .onSubmit((enterKey: EnterKeyType) => { this.onSend(); })

          Button({ type: ButtonType.Circle }) {
            Text('→').fontSize(18).fontColor('#FFFFFF')
          }
          .width(40)
          .height(40)
          .backgroundColor(this.chatInput.trim().length > 0 ? '#4E6EF2' : '#CCCCCC')
          .margin({ left: 8 })
          .enabled(this.chatInput.trim().length > 0 && !this.isStreaming)
          .onClick(() => { this.onSend(); })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      }
      .width('100%')
      .height('65%')
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 20, topRight: 20 })
    }
    .width('100%')
    .height('100%')
  }
}
