@Component
export struct OptionCard {
  @Prop text: string = '';
  @Prop index: number = 0;
  @Prop isSelected: boolean = false;
  @Prop isCorrect: boolean = false;
  @Prop showResult: boolean = false;
  onSelect: () => void = () => {};

  private optionLabels: string[] = ['A', 'B', 'C', 'D'];

  private getBgColor(): ResourceColor {
    if (!this.showResult) {
      return this.isSelected ? '#E8EEFF' : '#FFFFFF';
    }
    if (this.isCorrect) {
      return '#E8F5E9';
    }
    if (this.isSelected && !this.isCorrect) {
      return '#FFEBEE';
    }
    return '#FFFFFF';
  }

  private getBorderColor(): ResourceColor {
    if (!this.showResult) {
      return this.isSelected ? '#4E6EF2' : '#E0E0E0';
    }
    if (this.isCorrect) {
      return '#4CAF50';
    }
    if (this.isSelected && !this.isCorrect) {
      return '#F44336';
    }
    return '#E0E0E0';
  }

  build() {
    Row() {
      // Option label circle
      Text(this.optionLabels[this.index] ?? '')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.showResult && this.isCorrect ? '#FFFFFF' :
                   this.isSelected ? '#4E6EF2' : '#666666')
        .width(36)
        .height(36)
        .textAlign(TextAlign.Center)
        .borderRadius(18)
        .backgroundColor(this.showResult && this.isCorrect ? '#4CAF50' :
                         this.showResult && this.isSelected && !this.isCorrect ? '#F44336' :
                         this.isSelected ? '#E8EEFF' : '#F5F5F5')

      Text(this.text)
        .fontSize(15)
        .fontColor('#333333')
        .margin({ left: 14 })
        .layoutWeight(1)

      if (this.showResult && this.isCorrect) {
        Text('✓')
          .fontSize(20)
          .fontColor('#4CAF50')
          .fontWeight(FontWeight.Bold)
      } else if (this.showResult && this.isSelected && !this.isCorrect) {
        Text('✗')
          .fontSize(20)
          .fontColor('#F44336')
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(this.getBgColor())
    .borderRadius(12)
    .border({ width: 1.5, color: this.getBorderColor() })
    .onClick(() => {
      if (!this.showResult) {
        this.onSelect();
      }
    })
  }
}
