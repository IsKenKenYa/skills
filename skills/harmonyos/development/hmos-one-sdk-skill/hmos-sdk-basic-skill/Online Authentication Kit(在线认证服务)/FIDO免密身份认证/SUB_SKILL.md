---
name: hmos-online-authentication-kit-fido
description: 实现FIDO免密身份认证的开通、使用和关闭功能，支持指纹/人脸生物特征认证，需设备支持ATL4级别认证可信等级且联网，适用于免密登录、免密支付等业务场景
---

# FIDO免密身份认证技能

## 功能描述

本技能提供HarmonyOS系统的FIDO UAF本地免密认证能力，通过生物特征代替密码实现身份认证。支持三大核心功能：

1. **开通FIDO免密身份认证**：使用用户已有的生物特征开通FIDO免密身份认证能力
2. **使用FIDO免密身份认证**：使用用户已开通的生物特征进行FIDO免密身份认证
3. **关闭FIDO免密身份认证**：使用用户已开通的生物特征注销FIDO免密身份认证能力

基于FIDO UAF（Universal Authentication Framework）协议，通过生物识别和加密技术为用户提供无密码的身份认证体验。支持指纹识别和3D人脸识别，认证可信等级达到ATL4级别。

## 使用场景

### 触发词
- "FIDO认证"
- "免密登录"
- "生物特征认证"
- "开通FIDO"
- "使用FIDO"
- "关闭FIDO"
- "指纹认证"
- "人脸认证"
- "Online Authentication Kit FIDO"

### 能做
- 实现FIDO免密身份认证的完整流程（开通、使用、关闭）
- 查询设备认证能力和支持的认证器
- 检查用户策略的开启状态
- 处理UAF协议消息进行注册、认证、注销操作
- 通知FIDO认证器认证结果
- 支持自定义认证方式切换
- 引导用户设置生物特征（当未设置时）

### 绝不做
- 不处理非FIDO协议的认证方式
- 不替代FIDO服务端功能（需业务方自行部署FIDO服务器）
- 不处理超出生物特征认证范围的请求
- 不在设备不支持ATL4级别认证时强制执行
- 不绕过权限检查（必须获取ohos.permission.ACCESS_BIOMETRIC权限）

### 补充
- 必须部署FIDO服务器并正确配置facet id
- 设备需支持指纹/3D人脸识别且达到ATL4级别认证可信等级
- 需联网才能使用FIDO在线身份校验服务
- 需向用户明示个人信息处理并取得同意
- 支持Phone、PC/2in1、Tablet设备类型
- API起始版本：4.1.0(11)，元服务支持：5.0.0(12)

## 调用规范和规则

### 输入约束
- **报文格式**：必须符合FIDO UAF协议规范，JSON字符串格式
- **报文长度**：含challenge、transaction等字段的TA请求报文不可超过2048字节
- **生物特征**：用户必须已设置生物特征（指纹或3D人脸）
- **权限要求**：必须获取ohos.permission.ACCESS_BIOMETRIC权限
- **设备要求**：设备必须支持生物特征且达到ATL4认证可信等级

### 执行约束
- **最大耗时**：单次认证操作建议不超过30秒
- **最大迭代次数**：认证失败最多重试3次
- **API调用频次**：遵循FIDO服务端限制策略
- **网络要求**：必须联网访问FIDO服务端
- **facet id匹配**：客户端计算的facet id必须与服务端配置一致

### 内容约束
- **禁止生成**：虚假的FIDO报文、不符合UAF协议的数据
- **禁止使用高危函数**：禁止使用eval、exec等高危函数处理报文
- **禁止操作**：禁止绕过生物特征认证、禁止伪造认证结果
- **报文验证**：必须验证报文格式和数据的合法性

### 降级约束
- **设备不支持**：提示用户设备不支持FIDO认证，建议使用其他认证方式
- **网络失败**：提示网络异常，建议稍后重试
- **用户取消**：允许用户重新发起认证
- **未设置生物特征**：引导用户去设置生物特征（使用系统跳转能力）
- **认证失败**：提供自定义认证方式切换功能（需传入navigationButtonText）

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查设备是否支持生物特征（指纹/3D人脸）
2. 查询设备是否支持ATL4级别的认证可信等级
3. 检查用户是否已设置生物特征信息
4. 验证是否已获取ohos.permission.ACCESS_BIOMETRIC权限
5. 验证FIDO服务端是否已部署且配置正确

**权限配置**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.ACCESS_BIOMETRIC",
        "reason": "用于FIDO免密身份认证",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

