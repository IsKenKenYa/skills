---
name: hmos-scan-kit-barcode-generate
description: 通过文本或字节数组生成码图（二维码/条形码），支持QR Code、Data Matrix、PDF417等12种码制式，最大支持512字符长度，返回PixelMap图像对象，适用于扫码支付、信息录入场景
---

# 通过文本生成码图技能

## 功能描述

本技能提供HarmonyOS Scan Kit的码图生成能力，通过文本或字节数组生成自定义格式的码图（二维码/条形码）。支持将字符串转换为多种格式的码图，包括QR Code、Data Matrix、PDF417、Aztec等二维码，以及EAN-8、EAN-13、UPC-A、UPC-E、Codabar、Code 39、Code 93、Code 128、ITF-14等条形码。

**核心能力**：
- 支持12种码制式生成（QR Code、Data Matrix、PDF417、Aztec、EAN-8、EAN-13、UPC-A、UPC-E、Codabar、Code 39、Code 93、Code 128、ITF-14）
- 返回PixelMap图像对象，可直接用于UI渲染
- 支持自定义码图尺寸（200-4096像素）、颜色、边距
- QR Code支持纠错等级配置（LEVEL_L/M/Q/H）
- 支持文本和字节数组两种输入方式

**适用场景**：扫码支付、信息录入、会员卡生成、票据生成、名片生成等需要将文本信息转换为二维码/条形码的场景。

## 使用场景

### 触发词
- "生成二维码"
- "生成条形码"
- "生成QR码"
- "码图生成"
- "文本转二维码"
- "生成付款码"
- "生成会员卡码"

### 能做
- 将文本字符串转换为二维码/条形码图像
- 生成QR Code、Data Matrix、PDF417等二维码
- 生成EAN-8、EAN-13、Code 39等条形码
- 自定义码图尺寸、颜色、边距
- 为QR Code设置纠错等级
- 通过字节数组生成QR Code
- 返回PixelMap对象用于UI组件渲染

### 绝不做
- 不支持MULTIFUNCTIONAL CODE生成
- 不支持从图片解码生成码图（这是扫码功能）
- 不支持超出参数限制的内容生成（如QR Code超过512字符）
- 不支持格式错误的输入（如UPC-A输入非数字）
- 不在模拟器环境运行（仅支持真机）

### 补充
- 模拟器环境不支持码图生成，调用接口会返回"Emulator is not supported"错误
- 二维码生成建议宽高相同且≥200px，条形码建议宽高比例2:1且宽度>400px
- 码图颜色和背景应保持高对比度以提高识别率
- 码图生成后需要手动释放PixelMap内存以避免内存泄漏

## 调用规范和规则

### 输入约束
- **文本长度限制**：
  - QR Code/Aztec/PDF417/Data Matrix：不超过512字符
  - Code 39/Code 93/Code 128：不超过80字节
  - Codabar：不超过512字符
  - ITF-14：不超过80位数字，必须是偶数位
  - EAN-8：7位数字
  - EAN-13：12位数字，首位不能为0
  - UPC-A：11位数字
  - UPC-E：7位数字，首位需为0或1
- **字节数组长度限制**：
  - LEVEL_L/M：不超过2048字节
  - LEVEL_Q：不超过1536字节
  - LEVEL_H：不超过1024字节
- **码图尺寸**：宽高范围[200, 4096]像素
- **边距范围**：[1, 10]像素，默认为1
- **颜色格式**：HEX格式（如0xFFFFFF白色，0x000000黑色）

### 执行约束
- **最大耗时**：码图生成通常在100-500ms内完成
- **内存限制**：PixelMap序列化大小最大128MB
- **设备支持**：仅支持真机，不支持模拟器
- **API版本**：起始版本4.1.0(11)，字节数组输入从5.0.0(12)开始支持

### 内容约束
- **禁止生成内容**：
  - 不生成包含违法违规信息的码图
  - 不生成超出字符限制的内容
  - 不生成格式错误的码图（如非数字输入数字码）
- **参数校验要求**：
  - 必须校验scanType参数是否正确
  - 必须校验width和height是否在[200, 4096]范围内
  - 必须校验文本内容是否符合对应码类型的格式要求

