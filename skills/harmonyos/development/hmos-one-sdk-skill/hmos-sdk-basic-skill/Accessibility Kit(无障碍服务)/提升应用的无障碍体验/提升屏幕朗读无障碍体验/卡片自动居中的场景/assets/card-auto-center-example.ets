// 卡片自动居中完整示例代码
class ListDataSource implements IDataSource {
  private list: number[] = [];
  
  constructor(list: number[]) {
    this.list = list;
  }
  
  totalCount(): number {
    return this.list.length;
  }
  
  getData(index: number): number {
    if (index < 0 || index >= this.list.length) {
      console.error('Invalid index in getData: ' + index);
      return -1;
    }
    return this.list[index];
  }
  
  registerDataChangeListener(listener: DataChangeListener): void {
    // 注册数据变化监听器(可选实现)
  }
  
  unregisterDataChangeListener(listener: DataChangeListener): void {
    // 注销数据变化监听器(可选实现)
  }
}

@Entry
@Component
export struct CardAutoCenterExample {
  title: string = '卡片自动居中示例';
  private arr: ListDataSource = new ListDataSource([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
  private scrollerForList: Scroller = new Scroller();
  
  build() {
    NavDestination() {
      Column() {
        // 标题
        Text(this.title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 10 })
        
        // 横向滚动卡片列表
        List({ space: 20, initialIndex: 0, scroller: this.scrollerForList }) {
          LazyForEach(this.arr, (index: number) => {
            ListItem() {
              // 卡片内容
              Column() {
                Text('Card ' + index)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .margin({ bottom: 10 })
                
                Text('Content of card ' + index)
                  .fontSize(14)
                  .fontColor('#666666')
              }
              .width('100%')
              .height(120)
              .padding(15)
              .borderRadius(15)
              .backgroundColor(0xFFFFFF)
              .shadow({
                radius: 10,
                color: '#00000020',
                offsetX: 0,
                offsetY: 2
              })
            }
            .width('60%') // 设置卡片宽度占比,突出居中效果
            .onClick(() => {
              // 设置点击事件,使组件可被无障碍聚焦
              console.info('Card ' + index + ' clicked');
            })
            // 设置无障碍聚焦回调
            .onAccessibilityFocus((isFocus: boolean) => {
              if (isFocus) {
                try {
                  // 校验索引是否有效
                  if (index >= 0 && index < this.arr.totalCount()) {
                    // 如果聚焦则滚动List,使当前的ListItem居中
                    this.scrollerForList.scrollToIndex(index, false, ScrollAlign.CENTER);
                    console.info('Card ' + index + ' focused and centered');
                  } else {
                    console.error('Invalid card index: ' + index);
                  }
                } catch (error) {
                  console.error('scrollToIndex failed for card ' + index + ': ' + error.message);
                  // 降级处理:使用START对齐方式
                  try {
                    this.scrollerForList.scrollToIndex(index, false, ScrollAlign.START);
                  } catch (fallbackError) {
                    console.error('Fallback scrollToIndex also failed: ' + fallbackError.message);
                  }
                }
              }
            })
          }, (item: number) => 'card-' + item.toString()) // 提供唯一键值
        }
        .width('90%')
        .height(200)
        .scrollBar(BarState.Off)
        .scrollSnapAlign(ScrollSnapAlign.CENTER) // 设置居中对齐
        .listDirection(Axis.Horizontal) // 设置横向List
        .edgeEffect(EdgeEffect.Spring) // 设置弹簧边缘效果
        
        // 提示信息
        Text('请在无障碍模式下测试卡片聚焦功能')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 10 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(0xF5F5F5F5)
      .padding({ top: 20, bottom: 20 })
    }
    .title(this.title)
  }
}