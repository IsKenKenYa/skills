@Entry
@Component
export struct ProductCardExample {
  title: string = 'Product Card Accessibility Example';
  
  build() {
    NavDestination() {
      Column() {
        Text('E-commerce product card:')
          .width('100%')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({ bottom: 12 })
        
        Column() {
          Row() {
            Image($r('app.media.product1'))
              .width(120)
              .height(120)
              .borderRadius(10)
            
            Column() {
              Text('Wireless Earbuds Pro')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Black)
              
              Text('Active Noise Cancelling')
                .fontSize(14)
                .fontColor(Color.Gray)
                .margin({ top: 3 })
              
              Row() {
                Text('￥1299')
                  .fontSize(16)
                  .fontColor(Color.Red)
                  .fontWeight(FontWeight.Bold)
                
                Text('￥1599')
                  .fontSize(12)
                  .fontColor(Color.Gray)
                  .margin({ left: 8 })
                  .decoration({ type: TextDecorationType.LineThrough })
              }
              .margin({ top: 5 })
              
              Text('Free shipping')
                .fontSize(12)
                .fontColor(Color.Green)
                .margin({ top: 3 })
            }
            .margin({ left: 15 })
            .alignItems(HorizontalAlign.Start)
          }
          
          Row() {
            Button('Add to Cart')
              .fontSize(14)
              .width('45%')
              .height(40)
              .backgroundColor('#FF6B6B')
              .fontColor(Color.White)
            
            Button('Buy Now')
              .fontSize(14)
              .width('45%')
              .height(40)
              .backgroundColor('#4A90E2')
              .fontColor(Color.White)
              .margin({ left: 10 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 10 })
        }
        .padding(15)
        .borderRadius(12)
        .backgroundColor('#FFFFFF')
        .borderWidth(1)
        .borderColor('#E8E8E8')
        .accessibilityGroup(true)
        .accessibilityText('Wireless Earbuds Pro with Active Noise Cancelling, Price 1299 Yuan, Free shipping')
        .margin({ bottom: 20 })
        
        Text('Notification message card:')
          .width('100%')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({ bottom: 12 })
        
        Row() {
          Image($r('app.media.avatar'))
            .width(50)
            .height(50)
            .borderRadius(25)
          
          Column() {
            Row() {
              Text('John Doe')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.Black)
              
              Text('10:30 AM')
                .fontSize(12)
                .fontColor(Color.Gray)
                .margin({ left: 10 })
            }
            
            Text('Hey, are you free for lunch today?')
              .fontSize(14)
              .fontColor(Color.DarkGray)
              .margin({ top: 3 })
              .maxLines(2)
          }
          .margin({ left: 10 })
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .padding(12)
        .borderRadius(8)
        .backgroundColor('#F0F8FF')
        .accessibilityGroup(true)
        .accessibilityText('Message from John Doe at 10:30 AM: Hey, are you free for lunch today?')
      }
      .alignItems(HorizontalAlign.Start)
      .padding(10)
      .width('100%')
    }
    .title(this.title)
  }
}