import testNapi from 'libentry.so';

@Entry
@Component
struct Index {
  @State message: string = 'Address Sanitizer Test';

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })

        Button("触发地址越界事件")
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .width('80%')
          .height(50)
          .margin({ top: 20 })
          .onClick(() => {
            // 点击按钮触发地址越界事件
            // 注意:这会导致应用崩溃,重启应用后可查看日志
            testNapi.test();
          })

        Text("点击按钮将触发地址越界事件\n应用会崩溃,重启后查看日志")
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 20 })
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .height('100%')
  }
}