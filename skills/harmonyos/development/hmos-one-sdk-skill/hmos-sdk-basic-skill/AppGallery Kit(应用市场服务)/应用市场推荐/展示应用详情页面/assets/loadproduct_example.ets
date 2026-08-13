import { productViewManager } from '@kit.AppGalleryKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'LoadProduct';

@Entry
@Component
struct LoadProductExample {
  @State message: string = '拉起应用市场详情页';
  
  build() {
    Row() {
      Column() {
        Button(this.message)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.loadProductDemo();
          })
          .width('100%')
      }
      .height('100%')
    }
  }
  
  private loadProductDemo(): void {
    try {
      const uiContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
      
      const wantParam: Want = {
        parameters: {
          bundleName: 'com.huawei.hmsapp.books',
        }
      };
      
      const callback: productViewManager.ProductViewCallback = {
        onError: (error: BusinessError) => {
          hilog.error(0, TAG, `loadProduct onError.code is ${error.code}, message is ${error.message}`);
        },
        onAppear: () => {
          hilog.info(0, TAG, `loadProduct onAppear.`);
        },
        onDisappear: () => {
          hilog.info(0, TAG, `loadProduct onDisappear.`);
        }
      };
      
      productViewManager.loadProduct(uiContext, wantParam, callback);
    } catch (err) {
      const error = err as BusinessError;
      hilog.error(0, TAG, `loadProduct failed.code is ${error.code}, message is ${error.message}`);
    }
  }
}