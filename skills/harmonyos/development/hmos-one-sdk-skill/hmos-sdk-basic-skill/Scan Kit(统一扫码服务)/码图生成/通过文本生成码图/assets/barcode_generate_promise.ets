import { scanCore, generateBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'BarcodeGeneratePromise';
const DOMAIN = 0x0001;

export async function generateQRCodePromise(content: string, width: number, height: number): Promise<image.PixelMap | undefined> {
  if (!content || content.length === 0) {
    hilog.error(DOMAIN, TAG, 'Content is empty or null');
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
  
  if (content.length > 512) {
    hilog.error(DOMAIN, TAG, `QR Code content length ${content.length} exceeds 512 characters`);
    return undefined;
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
    const pixelMap: image.PixelMap = await generateBarcode.createBarcode(content, options);
    const imageInfo = pixelMap.getImageInfoSync();
    hilog.info(DOMAIN, TAG, `Succeeded in generating QR Code. Size: ${imageInfo.size.width}x${imageInfo.size.height}`);
    return pixelMap;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Failed to generate QR Code. Code: ${err.code}, message: ${err.message}`);
    return undefined;
  }
}

export async function generateBarcodeWithType(content: string, scanType: scanCore.ScanType, width: number, height: number): Promise<image.PixelMap | undefined> {
  if (!content || content.length === 0) {
    hilog.error(DOMAIN, TAG, 'Content is empty or null');
    return undefined;
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
    const pixelMap: image.PixelMap = await generateBarcode.createBarcode(content, options);
    const imageInfo = pixelMap.getImageInfoSync();
    hilog.info(DOMAIN, TAG, `Succeeded in generating barcode type ${scanType}. Size: ${imageInfo.size.width}x${imageInfo.size.height}`);
    return pixelMap;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Failed to generate barcode type ${scanType}. Code: ${err.code}, message: ${err.message}`);
    return undefined;
  }
}

export function validateEAN13(content: string): boolean {
  if (content.length !== 12) {
    hilog.error(DOMAIN, TAG, 'EAN-13 requires 12 digits input');
    return false;
  }
  
  if (!/^\d+$/.test(content)) {
    hilog.error(DOMAIN, TAG, 'EAN-13 only supports digits');
    return false;
  }
  
  if (content.startsWith('0')) {
    hilog.error(DOMAIN, TAG, 'EAN-13 first digit cannot be 0');
    return false;
  }
  
  return true;
}

export function validateUPCA(content: string): boolean {
  if (content.length !== 11) {
    hilog.error(DOMAIN, TAG, 'UPC-A requires 11 digits input');
    return false;
  }
  
  if (!/^\d+$/.test(content)) {
    hilog.error(DOMAIN, TAG, 'UPC-A only supports digits');
    return false;
  }
  
  return true;
}

export async function generateEAN13Barcode(content: string, width: number, height: number): Promise<image.PixelMap | undefined> {
  if (!validateEAN13(content)) {
    return undefined;
  }
  
  return await generateBarcodeWithType(content, scanCore.ScanType.EAN13_CODE, width, height);
}

export async function generateUPABarcode(content: string, width: number, height: number): Promise<image.PixelMap | undefined> {
  if (!validateUPCA(content)) {
    return undefined;
  }
  
  return await generateBarcodeWithType(content, scanCore.ScanType.UPC_A_CODE, width, height);
}