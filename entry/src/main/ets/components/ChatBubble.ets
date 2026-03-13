import { ChatMessage } from '../model/ChatModel';

@Component
export struct ChatBubble {
  @Prop message: ChatMessage;

  build() {
    Column() {
      if (this.message.role === 'user') {
        Row() {
          Blank()
          Text(this.message.content)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .lineHeight(22)
            .padding(12)
            .backgroundColor('#4E6EF2')
            .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 12, bottomRight: 4 })
            .constraintSize({ maxWidth: '80%' })
        }
        .width('100%')
      } else {
        Row() {
          Text(this.message.content + (this.message.isStreaming ? '▌' : ''))
            .fontSize(14)
            .fontColor('#333333')
            .lineHeight(22)
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 4, bottomRight: 12 })
            .constraintSize({ maxWidth: '80%' })
          Blank()
        }
        .width('100%')
      }
    }
    .padding({ left: 16, right: 16, top: 4, bottom: 4 })
  }
}