**设备能力检查**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
import { userAuth } from '@kit.UserAuthenticationKit';

try {
  // 查询设备人脸识别是否支持ATL4级别的认证可信等级
  userAuth.getAvailableStatus(userAuth.UserAuthType.FACE, userAuth.AuthTrustLevel.ATL4);
  console.info('current auth trust level is supported');
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`current auth trust level is not supported. Code is ${err?.code}, message is ${err?.message}`);
}
```

### 步骤2：开通FIDO免密身份认证

**完整流程代码**：
```typescript
import { fido } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { UIContext } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct FidoRegisterPage {
  private uiContext = this.getUIContext().getHostContext();
  
  async registerFido(regMessage: string): Promise<void> {
    try {
      // 1. 初始化认证器信息
      let discoverData = await fido.discover(this.uiContext);
      console.info('Succeeded in discover:', JSON.stringify(discoverData));
      
      // 2. 检查是否已开通FIDO认证
      let uafAuthMessage: fido.UAFMessage = {
        uafProtocolMessage: regMessage, // 从服务端获取的策略检查报文
        additionalData: ''
      };
      
      let isRegistered: boolean = true;
      try {
        await fido.checkPolicy(this.uiContext, uafAuthMessage);
        console.info('has registered, no need to register again.');
        return;
      } catch (error) {
        isRegistered = false;
        const err: BusinessError = error as BusinessError;
        console.error(`checkPolicy failed. Code: ${err.code}, Message: ${err.message}`);
      }
      
      // 3. 执行FIDO注册
      let uafRegMessage: fido.UAFMessage = {
        uafProtocolMessage: regMessage, // 从服务端获取的注册报文
        additionalData: ''
      };
      
      let channelBinding: fido.ChannelBinding = {};
      let messageResp = await fido.processUAFOperation(this.uiContext, uafRegMessage, channelBinding);
      console.info('processUAFOperation response:', JSON.stringify(messageResp));
      
      // 4. 通知注册结果
      let notifyMessage: fido.UAFMessage = {
        uafProtocolMessage: messageResp.uafProtocolMessage, // 从服务端获取的注册结果报文
        additionalData: ''
      };
      
      await fido.notifyUAFResult(this.uiContext, notifyMessage);
      console.info('Succeeded in notifyUAFResult.');
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to register FIDO. Code: ${err.code}, message: ${err.message}`);
      throw error;
    }
  }
  
  build() {
    Column() {
      Button('开通FIDO认证')
        .onClick(() => {
          // 从FIDO服务端获取注册报文
          this.registerFido('reg_message_from_server');
        });
    }
  }
}
```

### 步骤3：使用FIDO免密身份认证

**认证流程代码**：
```typescript
async authenticateFido(authMessage: string): Promise<fido.UAFMessage> {
  try {
    // 1. 初始化认证器信息
    let discoverData = await fido.discover(this.uiContext);
    console.info('Succeeded in discover:', JSON.stringify(discoverData));
    
    // 2. 检查是否已开通FIDO认证
    let uafAuthMessage: fido.UAFMessage = {
      uafProtocolMessage: authMessage, // 从服务端获取的策略检查报文
      additionalData: ''
    };
    
    await fido.checkPolicy(this.uiContext, uafAuthMessage);
    console.info('checkPolicy succeeded, user has registered.');
    
    // 3. 执行FIDO认证
    let uafRegMessage: fido.UAFMessage = {
      uafProtocolMessage: authMessage, // 从服务端获取的认证报文
      additionalData: '{"navigationButtonText": "使用其他方式验证"}' // 支持自定义认证方式
    };
    
    let channelBinding: fido.ChannelBinding = {};
    let messageResp = await fido.processUAFOperation(this.uiContext, uafRegMessage, channelBinding);
    console.info('processUAFOperation response:', JSON.stringify(messageResp));
    
    // 4. 发送认证响应报文至FIDO服务端进行验证
    return messageResp;
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to authenticate FIDO. Code: ${err.code}, message: ${err.message}`);
    
    // 处理自定义认证方式切换
    if (err.code === 1005900017) {
      console.info('User switched to custom authentication process.');
      // 拉起自定义认证界面
    }
    
    throw error;
  }
}
```

### 步骤4：关闭FIDO免密身份认证

**注销流程代码**：
```typescript
async deregisterFido(deregMessage: string): Promise<void> {
  try {
    // 1. 初始化认证器信息
    let discoverData = await fido.discover(this.uiContext);
    console.info('Succeeded in discover:', JSON.stringify(discoverData));
    
    // 2. 执行FIDO注销
    let uafRegMessage: fido.UAFMessage = {
      uafProtocolMessage: deregMessage, // 从服务端获取的注销报文
      additionalData: ''
    };
    
    let channelBinding: fido.ChannelBinding = {};
    let messageResp = await fido.processUAFOperation(this.uiContext, uafRegMessage, channelBinding);
    console.info('processUAFOperation response:', JSON.stringify(messageResp));
    
    // 3. 发送注销响应报文至FIDO服务端进行验证
    console.info('Succeeded in deregister FIDO.');
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`Failed to deregister FIDO. Code: ${err.code}, message: ${err.message}`);
    throw error;
  }
}
```

### 步骤5：错误处理

**完整错误处理代码**：
```typescript
function handleFidoError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      console.error('参数错误，请检查传入的参数格式');
      break;
    case 801:
      console.error('设备类型错误，不支持当前设备类型');
      break;
    case 1005900003:
      console.error('用户取消操作，可重新发起认证');
      break;
    case 1005900005:
      console.error('没有可用认证器，请检查用户注册状态');
      break;
    case 1005900006:
      console.error('协议错误，请检查报文格式是否正确');
      break;
    case 1005900007:
      console.error('facet id不匹配，请检查服务端配置');
      break;
    case 1005900009:
      console.error('认证器拒绝请求，请重新开启FIDO认证');
      break;
    case 1005900014:
      console.error('用户未录入生物特征信息，请引导用户设置');
      break;
    case 1005900015:
      console.error('系统中断，请重启设备后重试');
      break;
    case 1005900016:
      console.error('未知错误，请重试或重启设备');
      break;
    case 1005900017:
      console.info('切换到自定义认证方式，请拉起自定义认证界面');
      break;
    default:
      console.error(`未知错误码: ${error.code}, 消息: ${error.message}`);
  }
}
```

### 步骤6：降级处理

**降级处理代码**：
```typescript
async function fallbackAuthentication(context: common.Context): Promise<void> {
  try {
    // 尝试使用其他认证方式（如密码认证）
    console.warn('FIDO认证失败，尝试使用备用认证方式');
    // 实现备用认证逻辑
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error('备用认证也失败:', err.message);
    // 提示用户稍后重试或联系客服
  }
}