### 降级约束
- **参数错误降级**：提示用户检查输入内容和参数配置
- **内部错误降级**：提示用户重新调用接口，并建议检查系统状态
- **模拟器环境降级**：提示用户切换到真机环境运行
- **内存不足降级**：释放其他PixelMap资源后重新尝试

## 调用流程和步骤

### 步骤1：准备阶段

**导入模块**：
```typescript
import { scanCore, generateBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```

**参数准备**：
根据码类型准备正确的参数：
- QR Code：文本内容≤512字符，宽高相同且≥200px
- 条形码：符合格式要求（数字/字符），宽高比例建议2:1，宽度>400px
- 字节数组：仅支持QR Code，长度符合纠错等级限制

**参数校验**：
```typescript
function validateBarcodeParams(content: string, options: generateBarcode.CreateOptions): boolean {
  if (options.width < 200 || options.width > 4096) {
    hilog.error(0x0001, '[Barcode]', 'Width must be in range [200, 4096]');
    return false;
  }
  if (options.height < 200 || options.height > 4096) {
    hilog.error(0x0001, '[Barcode]', 'Height must be in range [200, 4096]');
    return false;
  }
  
  const scanType = options.scanType;
  if (scanType === scanCore.ScanType.QR_CODE && content.length > 512) {
    hilog.error(0x0001, '[Barcode]', 'QR Code content exceeds 512 characters');
    return false;
  }
  
  return true;
}
```

### 步骤2：调用API（Promise方式）

**示例代码**：
```typescript
async function generateQRCodePromise(content: string, width: number, height: number): Promise<image.PixelMap | undefined> {
  let options: generateBarcode.CreateOptions = {
    scanType: scanCore.ScanType.QR_CODE,
    height: height,
    width: width,
    backgroundColor: 0xFFFFFF,
    pixelMapColor: 0x000000,
    margin: 1,
    level: generateBarcode.ErrorCorrectionLevel.LEVEL_H
  };
  
  if (!validateBarcodeParams(content, options)) {
    return undefined;
  }
  
  try {
    const pixelMap: image.PixelMap = await generateBarcode.createBarcode(content, options);
    hilog.info(0x0001, '[Barcode]', `Succeeded in generating QR Code, size: ${pixelMap.getImageInfoSync().size}`);
    return pixelMap;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(0x0001, '[Barcode]', `Failed to generate QR Code. Code: ${err.code}, message: ${err.message}`);
    return undefined;
  }
}
```

### 步骤3：调用API（Callback方式）

**示例代码**：
```typescript
function generateQRCodeCallback(content: string, width: number, height: number, callback: (pixelMap: image.PixelMap | undefined) => void): void {
  let options: generateBarcode.CreateOptions = {
    scanType: scanCore.ScanType.QR_CODE,
    height: height,
    width: width
  };
  
  if (!validateBarcodeParams(content, options)) {
    callback(undefined);
    return;
  }
  
  try {
    generateBarcode.createBarcode(content, options, (err: BusinessError, pixelMap: image.PixelMap) => {
      if (err) {
        hilog.error(0x0001, '[Barcode]', `Failed to generate QR Code. Code: ${err.code}, message: ${err.message}`);
        callback(undefined);
        return;
      }
      hilog.info(0x0001, '[Barcode]', `Succeeded in generating QR Code, size: ${pixelMap.getImageInfoSync().size}`);
      callback(pixelMap);
    });
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(0x0001, '[Barcode]', `Failed to generate QR Code. Code: ${err.code}, message: ${err.message}`);
    callback(undefined);
  }
}
```

### 步骤4：调用API（字节数组方式）

**示例代码**：
```typescript
import { buffer } from '@kit.ArkTS';

async function generateQRCodeFromBytes(contentHex: string, width: number, height: number): Promise<image.PixelMap | undefined> {
  const contentBuffer: ArrayBuffer = buffer.from(contentHex, 'hex').buffer;
  
  let options: generateBarcode.CreateOptions = {
    scanType: scanCore.ScanType.QR_CODE,
    height: height,
    width: width,
    level: generateBarcode.ErrorCorrectionLevel.LEVEL_H
  };
  
  try {
    const pixelMap: image.PixelMap = await generateBarcode.createBarcode(contentBuffer, options);
    hilog.info(0x0001, '[Barcode]', 'Succeeded in generating QR Code from bytes');
    return pixelMap;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    hilog.error(0x0001, '[Barcode]', `Failed to generate QR Code from bytes. Code: ${err.code}, message: ${err.message}`);
    return undefined;
  }
}
```

