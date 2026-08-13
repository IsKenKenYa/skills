import accessibility from '@ohos.accessibility';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ElderCareCompleteApp {
  @State seniorModeState: boolean = false;
  @State fontSize: number = 16;
  @State iconSize: number = 24;
  @State spacing: number = 10;
  
  seniorModeCallback = (state: boolean) => {
    console.info(`[ElderCareApp] Senior mode changed: ${state}`);
    this.seniorModeState = state;
    this.applyElderCareTheme(state);
  };
  
  applyElderCareTheme(isEnabled: boolean): void {
    if (isEnabled) {
      this.fontSize = 24;
      this.iconSize = 40;
      this.spacing = 20;
      console.info('[ElderCareApp] Elder care theme applied');
    } else {
      this.fontSize = 16;
      this.iconSize = 24;
      this.spacing = 10;
      console.info('[ElderCareApp] Normal theme applied');
    }
  }
  
  async initializeElderCare(): Promise<void> {
    try {
      const currentState = await accessibility.getSeniorModeStateForSelf();
      console.info(`[ElderCareApp] Initial state: ${currentState}`);
      
      this.seniorModeState = currentState;
      this.applyElderCareTheme(currentState);
      
      accessibility.onSeniorModeStateChangeForSelf(this.seniorModeCallback);
      
      console.info('[ElderCareApp] Elder care initialized successfully');
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[ElderCareApp] Initialization failed: ${err.code} - ${err.message}`);
    }
  }
  
  async toggleSeniorMode(): Promise<void> {
    const newState = !this.seniorModeState;
    
    try {
      await accessibility.setSeniorModeStateForSelf(newState);
      this.seniorModeState = newState;
      this.applyElderCareTheme(newState);
      
      console.info(`[ElderCareApp] Mode toggled to: ${newState}`);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`[ElderCareApp] Toggle failed: ${err.code} - ${err.message}`);
    }
  }
  
  aboutToAppear(): void {
    this.initializeElderCare();
  }
  
  aboutToDisappear(): void {
    accessibility.offSeniorModeStateChangeForSelf(this.seniorModeCallback);
    console.info('[ElderCareApp] Elder care cleanup completed');
  }
  
  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_public_settings'))
          .width(this.iconSize)
          .height(this.iconSize)
        
        Text('长辈关怀应用')
          .fontSize(this.fontSize + 6)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: this.spacing * 2 })
      
      Divider()
        .margin({ bottom: this.spacing * 2 })
      
      Column() {
        Text('关怀模式设置')
          .fontSize(this.fontSize + 2)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: this.spacing })
        
        Row() {
          Text('关怀模式状态:')
            .fontSize(this.fontSize)
          
          Text(this.seniorModeState ? '已开启' : '已关闭')
            .fontSize(this.fontSize)
            .fontColor(this.seniorModeState ? '#00AA00' : '#AAAAAA')
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: this.spacing })
        
        Row() {
          Text('开关设置:')
            .fontSize(this.fontSize)
          
          Toggle({ type: ToggleType.Switch, isOn: this.seniorModeState })
            .selectedColor('#007DFF')
            .onChange(() => {
              this.toggleSeniorMode();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: this.spacing })
        
        if (this.seniorModeState) {
          Row() {
            Image($r('app.media.ic_public_ok'))
              .width(this.iconSize * 0.8)
              .height(this.iconSize * 0.8)
            
            Text('关怀模式已生效，界面已优化')
              .fontSize(this.fontSize)
              .fontColor('#00AA00')
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: this.spacing })
        }
      }
      .width('100%')
      .padding(this.spacing)
      .backgroundColor(this.seniorModeState ? '#F5F5F5' : '#FFFFFF')
      .borderRadius(12)
      
      Divider()
        .margin({ top: this.spacing * 2, bottom: this.spacing * 2 })
      
      Column() {
        Text('功能展示区域')
          .fontSize(this.fontSize + 2)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: this.spacing })
        
        Column() {
          Row() {
            Image($r('app.media.ic_public_phone'))
              .width(this.iconSize)
              .height(this.iconSize)
            
            Text('电话功能')
              .fontSize(this.fontSize)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .margin({ bottom: this.spacing })
          
          Row() {
            Image($r('app.media.ic_public_message'))
              .width(this.iconSize)
              .height(this.iconSize)
            
            Text('消息功能')
              .fontSize(this.fontSize)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .margin({ bottom: this.spacing })
          
          Row() {
            Image($r('app.media.ic_public_contacts'))
              .width(this.iconSize)
              .height(this.iconSize)
            
            Text('联系人')
              .fontSize(this.fontSize)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
        }
        .width('100%')
        .padding(this.spacing)
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(this.spacing * 2)
  }
}