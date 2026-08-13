import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common } from '@kit.AbilityKit';

const TAG: string = 'AppLinking';

@Entry
@Component
struct AppLinkingExample {
  build() {
    Button('start app linking', { type: ButtonType.Capsule, stateEffect: true })
      .width('87%')
      .height('5%')
      .margin({ bottom: '12vp' })
      .onClick(() => {
        let context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
        let bundleName: string = 'com.huawei.hmsapp.books';
        let link: string = 'https://appgallery.huawei.com/app/detail?id=' + bundleName;
        
        context.openLink(link, { appLinkingOnly: false })
          .then(() => {
            hilog.info(0x0001, TAG, 'openlink success.');
          })
          .catch((error: BusinessError) => {
            hilog.error(0x0001, TAG, `openlink failed. Code: ${error.code}, message is ${error.message}`);
          });
      })
  }
}