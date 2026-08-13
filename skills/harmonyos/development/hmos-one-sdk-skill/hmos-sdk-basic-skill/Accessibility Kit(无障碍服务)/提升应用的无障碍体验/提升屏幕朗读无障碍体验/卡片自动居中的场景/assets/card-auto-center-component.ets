// 完整卡片自动居中组件示例(包含错误处理和降级方案)
import { BasicListDataSource } from './list-datasource-example';

@Entry
@Component
export struct CompleteCardAutoCenterComponent {
  @State title: string = '完整卡片自动居中示例';
  @State cardCount: number = 10;
  @State currentIndex: number = 0;
  
  private dataSource: BasicListDataSource = new BasicListDataSource(
    ['Card 0', 'Card 1', 'Card 2', 'Card 3', 'Card 4', 'Card 5', 'Card 6', 'Card 7', 'Card 8', 'Card 9']
  );
  private scroller: Scroller = new Scroller();
  
  aboutToAppear() {
    console.info('Component about to appear, API version check:');
    // 检查API版本是否支持onAccessibilityFocus (需要API version 18+)
    // 实际项目中应通过设备API查询
  }
  
  build() {
    NavDestination() {
      Column() {
        // 顶部控制区
        Row() {
          Text(this.title)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
          
          Blank()
          
          // 添加卡片按钮
          Button('添加')
            .fontSize(14)
            .onClick(() => {
              if (this.cardCount < 1000) {
                this.dataSource.addDataItem(
                  this.cardCount,
                  'Card ' + this.cardCount
                );
                this.cardCount++;
              } else {
                console.warn('Maximum card count reached: 1000');
              }
            })
          
          // 删除卡片按钮
          Button('删除')
            .fontSize(14)
            .onClick(() => {
              if (this.cardCount > 1) {
                this.dataSource.deleteDataItem(this.cardCount - 1);
                this.cardCount--;
              } else {
                console.warn('Minimum card count reached: 1');
              }
            })
        }
        .width('90%')
        .height(50)
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 10 })
        
        // 横向滚动卡片列表
        List({ space: 20, initialIndex: 0, scroller: this.scroller }) {
          LazyForEach(this.dataSource, (item: string, index: number) => {
            ListItem() {
              Column() {
                Text(item)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .margin({ bottom: 10 })
                
                Text('Index: ' + index)
                  .fontSize(12)
                  .fontColor('#666666')
                
                // 操作按钮
                Row() {
                  Button('聚焦')
                    .fontSize(12)
                    .onClick(() => {
                      this.focusCard(index);
                    })
                }
                .margin({ top: 10 })
              }
              .width('100%')
              .height(150)
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
            .width('60%')
            .onClick(() => {
              this.currentIndex = index;
              console.info('Card clicked: ' + index);
            })
            .onAccessibilityFocus((isFocus: boolean) => {
              this.handleAccessibilityFocus(index, isFocus);
            })
          }, (item: string, index: number) => item + '-' + index)
        }
        .width('90%')
        .height(250)
        .scrollBar(BarState.Auto)
        .scrollSnapAlign(ScrollSnapAlign.CENTER)
        .listDirection(Axis.Horizontal)
        .edgeEffect(EdgeEffect.Spring)
        
        // 状态显示
        Column() {
          Text('当前卡片索引: ' + this.currentIndex)
            .fontSize(14)
            .margin({ top: 10 })
          
          Text('总卡片数: ' + this.cardCount)
            .fontSize(14)
            .margin({ top: 5 })
          
          Text('API版本要求: API version 18+')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 5 })
        }
        .width('90%')
        .margin({ top: 10 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(0xF0F0F0F0)
      .padding({ top: 20, bottom: 20 })
    }
    .title(this.title)
  }
  
  // 聚焦指定卡片
  private focusCard(index: number): void {
    try {
      if (index >= 0 && index < this.cardCount) {
        this.scroller.scrollToIndex(index, true, ScrollAlign.CENTER);
        this.currentIndex = index;
        console.info('Card focused: ' + index);
      } else {
        console.error('Invalid index for focusCard: ' + index);
      }
    } catch (error) {
      console.error('focusCard failed: ' + error.message);
      this.fallbackScrollToCard(index);
    }
  }
  
  // 处理无障碍聚焦
  private handleAccessibilityFocus(index: number, isFocus: boolean): void {
    if (isFocus) {
      console.info('Accessibility focus on card: ' + index);
      this.focusCard(index);
    } else {
      console.info('Accessibility unfocus on card: ' + index);
    }
  }
  
  // 降级滚动方案
  private fallbackScrollToCard(index: number): void {
    try {
      // 尝试使用START对齐方式
      this.scroller.scrollToIndex(index, false, ScrollAlign.START);
      console.warn('Fallback scroll with START alignment for card: ' + index);
    } catch (fallbackError) {
      console.error('Fallback scroll also failed: ' + fallbackError.message);
      // 最终降级:提示用户
      console.error('Unable to scroll to card ' + index);
    }
  }
}