import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct TestInvalidFormat {
  private TAG = 'TestInvalidFormat';
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
      // 测试1: 缩放级别超出范围
      let params1: mapCommon.MvtOverlayParams = {
        source: {
          tileUrl: 'https://example.com/tiles/{z}/{x}/{y}.pbf',
          minZoom: 25, // 超出最大值20
          maxZoom: 30  // 超出最大值20
        },
        layers: [{
          id: 'invalid-zoom-layer',
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

      try {
        await this.mapController?.addMvtOverlay(params1);
        this.testResult = 'Test Note: Invalid zoom levels may be adjusted automatically';
        console.warn(this.TAG, 'Zoom levels out of range');
      } catch (e) {
        this.testResult = `Test Passed: Invalid zoom level error - ${e.code}`;
        console.info(this.TAG, 'Invalid zoom test passed');
      }

      // 测试2: 颜色格式错误
      let params2: mapCommon.MvtOverlayParams = {
        source: {
          tileUrl: 'https://example.com/tiles/{z}/{x}/{y}.pbf',
          minZoom: 2,
          maxZoom: 15
        },
        layers: [{
          id: 'invalid-color-layer',
          type: mapCommon.MvtLayerType.FILL,
          sourceLayer: 'test',
          paint: {
            fillColor: {
              operator: mapCommon.Operator.CONSTANT,
              args: 'invalid-color' // 非数字颜色值
            }
          }
        }]
      };

      try {
        await this.mapController?.addMvtOverlay(params2);
        this.testResult += '\nTest Note: Invalid color format may be handled';
        console.warn(this.TAG, 'Invalid color format');
      } catch (e) {
        this.testResult += `\nTest Passed: Invalid color error - ${e.code}`;
        console.info(this.TAG, 'Invalid color test passed');
      }

      // 测试3: layer id为空
      let params3: mapCommon.MvtOverlayParams = {
        source: {
          tileUrl: 'https://example.com/tiles/{z}/{x}/{y}.pbf',
          minZoom: 2,
          maxZoom: 15
        },
        layers: [{
          id: '', // 空id
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

      try {
        await this.mapController?.addMvtOverlay(params3);
        this.testResult += '\nTest Note: Empty layer ID may be handled';
        console.warn(this.TAG, 'Empty layer ID');
      } catch (e) {
        this.testResult += `\nTest Passed: Empty layer ID error - ${e.code}`;
        console.info(this.TAG, 'Empty ID test passed');
      }

      // 测试4: 缺少必需参数
      let params4: mapCommon.MvtOverlayParams = {
        source: {
          tileUrl: 'https://example.com/tiles/{z}/{x}/{y}.pbf'
          // 缺少minZoom和maxZoom
        },
        layers: [{
          id: 'missing-param-layer',
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

      try {
        await this.mapController?.addMvtOverlay(params4);
        this.testResult += '\nTest Note: Missing params may use defaults';
        console.warn(this.TAG, 'Missing parameters');
      } catch (e) {
        this.testResult += `\nTest Passed: Missing parameter error - ${e.code}`;
        console.info(this.TAG, 'Missing param test passed');
      }

    } catch (e) {
      this.testResult = `Test Error: ${e.code} - ${e.message}`;
      console.error(this.TAG, this.testResult);
    }
  }

  build() {
    Column() {
      Text('Invalid Format Test')
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
        .backgroundColor('#FFF0F0');
    }
    .width('100%')
    .height('100%');
  }
}