async function guideUserToSetBiometrics(context: common.Context): Promise<void> {
  try {
    // 使用系统跳转能力引导用户设置生物特征
    let uafMessage: fido.UAFMessage = {
      uafProtocolMessage: '', // 空报文
      additionalData: '{"isGuideToSetBiometrics": true}'
    };
    await fido.processUAFOperation(context, uafMessage);
  } catch (error) {
    console.error('引导设置生物特征失败:', error);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误 | 检查传入参数格式和类型是否正确 |
| 801 | 设备类型错误 | 确认设备类型为Phone、PC/2in1、Tablet |
| 1005900003 | 用户取消操作 | 重新发起认证 |
| 1005900005 | 没有可用认证器 | checkPolicy时重新开启FIDO认证；processUAFOperation时检查用户注册状态 |
| 1005900006 | UAF协议错误 | 检查报文格式和数据是否正确 |
| 1005900007 | facet id不匹配 | 检查服务端facet id配置，格式为ohos:app-id:<签名值> |
| 1005900009 | 认证器拒绝请求 | 关闭当前FIDO认证，重新开启 |
| 1005900014 | 用户未录入生物特征 | 检查设备是否注册生物特征，引导用户设置 |
| 1005900015 | 系统中断 | 重启移动端设备 |
| 1005900016 | 未知错误 | 重试或重启设备后重试 |
| 1005900017 | 切换到自定义认证方式 | 拉起自定义认证界面或重新发起UAF认证 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.OnlineAuthenticationKit": "^4.1.0",
    "@kit.BasicServicesKit": "^4.1.0",
    "@kit.ArkUI": "^4.1.0",
    "@kit.AbilityKit": "^4.1.0"
  }
}
```

### 环境要求
- **HarmonyOS版本**：4.1.0(11)及以上
- **设备类型**：Phone、PC/2in1、Tablet
- **生物特征**：支持指纹识别或3D人脸识别
- **认证可信等级**：支持ATL4级别
- **网络连接**：必须联网访问FIDO服务端

### 常见编译问题

**问题1：权限未配置**
```
Error: Permission ohos.permission.ACCESS_BIOMETRIC is not granted
```
**解决方法**：在module.json5中配置权限声明：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.ACCESS_BIOMETRIC"
      }
    ]
  }
}
```

