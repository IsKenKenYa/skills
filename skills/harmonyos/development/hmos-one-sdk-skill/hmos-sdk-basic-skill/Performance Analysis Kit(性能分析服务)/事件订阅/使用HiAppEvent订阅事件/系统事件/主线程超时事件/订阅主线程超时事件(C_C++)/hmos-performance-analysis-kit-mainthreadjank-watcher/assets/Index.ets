@Entry
@Component
struct Index {
    @State message: string = '主线程超时事件订阅测试';

    build() {
        Column() {
            Text(this.message)
                .fontSize(30)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 50 })

            Button("触发主线程超时350ms")
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 30 })
                .onClick(() => {
                    let t = Date.now();
                    while (Date.now() - t <= 350) {}
                })

            Button("触发主线程超时500ms")
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 20 })
                .onClick(() => {
                    let t = Date.now();
                    while (Date.now() - t <= 500) {}
                })
        }
        .width('100%')
        .height('100%')
    }
}