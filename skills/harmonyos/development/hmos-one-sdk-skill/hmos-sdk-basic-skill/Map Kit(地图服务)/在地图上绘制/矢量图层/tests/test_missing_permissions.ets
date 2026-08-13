import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct TestMissingPermissions {
  private TAG = 'TestMissingPermissions';
  private mapOptions?: mapCommon.MapOptions;
  private mapController?: map.MapComponentController;
  private callback?: AsyncCallback<map.MapComponentController>;
  private testResult: string = '';

  aboutToAppear(): void {
    this.mapOptions = {
      position: {
        target: {
          latitude: 35.899780,
          longitude: 107.766172
        },
        zoom: 6
      },
      scaleControlsEnabled: true
    };

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController;
        await this.runTest();
      } else {
        this.testResult = `Map Init Failed: ${err.code} - ${err.message}`;
      }
    };
  }

  private async runTest(): Promise<void> {
    try {
      // 测试说明: 此测试需在未配置权限的情况下运行
      // 实际场景中，应该提示用户配置权限
      
      let params: mapCommon.MvtOverlayParams = {
        source: {
          tileUrl: 'https://example.com/tiles/{z}/{x}/{y}.pbf',
          minZoom: 2,
          maxZoom: 15
        },
        layers: [{
          id: 'permission-test-layer',
          type: mapCommon.MvtLayerType.FILL,
          sourceLayer: 'test',
          paint: {
            fillColor: {
              operator: mapCommon.Operator.GET,
              args: 'fill'
            }
          }
        }]
      };

      // 尝试添加矢量图层
      // 如果缺少权限，应该会失败或提示
      try {
        let mvtOverlay = await this.mapController?.addMvtOverlay(params);
        
        // 检查是否成功添加（如果权限未配置但测试通过了）
        if (mvtOverlay) {
          this.testResult = 'Test Note: MVT overlay added, but check if permissions are configured in module.json5';
          console.warn(this.TAG, 'Permissions may not be properly configured');
        } else {
          this.testResult = 'Test Failed: MVT overlay is null';
        }
      } catch (e) {
        // 如果权限缺失导致错误
        this.testResult = `Test Passed: Permission error detected - ${e.code}: ${e.message}`;
        console.info(this.TAG, 'Permission test passed');
        
        // 提示用户需要配置的权限
        this.testResult += '\nRequired permissions:';
        this.testResult += '\n- ohos.permission.LOCATION';
        this.testResult += '\n- ohos.permission.APPROXIMATELY_LOCATION';
        this.testResult += '\n- ohos.permission.INTERNET (for online tiles)';
      }

    } catch (e) {
      this.testResult = `Test Error: ${e.code} - ${e.message}`;
      console.error(this.TAG, this.testResult);
    }
  }

  build() {
    Column() {
      Text('Permission Test')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Text('This test should be run without permissions configured in module.json5')
        .fontSize(12)
        .fontColor('#FF0000')
        .margin({ bottom: 10 });

      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('60%');

      Text(this.testResult)
        .fontSize(14)
        .margin({ top: 20 })
        .padding(10)
        .backgroundColor('#FFF0F0');
    }
    .width('100%')
    .height('100%');
  }
}