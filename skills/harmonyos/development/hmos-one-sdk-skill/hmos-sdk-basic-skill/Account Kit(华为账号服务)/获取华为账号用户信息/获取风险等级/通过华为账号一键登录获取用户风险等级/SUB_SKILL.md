---
name: hmos-account-kit-get-risklevel-by-quicklogin
description: 通过华为账号一键登录获取用户风险等级，支持Phone/Tablet/PC/2in1/TV/Car设备，从5.1.1(19)版本支持TV，从26.0.0版本支持Car，适用于应用登录风控、恶意账号拦截场景
---

# 通过华为账号一键登录获取用户风险等级技能

## 功能描述

本技能实现通过华为账号一键登录功能获取用户风险等级，用于应用登录风控场景。通过在LoginWithHuaweiIDButton组件参数中设置riskLevel标识，在一键登录成功后获取Authorization Code，应用服务端使用该Authorization Code获取Access Token后调用获取用户风险等级接口，获取华为账号用户的风险等级（0-4级）和风险标签，帮助应用对恶意账号进行风控，提升应用安全等级。

## 使用场景

### 触发词
- "一键登录获取风险等级"
- "华为账号风险等级"
- "登录风控"
- "获取用户风险等级"
- "账号风控"
- "恶意账号拦截"

### 能做
- 通过华为账号一键登录获取用户风险等级
- 获取用户风险等级（0:未发现显著风险、1:低风险、2:中风险、3:高风险、4:风险未知）
- 获取用户风险标签（垃圾邮箱、卡商手机号、风险设备、IP聚集、设备聚集、批量操作、非法登录、薅羊毛等）
- 基于风险等级进行登录风控决策
- 基于风险等级进行二次验证或拦截

### 绝不做
- 不支持非一键登录方式获取风险等级
- 不支持用户非首次登录场景（非首次登录请使用华为账号其他方式登录获取用户风险等级）
- 不支持未申请riskLevel scope权限的应用
- 不支持未完成一键登录开发前提的应用

### 补充
- 仅支持Phone、Tablet、PC/2in1设备，TV设备支持从5.1.1(19)版本开始，Car设备支持从26.0.0版本开始
- 需要完成riskLevel scope权限申请，审批未完成或未通过将报错1001502014
- Authorization Code有效期为5分钟，只能使用一次
- Access Token有效期为60分钟，Refresh Token有效期为180天

## 调用规范和规则

### 输入约束
- 应用必须已完成一键登录开发前提工作
- 应用必须已申请riskLevel scope权限并通过审批
- 用户必须首次通过华为账号登录该应用
- 用户必须已登录华为账号系统账号
- 必须获取到华为账号绑定的匿名手机号

### 执行约束
- 最大耗时：客户端一键登录耗时不超过30秒，服务端API调用耗时不超过10秒
- Authorization Code有效期：5分钟，只能使用一次
- Access Token有效期：60分钟
- Refresh Token有效期：180天
- API调用频次：遵循华为账号服务API调用频率限制

### 内容约束
- 禁止未申请权限直接调用获取风险等级接口
- 禁止使用过期的Authorization Code
- 禁止使用过期的Access Token
- 禁止在用户非首次登录场景使用此技能
- 禁止硬编码Client ID、Client Secret等敏感信息

### 降级约束
- scope权限未申请或未通过：提示用户使用其他登录方式
- Authorization Code过期或失效：引导用户重新授权
- Access Token过期：使用Refresh Token刷新，若Refresh Token也过期则重新授权
- 网络失败：提示用户检查网络并重试
- API调用失败：记录错误日志，提示用户稍后重试或使用其他登录方式

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查应用是否已完成一键登录开发前提工作
2. 检查应用是否已申请riskLevel scope权限并通过审批
3. 检查用户是否首次通过华为账号登录该应用
4. 检查系统账号是否已登录华为账号
5. 检查是否已获取到华为账号绑定的匿名手机号

**参数准备**：
```typescript
// ArkTS客户端参数准备
import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';

// LoginWithHuaweiIDButton组件参数
const loginParams: loginComponentManager.LoginWithHuaweiIDButtonParams = {
  style: loginComponentManager.Style.BUTTON_RED,
  borderRadius: 24,
  loginType: loginComponentManager.LoginType.QUICK_LOGIN,
  supportDarkMode: true,
  verifyPhoneNumber: true,
  riskLevel: true  // 关键参数：标识应用期望在登录后获取华为账号的风险等级
};
```

### 步骤2：客户端一键登录

