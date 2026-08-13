import { scanCore, scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AlertDialog, Toast } from '@kit.ArkUI';

@Entry
@Component
struct ScanCallbackExample {
  @State scanResultText: string = '等待扫码...';
  @State scanHistory: Array<string> = [];

  build() {
    Column({ space: 20 }) {
      Text('默认界面扫码 - Callback方式')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50 })

      Text(this.scanResultText)
        .fontSize(16)
        .margin({ top: 20 })
        .width('90%')
        .textAlign(TextAlign.Center)
        .maxLines(10)

      Text('扫码历史记录')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30 })

      List({ space: 10 }) {
        ForEach(this.scanHistory, (item: string, index: number) => {
          ListItem() {
            Text(item)
              .fontSize(14)
              .width('90%')
              .padding(10)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
          }
        }, (item: string, index: number) => `${index}`)
      }
      .width('90%')
      .height('30%')
      .margin({ top: 10 })

      Row({ space: 10 }) {
        Button('扫码（无参数）')
          .width('45%')
          .height(50)
          .onClick(() => {
            this.startScanNoOptions();
          })

        Button('扫码（带参数）')
          .width('45%')
          .height(50)
          .onClick(() => {
            this.startScanWithOptions();
          })
      }
      .width('90%')
      .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  private startScanNoOptions(): void {
    try {
      this.scanResultText = '正在扫码...';

      scanBarcode.startScanForResult(
        this.getUIContext().getHostContext(),
        (error: BusinessError, result: scanBarcode.ScanResult) => {
          if (error) {
            this.handleError(error);
            return;
          }

          this.handleSuccess(result, '无参数');
        }
      );
    } catch (error) {
      this.handleError(error as BusinessError);
    }
  }

  private startScanWithOptions(): void {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.QR_CODE, scanCore.ScanType.ONE_D_CODE],
      enableMultiMode: false,
      enableAlbum: true
    };

    try {
      this.scanResultText = '正在扫码（二维码+条形码）...';

      scanBarcode.startScanForResult(
        this.getUIContext().getHostContext(),
        options,
        (error: BusinessError, result: scanBarcode.ScanResult) => {
          if (error) {
            this.handleError(error);
            return;
          }

          this.handleSuccess(result, '指定码类型');
        }
      );
    } catch (error) {
      this.handleError(error as BusinessError);
    }
  }

  private handleSuccess(result: scanBarcode.ScanResult, mode: string): void {
    const codeTypeName = this.getCodeTypeName(result.scanType);
    const timestamp = new Date().toLocaleTimeString();

    const resultText = 
      `[${timestamp}] 扫码成功 (${mode})\n` +
      `码类型: ${codeTypeName}\n` +
      `码内容: ${result.originalValue}`;

    this.scanResultText = resultText;

    // 添加到历史记录
    this.scanHistory.unshift(resultText);
    if (this.scanHistory.length > 10) {
      this.scanHistory.pop();
    }

    hilog.info(0x0001, '[ScanKit]', 
      `扫码成功: type=${result.scanType}, value=${result.originalValue}`);

    Toast.showToast({
      message: '扫码成功'
    });

    // 业务逻辑：根据码内容跳转
    this.handleBusinessLogic(result.originalValue);
  }

  private handleError(error: BusinessError): void {
    hilog.error(0x0001, '[ScanKit]', 
      `扫码失败: Code=${error.code}, Message=${error.message}`);

    switch (error.code) {
      case 1000500002:
        this.scanResultText = '用户取消扫码';
        Toast.showToast({ message: '已取消扫码' });
        break;
      case 401:
        this.scanResultText = '参数错误';
        AlertDialog.show({
          message: '扫码参数配置错误'
        });
        break;
      case 1000500001:
        this.scanResultText = '扫码内部错误';
        AlertDialog.show({
          message: '扫码服务异常，请稍后重试',
          primaryButton: {
            value: '重试',
            action: () => this.startScanWithOptions()
          }
        });
        break;
      default:
        this.scanResultText = `扫码失败: ${error.message}`;
    }
  }

  private handleBusinessLogic(codeContent: string): void {
    // 根据码内容执行业务逻辑
    if (codeContent.startsWith('http://') || codeContent.startsWith('https://')) {
      // 网址：提示用户打开浏览器
      AlertDialog.show({
        message: `检测到网址: ${codeContent}\n是否打开浏览器？`,
        primaryButton: {
          value: '打开',
          action: () => {
            // 调用浏览器打开网址
            hilog.info(0x0001, '[ScanKit]', `打开网址: ${codeContent}`);
          }
        },
        secondaryButton: {
          value: '取消',
          action: () => {}
        }
      });
    } else if (codeContent.match(/^\d+$/) && codeContent.length >= 8) {
      // 条形码：商品编码
      AlertDialog.show({
        message: `检测到商品条码: ${codeContent}\n是否查询商品信息？`,
        primaryButton: {
          value: '查询',
          action: () => {
            // 调用商品查询API
            hilog.info(0x0001, '[ScanKit]', `查询商品: ${codeContent}`);
          }
        }
      });
    } else {
      // 其他内容：直接显示
      hilog.info(0x0001, '[ScanKit]', `其他内容: ${codeContent}`);
    }
  }

  private getCodeTypeName(scanType: scanCore.ScanType): string {
    const typeNames: Record<number, string> = {
      0: '未知类型',
      1: 'AZTEC',
      2: 'CODABAR',
      3: 'CODE 39',
      4: 'CODE 93',
      5: 'CODE 128',
      6: 'DATA MATRIX',
      7: 'EAN-8',
      8: 'EAN-13',
      9: 'ITF-14',
      10: 'PDF417',
      11: 'QR CODE',
      12: 'UPC-A',
      13: 'UPC-E',
      14: '多功能码',
      100: '条形码',
      101: '二维码',
      1001: '所有类型'
    };

    return typeNames[scanType] || '未知';
  }
}