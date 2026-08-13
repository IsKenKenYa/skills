---
name: hmos-scan-kit-default-scan
description: 启动系统默认扫码界面进行二维码/条形码扫描，支持多种码类型识别和相册扫码，无需申请相机权限，适用于应用内扫码、商品条码扫描、二维码识别场景
---

# 默认界面扫码技能

## 功能描述

本技能提供HarmonyOS默认界面扫码能力的完整实现方案，通过调用Scan Kit的startScanForResult接口启动系统级扫码界面，支持单码和多码识别、多种码类型（QR Code、Bar Code、Data Matrix等）、相册扫码功能。系统对相机权限进行了预授权且调用期间处于安全访问状态，开发者无需申请相机权限即可使用。

**核心能力**：
- 系统级一致的扫码界面体验
- 支持多种主流码类型识别
- 单码和多码识别模式
- 相册扫码入口
- 暗光环境闪光灯开启提示
- 无需申请相机权限

**技术特点**：
- API版本：4.0.0(10)起始，推荐使用4.1.0(11)及以上版本
- 仅支持Stage模型
- 支持元服务API（4.1.0(11)及以上）
- 支持悬浮屏、分屏场景（6.0.0(20)及以上）

## 使用场景

### 触发词
- "默认界面扫码"
- "扫码功能"
- "二维码扫描"
- "条形码扫描"
- "启动扫码界面"
- "scanBarcode"
- "startScanForResult"

### 能做
- 启动系统默认扫码界面进行二维码/条形码扫描
- 配置扫码类型（支持ALL、QR Code、Bar Code等多种类型）
- 开启/关闭多码识别模式
- 开启/关闭相册扫码入口
- 获取扫码结果（码类型、码内容、位置信息等）
- 处理扫码成功、失败、取消等场景
- 在Wearable设备上使用（需带后置相机，6.1.0(23)及以上）

### 绝不做
- 不提供自定义扫码界面UI（如需自定义界面请使用自定义界面扫码API）
- 不支持相册多码识别（相册仅支持单码识别）
- 不支持在UIAbility生命周期外调用
- 不支持在FA模型下使用
- 不处理码内容解析和业务逻辑（仅返回原始码值）

### 补充
- 首次使用时系统会弹出隐私横幅提醒
- 从6.1.0(23)版本开始，扫码界面标题支持根据scanTypes动态显示
- 扫码界面UX为系统级统一体验，不支持添加自定义设置
- 建议同时接入"扫码直达"服务以支持系统扫码入口
- 模拟器支持默认界面扫码开发（6.0.0(20)及以上）

## 调用规范和规则

### 输入约束
- Context对象：必须是有效的UIAbility Context或UIContext的HostContext
- 扫码类型：必须是ScanType枚举值，支持数组形式传入多种类型
- 多码模式：布尔值，true表示多码识别，false表示单码识别
- 相册开关：布尔值，true表示开启相册扫码，false表示关闭

### 执行约束
- 调用时机：必须在页面和组件的生命周期内调用
- 权限要求：无需申请相机权限，系统预授权
- 最大耗时：无明确限制，由用户扫码操作决定
- API调用频次：无限制

### 内容约束
- 禁止在UIAbility生命周期外调用startScanForResult
- 禁止使用已废弃的startScan方法（4.1.0(11)起废弃）
- 禁止在自定义组件的build函数外获取Context
- 禁止使用eval、exec等高危函数处理扫码结果

### 降级约束
- 用户取消扫码：返回错误码1000500002，需友好提示用户
- 设备不支持扫码：使用scanCore.isDefaultScanSupported接口预检查（API 26.0.0及以上）
- 参数错误：返回错误码401，需校验参数类型和格式
- 内部错误：返回错误码1000500001，需记录日志并提示用户重试

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备是否支持默认界面扫码（API 26.0.0及以上）
2. 获取有效的UIAbility Context或UIContext
3. 确认当前处于页面或组件的生命周期内

**参数准备**：
```typescript
import { scanCore, scanBarcode } from '@kit.ScanKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义扫码参数
let options: scanBarcode.ScanOptions = {
  scanTypes: [scanCore.ScanType.ALL],  // 支持所有码类型
  enableMultiMode: true,                // 开启多码识别
  enableAlbum: true                     // 开启相册扫码
};
```

### 步骤2：调用API（Promise方式）