### 步骤5：错误处理

**错误处理代码**：
```typescript
async function generateBarcodeWithErrorHandling(content: string, options: generateBarcode.CreateOptions): Promise<image.PixelMap | undefined> {
  try {
    const pixelMap = await generateBarcode.createBarcode(content, options);
    return pixelMap;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    switch (err.code) {
      case 401:
        hilog.error(0x0001, '[Barcode]', 'Parameter error. Check content format and parameter types.');
        break;
      case 1000500001:
        hilog.error(0x0001, '[Barcode]', 'Internal error. Algorithm failed. Try again.');
        break;
      default:
        hilog.error(0x0001, '[Barcode]', `Unknown error. Code: ${err.code}, message: ${err.message}`);
    }
    
    return undefined;
  }
}
```

### 步骤6：降级处理

**降级处理代码**：
```typescript
async function generateBarcodeWithFallback(content: string, options: generateBarcode.CreateOptions): Promise<image.PixelMap | undefined> {
  try {
    return await generateBarcode.createBarcode(content, options);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    if (err.code === 1000500001) {
      hilog.warn(0x0001, '[Barcode]', 'Internal error detected, retrying with default options...');
      
      const fallbackOptions: generateBarcode.CreateOptions = {
        scanType: options.scanType,
        width: 200,
        height: 200,
        backgroundColor: 0xFFFFFF,
        pixelMapColor: 0x000000,
        margin: 1
      };
      
      try {
        return await generateBarcode.createBarcode(content, fallbackOptions);
      } catch (retryError) {
        hilog.error(0x0001, '[Barcode]', 'Fallback generation failed. Please check system status.');
        return undefined;
      }
    }
    
    hilog.error(0x0001, '[Barcode]', `Generation failed. Code: ${err.code}, message: ${err.message}`);
    return undefined;
  }
}
```

### 步骤7：渲染和释放

**UI渲染示例**：
```typescript
@Entry
@Component
struct BarcodePage {
  @State pixelMap: image.PixelMap | undefined = undefined;
  
  build() {
    Column() {
      Button('Generate QR Code')
        .onClick(async () => {
          this.pixelMap = await generateQRCodePromise('Huawei', 300, 300);
        })
      
      if (this.pixelMap) {
        Image(this.pixelMap)
          .width(300)
          .height(300)
          .objectFit(ImageFit.Contain)
      }
    }
  }
  
  aboutToDisappear() {
    if (this.pixelMap) {
      this.pixelMap.release();
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 可能原因 | 解决方法 |
|-------|------|---------|---------|
| 401 | Parameter error | 1. 参数类型错误<br>2. 参数校验失败 | 检查参数类型和取值范围，确保符合API要求 |
| 1000500001 | Internal error | 1. 码图生成算法失败<br>2. 创建PixelMap失败<br>3. 系统异常 | 重新调用接口，检查系统状态，释放内存后重试 |

**错误码详细信息**：
- **401错误**：常见于输入内容格式不符合码类型要求（如UPC-A输入非数字），或宽高参数超出[200, 4096]范围
- **1000500001错误**：常见于算法异常、系统内存不足、PixelMap创建失败，建议检查系统状态并重试

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ScanKit": "从API version 4.1.0(11)开始支持",
    "@kit.ImageKit": "用于PixelMap对象处理",
    "@kit.BasicServicesKit": "用于BusinessError错误处理",
    "@kit.PerformanceAnalysisKit": "用于hilog日志输出",
    "@kit.ArkTS": "用于buffer模块（字节数组输入时需要）"
  }
}
```

### 环境要求
- **HarmonyOS版本**：API version 4.1.0(11)及以上
- **设备类型**：Phone、Tablet、Wearable(5.1.0(18))、PC/2in1(5.1.1(19))、TV(5.1.1(19))
- **运行环境**：仅支持真机，不支持模拟器
- **系统能力**：SystemCapability.Multimedia.Scan.GenerateBarcode

### 常见编译问题

**问题1：找不到@kit.ScanKit模块**
```
Error: Cannot find module '@kit.ScanKit'
```
**解决方法**：确保HarmonyOS SDK版本≥4.1.0(11)，在oh-package.json5中添加依赖配置

