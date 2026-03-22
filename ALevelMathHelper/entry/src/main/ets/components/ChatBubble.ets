@Component
export struct ChatBubble {
  @Prop role: string = 'user';
  @Prop content: string = '';
  @Prop isStreaming: boolean = false;

  build() {
    Column() {
      if (this.role === 'user') {
        Row() {
          Blank()
          Text(this.content)
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
          Text(this.content + (this.isStreaming ? '|' : ''))
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