**示例代码**：
```typescript
import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct QuickLoginWithRiskLevel {
  logTag: string = 'QuickLoginWithRiskLevel';
  domainId: number = 0x0000;
  
  // 获取到的匿名手机号
  @State anonymousPhone: string = '139******99';
  
  // 构造LoginWithHuaweiIDButton控制器
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED)
      .onClickLoginWithHuaweiIDButton((error: BusinessError, response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          this.handleError(error);
          return;
        }
        if (response) {
          // 获取Authorization Code，传给应用服务端
          const authorizationCode = response.authorizationCode;
          const openID = response.openID;
          const unionID = response.unionID;
          
          hilog.info(this.domainId, this.logTag, 'Authorization Code获取成功');
          
          // 将Authorization Code传给应用服务端，用于获取用户风险等级
          this.sendCodeToServer(authorizationCode);
        }
      });

  // 错误处理
  handleError(error: BusinessError): void {
    hilog.error(this.domainId, this.logTag, `登录失败: ${error.code}, ${error.message}`);
    
    switch (error.code) {
      case 1001502001:
        // 用户未登录华为账号，请登录华为账号并重试
        break;
      case 1001502005:
        // 网络异常，请检查当前网络状态并重试
        break;
      case 1001502009:
        // 内部错误，请尝试使用其他方式登录
        break;
      case 1001502012:
        // 用户取消授权
        break;
      case 12300001:
        // 系统服务异常，请稍后重试
        break;
      case 1001502014:
        // 应用未申请scopes或permissions权限
        break;
      case 1005300001:
        // 用户未同意协议
        break;
      default:
        // 其他错误，请尝试使用其他方式登录
        break;
    }
  }

  // 发送Authorization Code到服务端
  async sendCodeToServer(authorizationCode: string): void {
    // 实现发送Authorization Code到应用服务端的逻辑
    // 服务端将使用Authorization Code获取Access Token和用户风险等级
  }

  build() {
    Column() {
      LoginWithHuaweiIDButton({
        params: {
          style: loginComponentManager.Style.BUTTON_RED,
          borderRadius: 24,
          loginType: loginComponentManager.LoginType.QUICK_LOGIN,
          supportDarkMode: true,
          verifyPhoneNumber: true,
          riskLevel: true  // 设置riskLevel为true
        },
        controller: this.controller
      })
    }
  }
}
```

### 步骤3：服务端获取Access Token

**示例代码（Java）**：
```java
import com.alibaba.fastjson2.JSONObject;
import org.apache.http.NameValuePair;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.message.BasicNameValuePair;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/**
 * 使用Authorization Code获取Access Token
 */
public class GetUserToken {
    // 获取用户级凭证接口URL
    private static final String TOKEN_URL = "https://oauth-login.cloud.huawei.com/oauth2/v3/token";
    
    public static JSONObject getAccessToken(String authorizationCode, String clientId, String clientSecret) throws IOException {
        HttpPost httpPost = new HttpPost(TOKEN_URL);
        
        // 构建请求参数
        List<NameValuePair> requestParams = new ArrayList<>();
        requestParams.add(new BasicNameValuePair("grant_type", "authorization_code"));
        requestParams.add(new BasicNameValuePair("code", authorizationCode));
        requestParams.add(new BasicNameValuePair("client_id", clientId));
        requestParams.add(new BasicNameValuePair("client_secret", clientSecret));
        
        httpPost.setHeader("Content-Type", "application/x-www-form-urlencoded");
        httpPost.setEntity(new UrlEncodedFormEntity(requestParams));
        
        // 执行HTTP请求
        JSONObject response = CallUtils.toJsonObject(CallUtils.remoteCallOAuth(httpPost));
        
        // 解析响应
        String accessToken = response.getString("access_token");
        String refreshToken = response.getString("refresh_token");
        Integer expiresIn = response.getInteger("expires_in");
        
        return response;
    }
}
```

### 步骤4：服务端获取用户风险等级