**问题2：PixelMap类型未定义**
```
Error: Cannot find name 'image.PixelMap'
```
**解决方法**：导入ImageKit模块：`import { image } from '@kit.ImageKit';`

**问题3：BusinessError类型错误**
```
Error: Property 'code' does not exist on type 'Error'
```
**解决方法**：导入BasicServicesKit并使用BusinessError类型：`import { BusinessError } from '@kit.BasicServicesKit';`

**问题4：buffer模块未找到**
```
Error: Cannot find module '@kit.ArkTS' or 'buffer'
```
**解决方法**：字节数组输入需要导入ArkTS模块：`import { buffer } from '@kit.ArkTS';`

## 常见问题与解决方法

### Q1：生成的码图识别率低
**原因**：码图尺寸过小或颜色对比度不足
**解决方法**：
- 二维码：宽高相同且≥200px，建议300-500px
- 条形码：宽高比例2:1，宽度>400px
- 使用默认颜色：黑色码图(0x000000) + 白色背景(0xFFFFFF)

### Q2：UPC-A/EAN-13生成失败
**原因**：输入内容格式不符合要求
**解决方法**：
- UPC-A：输入11位数字（纯数字），系统自动生成12位包含校验位
- EAN-13：输入12位数字（纯数字），首位不能为0，系统自动生成13位包含校验位

### Q3：QR Code内容过长导致码图复杂
**原因**：内容超过512字符导致码图密度过高
**解决方法**：
- 控制内容长度≤512字符
- 使用更高纠错等级（LEVEL_H）提高容错性
- 增大码图尺寸以降低密度

### Q4：模拟器环境调用失败
**原因**：码图生成不支持模拟器环境
**解决方法**：
- 切换到真机设备运行
- 使用真机调试功能测试码图生成

### Q5：PixelMap内存泄漏
**原因**：未及时释放PixelMap对象内存
**解决方法**：
- 在组件销毁时调用`pixelMap.release()`释放内存
- 确保异步方法执行完成后再释放对象
- 避免创建过多PixelMap对象

### Q6：字节数组输入失败
**原因**：字节数组长度超出纠错等级限制
**解决方法**：
- LEVEL_L/M：字节数组≤2048字节
- LEVEL_Q：字节数组≤1536字节
- LEVEL_H：字节数组≤1024字节

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "barcodeType": "QR_CODE",
  "contentLength": 512,
  "pixelMapSize": {
    "width": 300,
    "height": 300
  },
  "apiUsed": [
    "generateBarcode.createBarcode",
    "image.PixelMap.getImageInfoSync"
  ],
  "executionTime": "150ms"
}
```

## 参考文档

- [API开发指南](references/scan-barcodegenerate-guide.md)
- [API参考说明](references/scan-generatebarcode-reference.md)
- [scanCore模块参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scancore)
- [PixelMap接口参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/arkts-apis-image-pixelmap)
- [错误码参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code)

## 完整示例代码

- [ArkTS完整示例（Promise方式）](assets/barcode_generate_promise.ets)
- [ArkTS完整示例（Callback方式）](assets/barcode_generate_callback.ets)
- [ArkTS完整示例（字节数组方式）](assets/barcode_generate_bytes.ets)
- [完整UI示例页面](assets/barcode_page.ets)

## 测试用例

### 正向测试用例
- [QR Code生成测试](tests/test_qrcode_positive.py)：正常生成QR码，验证PixelMap返回
- [条形码生成测试](tests/test_barcode_positive.py)：生成EAN-13码，验证校验位自动生成
- [字节数组生成测试](tests/test_bytes_positive.py)：字节数组输入生成QR码

### 边界测试用例
- [最小尺寸测试](tests/test_min_size.py)：宽高=200px，验证最小尺寸生成
- [最大尺寸测试](tests/test_max_size.py)：宽高=4096px，验证最大尺寸生成
- [最大长度测试](tests/test_max_length.py)：512字符QR码，验证长度限制

### 异常测试用例
- [参数错误测试](tests/test_param_error.py)：宽高超出范围，验证401错误码
- [格式错误测试](tests/test_format_error.py)：UPC-A输入非数字，验证生成失败
- [超长内容测试](tests/test_exceed_length.py)：QR码>512字符，验证生成失败
- [模拟器测试](tests/test_emulator.py)：模拟器环境调用，验证错误提示