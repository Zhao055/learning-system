@Component
export struct ResultBadge {
  @Prop isCorrect: boolean = false;
  @State animScale: number = 0;

  aboutToAppear(): void {
    animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
      this.animScale = 1;
    });
  }

  build() {
    Column() {
      Text(this.isCorrect ? '✓' : '✗')
        .fontSize(48)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      Text(this.isCorrect ? 'Correct!' : 'Incorrect')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .margin({ top: 8 })
    }
    .width(140)
    .height(140)
    .borderRadius(70)
    .backgroundColor(this.isCorrect ? '#4CAF50' : '#F44336')
    .justifyContent(FlexAlign.Center)
    .scale({ x: this.animScale, y: this.animScale })
    .shadow({ radius: 12, color: this.isCorrect ? 'rgba(76,175,80,0.3)' : 'rgba(244,67,54,0.3)', offsetX: 0, offsetY: 4 })
  }
}
