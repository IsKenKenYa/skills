import accessibility from '@ohos.accessibility';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ElderCareMonitor {
  @State seniorModeState: boolean = false;
  @State message: string = '关怀模式状态监控';
  
  seniorModeCallback = (state: boolean) => {
    console.info(`Senior mode state changed: ${state}`);
    this.seniorModeState = state;
    this.message = `关怀模式已${state ? '开启' : '关闭'}`;
  };
  
  async aboutToAppear(): Promise<void> {
    try {
      this.seniorModeState = await accessibility.getSeniorModeStateForSelf();
      console.info(`Initial senior mode state: ${this.seniorModeState}`);
      
      accessibility.onSeniorModeStateChangeForSelf(this.seniorModeCallback);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Failed to get senior mode state: ${err.message}`);
    }
  }
  
  aboutToDisappear(): void {
    accessibility.offSeniorModeStateChangeForSelf(this.seniorModeCallback);
  }
  
  build() {
    Column() {
      Text(this.message)
        .fontSize(this.seniorModeState ? 24 : 16)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })
      
      Row() {
        Text(`当前状态: ${this.seniorModeState ? '开启' : '关闭'}`)
          .fontSize(this.seniorModeState ? 20 : 14)
        
        Toggle({ type: ToggleType.Switch, isOn: this.seniorModeState })
          .onChange(async (isOn: boolean) => {
            if (isOn !== this.seniorModeState) {
              try {
                await accessibility.setSeniorModeStateForSelf(isOn);
                this.seniorModeState = isOn;
                console.info(`Senior mode state set to: ${isOn}`);
              } catch (error) {
                const err = error as BusinessError;
                console.error(`Failed to set senior mode state: ${err.message}`);
              }
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 20 })
      
      if (this.seniorModeState) {
        Text('关怀模式已启用，界面元素已放大')
          .fontSize(18)
          .fontColor('#00AA00')
          .margin({ top: 30 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}