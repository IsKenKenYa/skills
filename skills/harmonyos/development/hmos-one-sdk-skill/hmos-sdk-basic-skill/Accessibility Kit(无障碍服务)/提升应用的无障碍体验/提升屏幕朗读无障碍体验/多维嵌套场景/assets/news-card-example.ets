@Entry
@Component
export struct NewsCardExample {
  title: string = 'News Card Accessibility Example';
  
  build() {
    NavDestination() {
      Column() {
        Text('News card with accessibilityGroup:')
          .width('100%')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({ bottom: 12 })
        
        Column() {
          Text('HarmonyOS 5.0 Released')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.Black)
          
          Row() {
            Text('TechNews')
              .fontSize(14)
              .fontColor(Color.Gray)
              .margin({ right: 10 })
            
            Text('2026-07-02')
              .fontSize(14)
              .fontColor(Color.Gray)
          }
          .margin({ top: 5 })
          
          Text('Huawei announced the latest HarmonyOS version...')
            .fontSize(14)
            .fontColor(Color.DarkGray)
            .margin({ top: 8 })
            .maxLines(2)
        }
        .padding(15)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')
        .accessibilityGroup(true)
        .accessibilityText('News: HarmonyOS 5.0 Released by TechNews on 2026-07-02')
        .margin({ bottom: 20 })
        
        Text('Product card example:')
          .width('100%')
          .fontSize(12)
          .fontColor(Color.Black)
          .margin({ bottom: 12 })
        
        Row() {
          Image($r('app.media.product_image'))
            .width(80)
            .height(80)
            .borderRadius(8)
            .objectFit(ImageFit.Cover)
          
          Column() {
            Text('Premium Headphones')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.Black)
            
            Row() {
              Text('￥999')
                .fontSize(14)
                .fontColor(Color.Red)
                .fontWeight(FontWeight.Bold)
                .margin({ right: 10 })
              
              Text('VIP Price')
                .fontSize(12)
                .fontColor(Color.Orange)
            }
            .margin({ top: 5 })
          }
          .margin({ left: 15 })
          .alignItems(HorizontalAlign.Start)
        }
        .padding(15)
        .borderRadius(8)
        .backgroundColor('#FFFFFF')
        .borderWidth(1)
        .borderColor('#E0E0E0')
        .accessibilityGroup(true)
        .accessibilityText('Premium Headphones, Price: 999 Yuan, VIP exclusive')
      }
      .alignItems(HorizontalAlign.Start)
      .padding(10)
    }
    .title(this.title)
  }
}