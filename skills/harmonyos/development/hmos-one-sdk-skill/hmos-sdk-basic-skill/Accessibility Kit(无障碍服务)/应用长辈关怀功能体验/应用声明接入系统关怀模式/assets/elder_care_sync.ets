import accessibility from '@ohos.accessibility';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ElderCareSyncDemo {
  @State seniorModeState: boolean = false;
  @State fontSize: number = 16;
  @State iconSize: number = 24;
  
  seniorModeCallback = (state: boolean) => {
    console.info(`Senior mode state changed: ${state}`);
    this.seniorModeState = state;
    this.updateElderCareUI(state);
  };
  
  updateElderCareUI(state: boolean): void {
    if (state) {
      this.fontSize = 24;
      this.iconSize = 36;
      console.info('Elder care UI enabled: large font and icons');
    } else {
      this.fontSize = 16;
      this.iconSize = 24;
      console.info('Elder care UI disabled: normal font and icons');
    }
  }
  
  async aboutToAppear(): Promise<void> {
    try {
      this.seniorModeState = await accessibility.getSeniorModeStateForSelf();
      this.updateElderCareUI(this.seniorModeState);
      
      accessibility.onSeniorModeStateChangeForSelf(this.seniorModeCallback);
      
      console.info('Elder care sync demo initialized');
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to initialize: ${err.message}`);
    }
  }
  
  aboutToDisappear(): void {
    accessibility.offSeniorModeStateChangeForSelf(this.seniorModeCallback);
  }
  
  build() {
    Column() {
      Text('关怀模式同步示例')
        .fontSize(this.fontSize + 4)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      Row() {
        Text(`关怀模式: ${this.seniorModeState ? '开启' : '关闭'}`)
          .fontSize(this.fontSize)
        
        Toggle({ type: ToggleType.Switch, isOn: this.seniorModeState })
          .selectedColor('#007DFF')
          .onChange(async (isOn: boolean) => {
            if (isOn !== this.seniorModeState) {
              try {
                await accessibility.setSeniorModeStateForSelf(isOn);
                this.seniorModeState = isOn;
                this.updateElderCareUI(isOn);
              } catch (error) {
                const err = error as BusinessError;
                console.error(`Failed to sync: ${err.message}`);
              }
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ top: 20 })
      
      Divider()
        .margin({ top: 20, bottom: 20 })
      
      Column() {
        Text('示例文本内容')
          .fontSize(this.fontSize)
          .margin({ bottom: 10 })
        
        Text('这是关怀模式下的界面展示')
          .fontSize(this.fontSize)
          .margin({ bottom: 10 })
        
        Image($r('app.media.ic_public_settings'))
          .width(this.iconSize)
          .height(this.iconSize)
          .margin({ top: 10 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ top: 20 })
      
      if (this.seniorModeState) {
        Row() {
          Image($r('app.media.ic_public_ok'))
            .width(this.iconSize)
            .height(this.iconSize)
          
          Text('关怀模式已启用')
            .fontSize(this.fontSize)
            .fontColor('#00AA00')
        }
        .margin({ top: 30 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(20)
  }
}