**示例代码（Java）**：
```java
import com.alibaba.fastjson2.JSONArray;
import com.alibaba.fastjson2.JSONObject;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpPost;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

/**
 * 获取用户风险等级
 */
public class GetUserRiskLevel {
    // 获取用户风险等级接口URL
    private static final String RISK_LEVEL_URL = "https://account.cloud.huawei.com/user/getuserrisklevel";
    
    public static JSONObject getUserRiskLevel(String accessToken, String clientId, String transactionID, String scene) throws IOException {
        // 构建请求URL（带Query参数）
        String urlWithParams = RISK_LEVEL_URL + "?clientID=" + clientId + "&transactionID=" + transactionID;
        
        HttpPost httpPost = new HttpPost(urlWithParams);
        
        // 构建请求Body
        Map<String, String> requestBody = new HashMap<>();
        requestBody.put("accessToken", accessToken);
        requestBody.put("scene", scene);  // registration 或 marketing
        
        httpPost.setHeader("Content-Type", "application/json;charset=utf-8");
        httpPost.setEntity(CallUtils.wrapJsonEntity(requestBody));
        
        // 执行HTTP请求并处理响应
        JSONObject response = CallUtils.toJsonObject(CallUtils.remoteCall(httpPost, (CloseableHttpResponse httpResponse, String rawBody) -> {
            int statusCode = httpResponse.getStatusLine().getStatusCode();
            
            if (statusCode != 200) {
                return new IOException("HTTP请求失败: " + statusCode + ", " + rawBody);
            }
            
            JSONObject responseBody = CallUtils.toJsonObject(rawBody);
            Integer errCode = responseBody.getInteger("errCode");
            
            if (Objects.nonNull(errCode) && errCode != 0) {
                return new IOException("业务错误: " + statusCode + ", " + rawBody);
            }
            
            return null;
        }));
        
        // 解析风险等级和风险标签
        Integer errCode = response.getInteger("errCode");
        String errMsg = response.getString("errMsg");
        Integer riskLevel = response.getInteger("riskLevel");
        JSONArray riskTag = response.getJSONArray("riskTag");
        
        return response;
    }
    
    /**
     * 处理风险等级结果
     */
    public static void handleRiskLevel(Integer riskLevel, JSONArray riskTag) {
        switch (riskLevel) {
            case 0:
                // 未发现显著风险，建议放通
                System.out.println("风险等级: 0 - 未发现显著风险");
                break;
            case 1:
                // 低风险，建议简单验证（验证码、短信）或人工审核
                System.out.println("风险等级: 1 - 低风险");
                break;
            case 2:
                // 中风险，建议采取一定措施（二次验证、降低奖励概率等）
                System.out.println("风险等级: 2 - 中风险");
                break;
            case 3:
                // 高风险，建议业务逻辑直接拦截
                System.out.println("风险等级: 3 - 高风险");
                break;
            case 4:
                // 风险未知，建议结合账号历史行为决策
                System.out.println("风险等级: 4 - 风险未知");
                break;
            default:
                System.out.println("未知风险等级");
                break;
        }
        
        // 处理风险标签
        if (riskTag != null && riskTag.size() > 0) {
            System.out.println("风险标签: " + riskTag.toJSONString());
            for (int i = 0; i < riskTag.size(); i++) {
                String tag = riskTag.getString(i);
                // 根据风险标签进行特定处理
                switch (tag) {
                    case "spamMailbox":
                        // 绑定垃圾邮箱
                        break;
                    case "riskPhoneNumber":
                        // 绑定卡商手机号
                        break;
                    case "riskDevice":
                        // 使用风险设备
                        break;
                    case "ipCluster":
                        // IP聚集
                        break;
                    case "deviceCluster":
                        // 设备聚集
                        break;
                    case "batchBehavior":
                        // 批量操作
                        break;
                    case "illegalLogin":
                        // 非法登录
                        break;
                    case "activityFraud":
                        // 恶意行为-薅羊毛
                        break;
                    default:
                        break;
                }
            }
        }
    }
}
```

### 步骤5：错误处理和降级处理

