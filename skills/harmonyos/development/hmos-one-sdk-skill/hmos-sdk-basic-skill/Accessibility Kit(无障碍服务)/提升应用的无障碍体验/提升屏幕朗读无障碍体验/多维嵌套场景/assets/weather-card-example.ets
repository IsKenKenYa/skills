@Entry
@Component
export struct WeatherCardExample {
  title: string = 'Weather Card Accessibility Example';
  
  build() {
    NavDestination() {
      Column() {
        Text('Correct behavior:')
          .width('100%')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({ bottom: 12 })
        
        Row() {
          Text('07:05')
            .fontSize(32)
            .fontColor(Color.Red)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .margin({ right: 20 })
          
          Text('Moscow')
            .fontSize(20)
            .fontColor(Color.Green)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
        }
        .height(50)
        .accessibilityGroup(true)
        .margin({ bottom: 150 })
        
        Text('Incorrect behavior:')
          .width('100%')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({ bottom: 12 })
        
        Row() {
          Text('12:05')
            .fontSize(32)
            .fontColor(Color.Red)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .margin({ right: 20 })
          
          Text('Beijing')
            .fontSize(20)
            .fontColor(Color.Green)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
        }
        .accessibilityText('Time Group')
        .height(50)
        .margin({ bottom: 150 })
        
        Text('Custom text example:')
          .width('100%')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({ bottom: 12 })
        
        Row() {
          Text('15:30')
            .fontSize(32)
            .fontColor(Color.Blue)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .margin({ right: 20 })
          
          Text('Shanghai')
            .fontSize(20)
            .fontColor(Color.Orange)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
        }
        .height(50)
        .accessibilityGroup(true)
        .accessibilityText('Current time and location: 15:30 Shanghai')
      }
      .alignItems(HorizontalAlign.Start)
      .padding(10)
    }
    .title(this.title)
  }
}