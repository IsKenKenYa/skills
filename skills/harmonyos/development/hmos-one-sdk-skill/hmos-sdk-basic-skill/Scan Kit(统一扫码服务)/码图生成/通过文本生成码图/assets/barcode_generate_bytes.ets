import { scanCore, generateBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { buffer } from '@kit.ArkTS';

const TAG = 'BarcodeGenerateBytes';
const DOMAIN = 0x0001;

export async function generateQRCodeFromHexBytes(contentHex: string, width: number, height: number, level: generateBarcode.ErrorCorrectionLevel = generateBarcode.ErrorCorrectionLevel.LEVEL_H): Promise<image.PixelMap | undefined> {
  if (!contentHex || contentHex.length === 0) {
    hilog.error(DOMAIN, TAG, 'Hex content is empty or null');
    return undefined;
  }
  
  if (width < 200 || width > 4096) {
    hilog.error(DOMAIN, TAG, `Width ${width} is out of range [200, 4096]`);
    return undefined;
  }
  
  if (height < 200 || height > 4096) {
    hilog.error(DOMAIN, TAG, `Height ${height} is out of range [200, 4096]`);
    return undefined;
  }
  
  const contentBuffer: ArrayBuffer = buffer.from(contentHex, 'hex').buffer;
  const bytesLength = contentBuffer.byteLength;
  
  const maxLength = getMaxLengthForLevel(level);
  if (bytesLength > maxLength) {
    hilog.error(DOMAIN, TAG, `Byte array length ${bytesLength} exceeds limit ${maxLength} for level ${level}`);
    return undefined;
  }
  
  let options: generateBarcode.CreateOptions = {
    scanType: scanCore.ScanType.QR_CODE,
    height: height,
    width: width,
    backgroundColor: 0xFFFFFF,
    pixelMapColor: 0x000000,
    margin: 1,
    level: level
  };
  
  try {
    const pixelMap: image.PixelMap = await generateBarcode.createBarcode(contentBuffer, options);
    const imageInfo = pixelMap.getImageInfoSync();
    hilog.info(DOMAIN, TAG, `Succeeded in generating QR Code from bytes. Size: ${imageInfo.size.width}x${imageInfo.size.height}, Bytes: ${bytesLength}`);
    return pixelMap;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Failed to generate QR Code from bytes. Code: ${err.code}, message: ${err.message}`);
    return undefined;
  }
}

export function getMaxLengthForLevel(level: generateBarcode.ErrorCorrectionLevel): number {
  switch (level) {
    case generateBarcode.ErrorCorrectionLevel.LEVEL_L:
    case generateBarcode.ErrorCorrectionLevel.LEVEL_M:
      return 2048;
    case generateBarcode.ErrorCorrectionLevel.LEVEL_Q:
      return 1536;
    case generateBarcode.ErrorCorrectionLevel.LEVEL_H:
      return 1024;
    default:
      return 1024;
  }
}

export async function generateQRCodeFromBytesWithValidation(contentBuffer: ArrayBuffer, width: number, height: number): Promise<image.PixelMap | undefined> {
  if (!contentBuffer || contentBuffer.byteLength === 0) {
    hilog.error(DOMAIN, TAG, 'ArrayBuffer is empty or null');
    return undefined;
  }
  
  if (width < 200 || width > 4096) {
    hilog.error(DOMAIN, TAG, `Width ${width} is out of range [200, 4096]`);
    return undefined;
  }
  
  if (height < 200 || height > 4096) {
    hilog.error(DOMAIN, TAG, `Height ${height} is out of range [200, 4096]`);
    return undefined;
  }
  
  const bytesLength = contentBuffer.byteLength;
  const maxLength = 1024;
  
  if (bytesLength > maxLength) {
    hilog.error(DOMAIN, TAG, `Byte array length ${bytesLength} exceeds limit ${maxLength} for LEVEL_H`);
    return undefined;
  }
  
  let options: generateBarcode.CreateOptions = {
    scanType: scanCore.ScanType.QR_CODE,
    height: height,
    width: width,
    level: generateBarcode.ErrorCorrectionLevel.LEVEL_H
  };
  
  try {
    const pixelMap: image.PixelMap = await generateBarcode.createBarcode(contentBuffer, options);
    const imageInfo = pixelMap.getImageInfoSync();
    hilog.info(DOMAIN, TAG, `Succeeded in generating QR Code from ArrayBuffer. Size: ${imageInfo.size.width}x${imageInfo.size.height}, Bytes: ${bytesLength}`);
    return pixelMap;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Failed to generate QR Code from ArrayBuffer. Code: ${err.code}, message: ${err.message}`);
    return undefined;
  }
}