**错误处理代码**：
```java
/**
 * 错误处理和降级处理
 */
public class ErrorHandler {
    /**
     * 处理获取用户风险等级接口错误
     */
    public static void handleRiskLevelError(Integer errCode, String errMsg) {
        switch (errCode) {
            case 6:
                // 会话失效，access_token无效或已过期
                // 建议：使用Refresh Token刷新Access Token，或重新授权
                System.out.println("错误: 会话失效 - " + errMsg);
                break;
            case 403:
                // 无权访问，未申请riskLevel scope权限
                // 建议：前往AGC申请权限
                System.out.println("错误: 无权访问 - " + errMsg);
                break;
            case 503:
                // 触发系统流控
                // 建议：稍后重试
                System.out.println("错误: 系统流控 - " + errMsg);
                break;
            case 70001201:
                // 请求参数错误
                // 建议：检查请求参数
                System.out.println("错误: 参数错误 - " + errMsg);
                break;
            case 70001402:
                // 系统鉴权错误
                // 建议：稍后重试或提交问题
                System.out.println("错误: 鉴权错误 - " + errMsg);
                break;
            case 70020002:
                // 接口内部超时
                // 建议：稍后重试
                System.out.println("错误: 接口超时 - " + errMsg);
                break;
            case 70001401:
                // 接口内部错误
                // 建议：根据错误描述处理或提交问题
                System.out.println("错误: 内部错误 - " + errMsg);
                break;
            default:
                System.out.println("未知错误: " + errCode + " - " + errMsg);
                break;
        }
    }
    
    /**
     * 降级处理：Access Token过期时使用Refresh Token刷新
     */
    public static JSONObject refreshToken(String refreshToken, String clientId, String clientSecret) throws IOException {
        String url = "https://oauth-login.cloud.huawei.com/oauth2/v3/token";
        
        HttpPost httpPost = new HttpPost(url);
        List<NameValuePair> requestParams = new ArrayList<>();
        requestParams.add(new BasicNameValuePair("grant_type", "refresh_token"));
        requestParams.add(new BasicNameValuePair("refresh_token", refreshToken));
        requestParams.add(new BasicNameValuePair("client_id", clientId));
        requestParams.add(new BasicNameValuePair("client_secret", clientSecret));
        
        httpPost.setHeader("Content-Type", "application/x-www-form-urlencoded");
        httpPost.setEntity(new UrlEncodedFormEntity(requestParams));
        
        return CallUtils.toJsonObject(CallUtils.remoteCallOAuth(httpPost));
    }
}
```

## 错误码说明

### 客户端错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1001502001 | 用户未登录华为账号 | 提示用户登录华为账号并重试 |
| 1001502005 | 网络错误 | 提示用户检查网络状态并重试 |
| 1001502009 | 内部错误 | 提示用户尝试使用其他方式登录 |
| 1001502012 | 用户取消授权 | 提示用户授权后重试 |
| 1001502014 | 应用未申请scopes或permissions权限 | 完成riskLevel scope权限申请 |
| 12300001 | 系统服务异常 | 提示用户稍后重试 |
| 1005300001 | 用户未同意协议 | 提示用户同意协议后重试 |

### 服务端错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 6 | 会话失效，access_token无效或已过期 | 使用Refresh Token刷新或重新授权 |
| 403 | 无权访问 | 前往AGC申请riskLevel scope权限 |
| 503 | 触发系统流控 | 稍后重试 |
| 70001201 | 请求参数错误 | 检查请求参数格式 |
| 70001402 | 系统鉴权错误 | 稍后重试或提交问题 |
| 70020002 | 接口内部超时 | 稍后重试 |
| 70001401 | 接口内部错误 | 根据错误描述处理或提交问题 |

### HTTP错误码

| HTTP响应码 | 说明 | 解决方法 |
|-------|------|---------|
| 200 | 接口调用成功 | 检查Response Body中的errCode判断业务结果 |
| 400 | 参数错误 | 检查请求参数是否符合规范 |
| 403 | 无权限访问 | 检查网络环境配置和权限申请 |
| 404 | 找不到服务 | 检查请求URI是否正确 |
| 405 | 不支持的http请求method | 检查http请求method |
| 415 | 不支持的媒体类型 | 检查contentType是否正确 |
| 500 | 服务内部错误 | 提交问题反馈 |
| 502 | 请求连接异常 | 稍后重试 |
| 504 | 请求连接超时 | 稍后重试 |

## 编译和修复问题

### 依赖声明

**ArkTS客户端依赖**：
```json
{
  "dependencies": {
    "@kit.AccountKit": ">=4.1.0",
    "@kit.BasicServicesKit": ">=4.1.0",
    "@kit.PerformanceAnalysisKit": ">=4.1.0"
  }
}
```

**Java服务端依赖**：
```xml
<dependencies>
    <dependency>
        <groupId>com.alibaba.fastjson2</groupId>
        <artifactId>fastjson2</artifactId>
        <version>2.x.x</version>
    </dependency>
    <dependency>
        <groupId>org.apache.httpcomponents</groupId>
        <artifactId>httpclient</artifactId>
        <version>4.5.x</version>
    </dependency>
</dependencies>
```

### 环境要求
- HarmonyOS版本：>=4.1.0(11)，TV设备支持从5.1.1(19)开始，Car设备支持从26.0.0开始
- 设备类型：Phone、Tablet、PC/2in1、TV（5.1.1+）、Car（26.0.0+）
- Stage模型：仅支持Stage模型
- TLS协议：必须使用TLS1.2协议及规定内加密套件

### 常见编译问题