**示例代码**：
```typescript
@Entry
@Component
struct ScanPage {
  build() {
    Column() {
      Button('开始扫码')
        .onClick(() => {
          this.startScan();
        })
    }
  }

  private async startScan(): Promise<void> {
    let options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: true,
      enableAlbum: true
    };

    try {
      const result: scanBarcode.ScanResult = 
        await scanBarcode.startScanForResult(
          this.getUIContext().getHostContext(), 
          options
        );
      
      hilog.info(0x0001, '[ScanKit]', 
        `扫码成功: ${JSON.stringify(result)}`);
      
      // 处理扫码结果
      this.handleScanResult(result);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(0x0001, '[ScanKit]', 
        `扫码失败: Code=${err.code}, Message=${err.message}`);
      this.handleScanError(err);
    }
  }

  private handleScanResult(result: scanBarcode.ScanResult): void {
    // 解析码值结果，跳转应用服务页
    hilog.info(0x0001, '[ScanKit]', 
      `码类型: ${result.scanType}, 码内容: ${result.originalValue}`);
    
    if (result.scanCodeRect) {
      hilog.info(0x0001, '[ScanKit]', 
        `码位置: left=${result.scanCodeRect.left}, top=${result.scanCodeRect.top}`);
    }
  }

  private handleScanError(error: BusinessError): void {
    switch (error.code) {
      case 1000500002:
        hilog.warn(0x0001, '[ScanKit]', '用户取消扫码');
        break;
      case 401:
        hilog.error(0x0001, '[ScanKit]', '参数错误');
        break;
      case 1000500001:
        hilog.error(0x0001, '[ScanKit]', '内部错误');
        break;
      default:
        hilog.error(0x0001, '[ScanKit]', `未知错误: ${error.message}`);
    }
  }
}
```

### 步骤3：调用API（Callback方式）

**示例代码**：
```typescript
@Entry
@Component
struct ScanPageWithCallback {
  build() {
    Column() {
      Button('开始扫码 (Callback)')
        .onClick(() => {
          this.startScanWithCallback();
        })
    }
  }

  private startScanWithCallback(): void {
    let options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.QR_CODE],  // 仅扫描二维码
      enableMultiMode: false,                   // 单码识别
      enableAlbum: true
    };

    try {
      scanBarcode.startScanForResult(
        this.getUIContext().getHostContext(),
        options,
        (error: BusinessError, result: scanBarcode.ScanResult) => {
          if (error) {
            hilog.error(0x0001, '[ScanKit]', 
              `扫码失败: Code=${error.code}, Message=${error.message}`);
            this.handleScanError(error);
            return;
          }

          hilog.info(0x0001, '[ScanKit]', 
            `扫码成功: ${JSON.stringify(result)}`);
          this.handleScanResult(result);
        }
      );
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(0x0001, '[ScanKit]', 
        `启动扫码失败: Code=${err.code}, Message=${err.message}`);
    }
  }

  private handleScanResult(result: scanBarcode.ScanResult): void {
    // 业务逻辑处理
  }

  private handleScanError(error: BusinessError): void {
    // 错误处理
  }
}
```

### 步骤4：降级处理

**设备兼容性检查**：
```typescript
import { scanCore } from '@kit.ScanKit';

async function checkScanSupport(): Promise<boolean> {
  try {
    // API 26.0.0及以上版本支持
    const isSupported = scanCore.isDefaultScanSupported();
    if (!isSupported) {
      hilog.warn(0x0001, '[ScanKit]', '当前设备不支持默认界面扫码');
      // 降级方案：提示用户或使用其他扫码方式
      return false;
    }
    return true;
  } catch (error) {
    hilog.error(0x0001, '[ScanKit]', '检查扫码支持失败');
    return false;
  }
}
```

