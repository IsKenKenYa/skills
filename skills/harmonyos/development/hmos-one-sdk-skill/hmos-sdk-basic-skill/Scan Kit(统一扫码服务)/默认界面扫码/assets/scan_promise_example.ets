import { scanCore, scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AlertDialog, Toast } from '@kit.ArkUI';

@Entry
@Component
struct ScanPromiseExample {
  @State scanResultText: string = '等待扫码...';

  build() {
    Column({ space: 20 }) {
      Text('默认界面扫码 - Promise方式')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50 })

      Text(this.scanResultText)
        .fontSize(16)
        .margin({ top: 20 })
        .width('90%')
        .textAlign(TextAlign.Center)

      Button('开始扫码（所有码类型）')
        .width('80%')
        .height(50)
        .margin({ top: 30 })
        .onClick(() => {
          this.startScanAllTypes();
        })

      Button('开始扫码（仅二维码）')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.startScanQRCode();
        })

      Button('开始扫码（多码识别）')
        .width('80%')
        .height(50)
        .margin({ top: 10 })
        .onClick(() => {
          this.startScanMultiMode();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  private async startScanAllTypes(): Promise<void> {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: false,
      enableAlbum: true
    };

    try {
      this.scanResultText = '正在扫码...';
      const result = await scanBarcode.startScanForResult(
        this.getUIContext().getHostContext(),
        options
      );

      this.handleSuccess(result, '所有码类型');
    } catch (error) {
      this.handleError(error as BusinessError);
    }
  }

  private async startScanQRCode(): Promise<void> {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.QR_CODE],
      enableMultiMode: false,
      enableAlbum: true
    };

    try {
      this.scanResultText = '正在扫码...';
      const result = await scanBarcode.startScanForResult(
        this.getUIContext().getHostContext(),
        options
      );

      this.handleSuccess(result, '二维码');
    } catch (error) {
      this.handleError(error as BusinessError);
    }
  }

  private async startScanMultiMode(): Promise<void> {
    const options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: true,
      enableAlbum: true
    };

    try {
      this.scanResultText = '正在扫码（多码模式）...';
      const result = await scanBarcode.startScanForResult(
        this.getUIContext().getHostContext(),
        options
      );

      this.handleSuccess(result, '多码识别');
    } catch (error) {
      this.handleError(error as BusinessError);
    }
  }

  private handleSuccess(result: scanBarcode.ScanResult, mode: string): void {
    const codeTypeName = this.getCodeTypeName(result.scanType);
    const sourceName = result.source === scanCore.ScanSource.CAMERA ? '相机' : '相册';

    this.scanResultText = 
      `扫码成功 (${mode})\n` +
      `码类型: ${codeTypeName}\n` +
      `码内容: ${result.originalValue}\n` +
      `扫码来源: ${sourceName}`;

    if (result.scanCodeRect) {
      this.scanResultText += 
        `\n位置: (${result.scanCodeRect.left}, ${result.scanCodeRect.top})`;
    }

    if (result.isGS1) {
      this.scanResultText += '\n携带GS1数据';
    }

    hilog.info(0x0001, '[ScanKit]', 
      `扫码成功: type=${result.scanType}, value=${result.originalValue}`);

    Toast.showToast({
      message: '扫码成功'
    });
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
          message: '扫码参数配置错误，请检查设置'
        });
        break;
      case 1000500001:
        this.scanResultText = '扫码内部错误';
        AlertDialog.show({
          message: '扫码服务异常，请稍后重试',
          primaryButton: {
            value: '重试',
            action: () => this.startScanAllTypes()
          }
        });
        break;
      default:
        this.scanResultText = `扫码失败: ${error.message}`;
        AlertDialog.show({
          message: `扫码失败: ${error.message}`
        });
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