**问题2：facet id配置错误**
```
Error: No Facet_ID is registered (1005900007)
```
**解决方法**：
1. 通过getBundleInfoForSelf获取应用签名值
2. 拼接facet id：ohos:app-id:<签名值>
3. 配置到FIDO服务端

**问题3：设备不支持ATL4**
```
Error: current auth trust level is not supported
```
**解决方法**：检查设备是否支持ATL4认证可信等级，如果不支持则提示用户使用其他认证方式

**问题4：用户未设置生物特征**
```
Error: The user does not record biometric features (1005900014)
```
**解决方法**：使用isGuideToSetBiometrics参数引导用户设置生物特征

## 常见问题与解决方法

### Q1：如何获取正确的facet id？
**原因**：facet id必须与FIDO服务端配置一致
**解决方法**：
- 调用getBundleInfoForSelf获取appId
- 去除包名前缀和末尾所有"="
- 拼接"ohos:app-id:"前缀
- 配置到FIDO服务端

### Q2：如何处理用户取消认证？
**原因**：用户在生物特征验证时点击关闭
**解决方法**：
- 检查错误码1005900003
- 提示用户重新发起认证
- 提供其他认证方式选项

### Q3：如何实现自定义认证方式切换？
**原因**：用户生物认证失败后希望使用其他方式
**解决方法**：
- 在additionalData中传入navigationButtonText
- 监听错误码1005900017
- 拉起自定义认证界面

### Q4：如何引导用户设置生物特征？
**原因**：用户设备未设置指纹或人脸
**解决方法**：
- 在additionalData中传入{"isGuideToSetBiometrics": true}
- 系统自动跳转到生物特征设置界面

### Q5：如何处理网络异常？
**原因**：FIDO服务需要联网
**解决方法**：
- 检查网络连接状态
- 提示用户检查网络设置
- 提供离线降级方案

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "register|authenticate|deregister",
  "discoverData": {
    "supportedUAFVersions": [{"major": 1, "minor": 0}],
    "clientVendor": "CFCA",
    "availableAuthenticators": [
      {
        "aaid": "001B#1001",
        "title": "指纹认证器",
        "userVerification": 2
      }
    ]
  },
  "uafMessageResponse": {
    "uafProtocolMessage": "...",
    "additionalData": ""
  },
  "apiUsed": [
    "fido.discover",
    "fido.checkPolicy",
    "fido.processUAFOperation",
    "fido.notifyUAFResult"
  ]
}
```

## 参考文档

- [FIDO免密身份认证开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/onlineauthentication-fido)
- [FIDO API参考文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/onlineauthentication-fido-api)
- [FIDO错误码参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/onlineauthentication-error-code-fido)
- [个人数据处理说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/onlineauthentication-personal-data-processing-description)
- [通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)

## 完整示例代码

- [ArkTS完整示例-开通FIDO认证](assets/fido_register_complete.ets)
- [ArkTS完整示例-使用FIDO认证](assets/fido_authenticate_complete.ets)
- [ArkTS完整示例-关闭FIDO认证](assets/fido_deregister_complete.ets)
- [权限配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [开通FIDO认证-指纹认证器](tests/test_fido_register_fingerprint.py)：测试正常开通指纹认证流程
- [使用FIDO认证-指纹认证](tests/test_fido_authenticate_fingerprint.py)：测试正常指纹认证流程
- [关闭FIDO认证-正常注销](tests/test_fido_deregister.py)：测试正常注销流程

### 边界测试用例
- [多次注册检查](tests/test_fido_already_registered.py)：测试已注册用户再次注册的处理
- [设备能力检查](tests/test_fido_device_capability.py)：测试设备不支持ATL4时的处理
- [报文长度限制](tests/test_fido_message_length.py)：测试报文超过2048字节的处理

### 异常测试用例
- [用户取消认证](tests/test_fido_user_cancel.py)：测试用户取消认证的错误处理
- [网络异常](tests/test_fido_network_error.py)：测试网络异常的降级处理
- [facet id不匹配](tests/test_fido_facetid_error.py)：测试facet id配置错误的处理
- [用户未设置生物特征](tests/test_fido_no_biometrics.py)：测试引导用户设置生物特征
- [自定义认证切换](tests/test_fido_custom_auth.py)：测试自定义认证方式切换功能