**错误降级方案**：
```typescript
async function startScanWithFallback(): Promise<void> {
  // 先检查设备支持
  const isSupported = await checkScanSupport();
  if (!isSupported) {
    // 降级方案1：提示用户使用其他设备
    AlertDialog.show({
      message: '当前设备不支持扫码功能，请使用其他设备'
    });
    return;
  }

  try {
    const result = await scanBarcode.startScanForResult(
      this.getUIContext().getHostContext(),
      { scanTypes: [scanCore.ScanType.ALL] }
    );
    this.handleScanResult(result);
  } catch (error) {
    const err = error as BusinessError;
    if (err.code === 1000500002) {
      // 用户取消，友好提示
      Toast.showToast({ message: '已取消扫码' });
    } else {
      // 其他错误，提示重试
      AlertDialog.show({
        message: '扫码失败，请重试',
        primaryButton: { value: '重试', action: () => this.startScanWithFallback() }
      });
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 参数类型不正确；2. 参数校验失败 | 检查scanTypes参数是否为有效的ScanType枚举数组；检查enableMultiMode和enableAlbum是否为布尔值；检查context是否为有效对象 |
| 1000500001 | 内部错误 | 检查系统日志排查问题；重启应用后重试；检查设备扫码功能是否正常 |
| 1000500002 | 用户取消扫码 | 此为正常操作，无需特殊处理；可友好提示用户已取消操作 |

## 编译和修复问题

### 依赖声明
```json
{
  "name": "scankit-demo",
  "version": "1.0.0",
  "dependencies": {
    "@kit.ScanKit": "^4.1.0",
    "@kit.PerformanceAnalysisKit": "^4.1.0",
    "@kit.BasicServicesKit": "^4.1.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：4.0.0(10)及以上（推荐4.1.0(11)及以上）
- DevEco Studio：3.1及以上
- 模型约束：仅支持Stage模型
- 设备要求：带相机的设备（Wearable需带后置相机，API 6.1.0(23)及以上）

### 常见编译问题

**问题1：模块导入失败**
```
Error: Cannot find module '@kit.ScanKit' or its corresponding type declarations.
```
**解决方法**：
- 检查HarmonyOS SDK版本是否为4.0.0(10)及以上
- 在module.json5中添加依赖声明
- 同步项目依赖

**问题2：Context获取失败**
```
Error: Cannot read property 'getHostContext' of undefined
```
**解决方法**：
- 确保在UI组件的生命周期内调用
- 使用`this.getUIContext().getHostContext()`而非直接使用getContext
- 检查组件是否已正确初始化

**问题3：API版本不匹配**
```
Error: Property 'isDefaultScanSupported' does not exist on type 'typeof scanCore'.
```
**解决方法**：
- 检查API版本，isDefaultScanSupported从API 26.0.0开始支持
- 使用版本判断逻辑包装新API调用
- 为低版本设备提供降级方案

## 常见问题与解决方法

### Q1：扫码界面标题如何动态显示？
**原因**：从6.1.0(23)版本开始，扫码界面标题支持根据scanTypes动态显示
**解决方法**：
- 设置scanTypes为QR_CODE类型：标题显示"扫描二维码"
- 设置scanTypes为条形码类型：标题显示"扫描条形码"
- 设置scanTypes为ALL或同时包含二维码和条形码：标题显示"扫描二维码/条形码"
- 不设置scanTypes：标题显示"扫描二维码/条形码"

### Q2：如何在Wearable设备上使用默认界面扫码？
**原因**：从6.1.0(23)版本开始支持Wearable设备
**解决方法**：
- 确保设备API版本为6.1.0(23)及以上
- 使用cameraManager.getSupportedCameras接口检查是否有后置相机
- 调用scanCore.isDefaultScanSupported检查设备支持情况

### Q3：相册扫码功能如何使用？
**原因**：相册扫码功能通过enableAlbum参数控制
**解决方法**：
- 设置enableAlbum为true开启相册入口
- 用户可在扫码界面点击相册图标选择图片
- 注意：相册扫码仅支持单码识别

### Q4：如何处理多码识别？
**原因**：多码识别功能通过enableMultiMode参数控制
**解决方法**：
- 设置enableMultiMode为true开启多码识别
- 扫码界面会识别视野内的多个码
- 用户需点击选择其中一个码图获取扫码结果

### Q5：如何在模拟器上测试扫码功能？
**原因**：从6.0.0(20)版本开始模拟器支持默认界面扫码
**解决方法**：
- 使用DevEco Studio 3.1及以上版本
- 创建API 6.0.0(20)及以上的模拟器
- 注意模拟器相机流存在镜像问题和固定分辨率黑边

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "scanResult": {
    "scanType": "QR_CODE",
    "originalValue": "扫码内容字符串",
    "scanCodeRect": {
      "left": 100,
      "top": 200,
      "right": 300,
      "bottom": 400
    },
    "isGS1": false,
    "source": "CAMERA"
  },
  "apiUsed": [
    "scanBarcode.startScanForResult",
    "scanCore.ScanType"
  ],
  "deviceSupport": true,
  "scanMode": "camera"
}
```

## 参考文档

- [默认界面扫码开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/scan-scanbarcode)
- [scanBarcode API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scanbarcode-api)
- [scanCore API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-scancore)
- [扫码错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/scan-error-code)

## 完整示例代码

- [ArkTS示例 - Promise方式](assets/scan_promise_example.ets)
- [ArkTS示例 - Callback方式](assets/scan_callback_example.ets)
- [完整工程示例](https://gitcode.com/HarmonyOS_Samples/scankit-samplecode-clientdemo-arkts)

## 测试用例

### 正向测试用例
- [测试单码识别 - 二维码](tests/test_single_qr_code.py)：扫描单个QR Code码
- [测试单码识别 - 条形码](tests/test_single_barcode.py)：扫描单个条形码
- [测试多码识别](tests/test_multi_code.py)：同时扫描多个码
- [测试相册扫码](tests/test_album_scan.py)：从相册选择图片扫码

### 边界测试用例
- [测试所有码类型](tests/test_all_code_types.py)：测试ScanType.ALL参数
- [测试指定码类型](tests/test_specific_code_types.py)：测试QR_CODE、ONE_D_CODE等
- [测试取消扫码](tests/test_cancel_scan.py)：用户点击返回取消扫码

### 异常测试用例
- [测试参数错误](tests/test_invalid_params.py)：传入无效参数类型
- [测试设备不支持](tests/test_unsupported_device.py)：在不支持扫码的设备上调用
- [测试重复调用](tests/test_duplicate_call.py)：连续多次调用扫码接口