import { mapCommon, map, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';

@Entry
@Component
struct TestInvalidUrl {
  private TAG = 'TestInvalidUrl';
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
      // 测试1: URL缺少占位符
      let params1: mapCommon.MvtOverlayParams = {
        source: {
          tileUrl: 'https://example.com/tiles.pbf', // 缺少{x}、{y}、{z}
          minZoom: 2,
          maxZoom: 15
        },
        layers: [{
          id: 'invalid-url-layer',
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
        this.testResult = 'Test Failed: Invalid URL should throw error';
      } catch (e) {
        if (e.code === 401) {
          this.testResult = 'Test Passed: Invalid URL detected (error 401)';
          console.info(this.TAG, 'Invalid URL test passed');
        } else {
          this.testResult = `Test Failed: Unexpected error code ${e.code}`;
        }
      }

      // 测试2: URL使用非HTTP/HTTPS协议
      let params2: mapCommon.MvtOverlayParams = {
        source: {
          tileUrl: 'ftp://example.com/tiles/{z}/{x}/{y}.pbf',
          minZoom: 2,
          maxZoom: 15
        },
        layers: [{
          id: 'ftp-url-layer',
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
        await this.mapController?.addMvtOverlay(params2);
        this.testResult += '\nTest Failed: FTP URL should throw error';
      } catch (e) {
        this.testResult += '\nTest Passed: Non-HTTP URL detected';
        console.info(this.TAG, 'FTP URL test passed');
      }

      // 测试3: URL为空字符串
      let params3: mapCommon.MvtOverlayParams = {
        source: {
          tileUrl: '',
          minZoom: 2,
          maxZoom: 15
        },
        layers: [{
          id: 'empty-url-layer',
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
        this.testResult += '\nTest Failed: Empty URL should throw error';
      } catch (e) {
        this.testResult += '\nTest Passed: Empty URL detected';
        console.info(this.TAG, 'Empty URL test passed');
      }

    } catch (e) {
      this.testResult = `Test Error: ${e.code} - ${e.message}`;
      console.error(this.TAG, this.testResult);
    }
  }

  build() {
    Column() {
      Text('Invalid URL Test')
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