**问题1：未导入AccountKit模块**
```
Error: Cannot find name 'LoginWithHuaweiIDButton'
```
**解决方法**：
```typescript
import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
```

**问题2：riskLevel参数类型错误**
```
Error: Type 'string' is not assignable to type 'boolean'
```
**解决方法**：确保riskLevel参数为boolean类型，值为true或false

**问题3：缺少BusinessError导入**
```
Error: Cannot find name 'BusinessError'
```
**解决方法**：
```typescript
import { BusinessError } from '@kit.BasicServicesKit';
```

## 常见问题与解决方法

### Q1：如何申请riskLevel scope权限？
**原因**：获取用户风险等级功能需要申请专门的scope权限
**解决方法**：
- 发送邮件至accountkit@huawei.com申请
- 邮件主题：【获取风险等级】权限申请
- 邮件正文提供：企业名称、应用名称、应用包名、APP ID、Client ID、背景介绍、使用场景、必要性说明
- 等待1-2个工作日审批结果

### Q2：调用获取风险等级接口返回errCode=403？
**原因**：应用未申请riskLevel scope权限或获取Authorization Code时未携带riskLevel scope
**解决方法**：
- 检查是否已完成riskLevel scope权限申请并通过审批
- 确保在LoginWithHuaweiIDButton参数中设置riskLevel: true
- 确保获取Authorization Code时包含riskLevel scope

### Q3：Access Token过期如何处理？
**原因**：Access Token有效期为60分钟
**解决方法**：
- 使用Refresh Token调用刷新用户级凭证接口获取新的Access Token
- 若Refresh Token也过期（180天），引导用户重新授权

### Q4：Authorization Code过期如何处理？
**原因**：Authorization Code有效期为5分钟，只能使用一次
**解决方法**：
- 在获取Authorization Code后立即传给服务端使用
- 若已过期，引导用户重新授权获取新的Authorization Code

### Q5：用户非首次登录如何获取风险等级？
**原因**：此技能仅适用于用户首次登录场景
**解决方法**：使用华为账号其他方式登录获取用户风险等级技能

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "riskLevel": 2,
  "riskTag": ["spamMailbox", "ipCluster"],
  "authorizationCode": "xxx",
  "accessToken": "xxx",
  "refreshToken": "xxx",
  "expiresIn": 3600,
  "openID": "xxx",
  "unionID": "xxx",
  "apiUsed": [
    "LoginWithHuaweiIDButton",
    "LoginWithHuaweiIDButtonParams",
    "HuaweiIDCredential",
    "获取用户级凭证接口",
    "获取用户风险等级接口"
  ],
  "riskLevelDescription": "中风险：发现风险因素，结合总体评分后风险中等",
  "suggestion": "建议根据业务场景采取一定措施规避伤害，如二次验证、降低奖励概率等"
}
```

## 参考文档

- [API开发指南](references/account-get-risklevel-byquicklogin.md)
- [LoginWithHuaweiIDButton组件](references/account-api-huawei-id-button.md)
- [loginComponentManager组件管理](references/account-api-component-manager.md)
- [获取用户风险等级接口](references/account-api-getuserrisklevel.md)
- [获取用户级凭证接口](references/account-api-obtain-user-token.md)

## 完整示例代码

- [ArkTS客户端示例](assets/quicklogin_with_risklevel.ets)
- [Java服务端示例](assets/get_user_risklevel.java)
- [错误处理示例](assets/error_handler.java)
- [降级处理示例](assets/token_refresh.java)

## 测试用例

### 正向测试用例
- [首次登录获取风险等级](tests/test_first_login_risklevel.py)：用户首次登录成功获取风险等级
- [低风险用户登录](tests/test_low_risk_login.py)：风险等级为1的用户登录流程
- [高风险用户拦截](tests/test_high_risk_intercept.py)：风险等级为3的用户拦截流程

### 边界测试用例
- [Authorization Code过期处理](tests/test_code_expired.py)：测试Authorization Code过期时的处理
- [Access Token过期处理](tests/test_token_expired.py)：测试Access Token过期时的刷新流程
- [Refresh Token过期处理](tests/test_refresh_token_expired.py)：测试Refresh Token过期时重新授权

### 异常测试用例
- [未申请权限错误](tests/test_no_permission.py)：测试未申请riskLevel scope权限时的错误处理
- [网络异常处理](tests/test_network_error.py)：测试网络异常时的降级处理
- [用户取消授权](tests/test_user_cancel.py)：测试用户取消授权时的处理
- [参数错误处理](tests/test_param_error.py)：测试请求参数错误时的处理