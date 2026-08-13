import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct TestLocalMvtOverlay {
  private TAG = 'TestLocalMvtOverlay';
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
        this.testResult = `Failed: ${err.code} - ${err.message}`;
      }
    };
  }

  private async runTest(): Promise<void> {
    try {
      // 测试: 本地加载矢量图层
      let params: mapCommon.MvtOverlayParams = {
        source: {
          tileProvider: this.tileProviderMethod,
          minZoom: 2,
          maxZoom: 15
        },
        layers: [{
          id: 'local-layer',
          type: mapCommon.MvtLayerType.FILL,
          sourceLayer: 'local',
          paint: {
            fillColor: {
              operator: mapCommon.Operator.GET,
              args: 'fill'
            },
            fillOpacity: {
              operator: mapCommon.Operator.GET,
              args: 'fill-opacity'
            }
          }
        }]
      };

      let mvtOverlay = await this.mapController?.addMvtOverlay(params);
      if (mvtOverlay) {
        this.testResult = 'Test Passed: Local MVT overlay added successfully';
        console.info(this.TAG, this.testResult);
      } else {
        this.testResult = 'Test Failed: MVT overlay is null';
        console.error(this.TAG, this.testResult);
      }

      // 测试: 模糊度设置
      mvtOverlay?.setBlur(5);
      let blur = mvtOverlay?.getBlur();
      if (blur === 5) {
        this.testResult += '\nTest Passed: Blur set successfully';
        console.info(this.TAG, 'Blur test passed');
      } else {
        this.testResult += '\nTest Failed: Blur value mismatch';
        console.error(this.TAG, 'Blur test failed');
      }

    } catch (e) {
      this.testResult = `Test Failed: ${e.code} - ${e.message}`;
      console.error(this.TAG, this.testResult);
    }
  }

  // 模拟本地瓦片提供器
  private tileProviderMethod(x: number, y: number, z: number): Promise<ArrayBuffer> {
    return new Promise((resolve, reject) => {
      try {
        // 模拟返回空的ArrayBuffer数据
        let buffer = new ArrayBuffer(0);
        resolve(buffer);
        console.info(this.TAG, `Tile loaded: x=${x}, y=${y}, z=${z}`);
      } catch (error) {
        reject(error);
      }
    });
  }

  build() {
    Column() {
      Text('Local MVT Overlay Test')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      MapComponent({ mapOptions: this.mapOptions, mapCallback: this.callback })
        .width('100%')
        .height('60%');

      Text(this.testResult)
        .fontSize(14)
        .margin({ top: 20 })
        .padding(10)
        .backgroundColor('#F0F0F0');
    }
    .width('100%')
    .height('100%');
  }
}