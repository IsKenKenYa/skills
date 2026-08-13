import { scanCore, generateBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'BarcodeGenerateCallback';
const DOMAIN = 0x0001;

export function generateQRCodeCallback(content: string, width: number, height: number, callback: (pixelMap: image.PixelMap | undefined, error?: BusinessError) => void): void {
  if (!content || content.length === 0) {
    hilog.error(DOMAIN, TAG, 'Content is empty or null');
    callback(undefined);
    return;
  }
  
  if (width < 200 || width > 4096) {
    hilog.error(DOMAIN, TAG, `Width ${width} is out of range [200, 4096]`);
    callback(undefined);
    return;
  }
  
  if (height < 200 || height > 4096) {
    hilog.error(DOMAIN, TAG, `Height ${height} is out of range [200, 4096]`);
    callback(undefined);
    return;
  }
  
  if (content.length > 512) {
    hilog.error(DOMAIN, TAG, `QR Code content length ${content.length} exceeds 512 characters`);
    callback(undefined);
    return;
  }
  
  let options: generateBarcode.CreateOptions = {
    scanType: scanCore.ScanType.QR_CODE,
    height: height,
    width: width,
    backgroundColor: 0xFFFFFF,
    pixelMapColor: 0x000000,
    margin: 1,
    level: generateBarcode.ErrorCorrectionLevel.LEVEL_H
  };
  
  try {
    generateBarcode.createBarcode(content, options, (err: BusinessError, pixelMap: image.PixelMap) => {
      if (err) {
        hilog.error(DOMAIN, TAG, `Failed to generate QR Code. Code: ${err.code}, message: ${err.message}`);
        callback(undefined, err);
        return;
      }
      
      const imageInfo = pixelMap.getImageInfoSync();
      hilog.info(DOMAIN, TAG, `Succeeded in generating QR Code. Size: ${imageInfo.size.width}x${imageInfo.size.height}`);
      callback(pixelMap);
    });
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Failed to call createBarcode. Code: ${err.code}, message: ${err.message}`);
    callback(undefined, err);
  }
}

export function generateBarcodeWithTypeCallback(content: string, scanType: scanCore.ScanType, width: number, height: number, callback: (pixelMap: image.PixelMap | undefined, error?: BusinessError) => void): void {
  if (!content || content.length === 0) {
    hilog.error(DOMAIN, TAG, 'Content is empty or null');
    callback(undefined);
    return;
  }
  
  let options: generateBarcode.CreateOptions = {
    scanType: scanType,
    height: height,
    width: width,
    backgroundColor: 0xFFFFFF,
    pixelMapColor: 0x000000,
    margin: 1
  };
  
  if (scanType === scanCore.ScanType.QR_CODE) {
    options.level = generateBarcode.ErrorCorrectionLevel.LEVEL_H;
  }
  
  try {
    generateBarcode.createBarcode(content, options, (err: BusinessError, pixelMap: image.PixelMap) => {
      if (err) {
        hilog.error(DOMAIN, TAG, `Failed to generate barcode type ${scanType}. Code: ${err.code}, message: ${err.message}`);
        callback(undefined, err);
        return;
      }
      
      const imageInfo = pixelMap.getImageInfoSync();
      hilog.info(DOMAIN, TAG, `Succeeded in generating barcode type ${scanType}. Size: ${imageInfo.size.width}x${imageInfo.size.height}`);
      callback(pixelMap);
    });
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Failed to call createBarcode. Code: ${err.code}, message: ${err.message}`);
    callback(undefined, err);
  }
}

export function generateQRCodeWithRetry(content: string, width: number, height: number, maxRetries: number = 3, callback: (pixelMap: image.PixelMap | undefined, error?: BusinessError) => void): void {
  let retryCount = 0;
  
  function attemptGenerate() {
    generateQRCodeCallback(content, width, height, (pixelMap, error) => {
      if (pixelMap) {
        callback(pixelMap);
        return;
      }
      
      if (error && error.code === 1000500001 && retryCount < maxRetries) {
        retryCount++;
        hilog.warn(DOMAIN, TAG, `Internal error detected, retrying (attempt ${retryCount}/${maxRetries})...`);
        attemptGenerate();
      } else {
        callback(undefined, error);
      }
    });
  }
  
  attemptGenerate();
}