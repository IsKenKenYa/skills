---
name: hmos-remote-communication-kit-preparations
description: 配置Remote Communication Kit开发环境权限和参数，支持ArkTS/C API开发，包含网络权限、HTTP明文配置，适用于远场通信服务开发场景
---

# Remote Communication Kit开发准备技能

## 功能描述

本技能用于配置Remote Communication Kit(远场通信服务)的开发环境准备工作,包括权限声明、C API环境配置、HTTP明文传输策略配置等必需的开发前置条件。Remote Communication Kit提供HTTP数据请求功能,支持GET、POST、HEAD、PUT、DELETE、PATCH等常见HTTP方法。

**核心能力**:
- 配置必需的网络权限(INTERNET、GET_NETWORK_INFO)
- 配置C API开发环境的CMakeLists.txt
- 配置HTTP明文传输安全策略
- 验证开发环境配置完整性

**适用范围**:
- Remote Communication Kit ArkTS API开发
- Remote Communication Kit C API开发
- HTTP/HTTPS网络请求场景
- 代理、DNS、SSL/TLS配置场景

**限制条件**:
- 需要在module.json5中正确配置权限
- C API需要额外配置CMakeLists.txt
- HTTP明文配置需要遵守安全策略

**典型场景**:
- 应用首次集成Remote Communication Kit
- 配置网络请求权限和环境
- 解决HTTP明文访问限制问题

## 使用场景

### 触发词
- "配置Remote Communication Kit权限" - 配置网络访问权限
- "Remote Communication Kit开发准备" - 完整开发环境配置
- "配置rcp权限" - 配置rcp模块权限
- "HTTP明文配置" - 配置HTTP明文传输策略
- "C API网络配置" - 配置Native层网络开发环境

### 能做
- 配置ohos.permission.INTERNET权限
- 配置ohos.permission.GET_NETWORK_INFO权限
- 配置C API的CMakeLists.txt链接
- 配置network_config.json明文传输策略
- 提供权限配置示例代码
- 提供CMakeLists.txt配置示例
- 提供HTTP明文配置示例

### 绝不做
- 不执行具体的网络请求操作(仅配置开发环境)
- 不替代实际的网络通信代码实现
- 不处理超出开发准备范围的请求
- 不修改运行时权限(仅配置静态权限)

### 补充
- 除取消网络请求、关闭会话外,其余请求都需要权限
- 从API 6.1.0(23)开始支持HTTP明文拦截配置
- 自API 5.1.0(18)起,可创建的session实例数量从16个增加到1024个
- HTTP明文配置需遵守安全规范,建议优先使用HTTPS

## 调用规范和规则

### 输入约束
- 配置文件路径必须符合HarmonyOS项目结构规范
- module.json5路径: entry/src/main/module.json5
- network_config.json路径: src/main/resources/base/profile/network_config.json
- CMakeLists.txt路径: 项目根目录/CMakeLists.txt
- 配置参数必须使用正确的JSON/JSON5语法

### 执行约束
- 最大配置文件大小: 1MB
- 配置验证耗时: ≤5秒
- 权限数量限制: ≤10个权限声明
- 配置文件编码: UTF-8

### 内容约束
- 禁止配置非必需权限
- 禁止使用不安全的HTTP明文配置(全局允许明文传输需谨慎)
- 禁止硬编码敏感信息(证书路径、密钥等)
- 禁止配置已废弃的API版本参数

### 降级约束
- 配置文件不存在: 提供创建模板并指导用户创建
- 权限配置错误: 提示错误信息并给出正确配置示例
- C API环境缺失: 提示配置CMakeLists.txt步骤
- HTTP明文配置冲突: 提示安全风险并建议使用HTTPS

## 调用流程和步骤

### 步骤1: 权限配置准备阶段

**前置校验**:
1. 检查entry/src/main/module.json5文件是否存在
2. 检查是否已配置ohos.permission.INTERNET权限
3. 检查是否已配置ohos.permission.GET_NETWORK_INFO权限
4. 验证权限格式是否正确

**参数准备**:
```typescript
// module.json5权限配置结构
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      },
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      }
    ]
  }
}
```

### 步骤2: 配置module.json5权限

**示例代码**:
```typescript
// 在entry/src/main/module.json5中配置权限
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet",
      "2in1"
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:permission_internet_reason",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.GET_NETWORK_INFO",
        "reason": "$string:permission_network_info_reason",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when": "inuse"
        }
      }
    ]
  }
}
```

**说明**:
- ohos.permission.INTERNET: 用于应用访问互联网(必需)
- ohos.permission.GET_NETWORK_INFO: 用于获取设备网络信息(部分场景必需)
- 除取消网络请求、关闭会话外,其余请求都需要权限

### 步骤3: C API环境配置(可选)

**前置校验**:
1. 确认使用C API开发Remote Communication Kit
2. 检查CMakeLists.txt文件是否存在
3. 检查是否已配置动态库路径和头文件路径
4. 验证链接库名称是否正确

**配置示例**:
```cmake
# CMakeLists.txt配置示例
# 编译target为entry
cmake_minimum_required(VERSION 3.4.1)
project(entry)

# 设置头文件路径
target_include_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

# 设置动态库路径
target_link_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

# 链接librcp_c.so及其他依赖的so
target_link_libraries(entry PUBLIC 
    librcp_c.so
)
```

**说明**:
- HMOS_SDK_NATIVE: HarmonyOS Native SDK路径环境变量
- librcp_c.so: Remote Communication Kit C API核心库
- 需根据实际编译target调整配置

### 步骤4: HTTP明文传输配置(可选)

**前置校验**:
1. 确认是否需要HTTP明文传输(建议优先使用HTTPS)
2. 检查src/main/resources/base/profile目录是否存在
3. 检查network_config.json文件是否存在(不存在则创建)
4. 验证配置是否符合安全规范

**配置示例**:
```json
// network_config.json配置示例
{
  "network-security-config": {
    "base-config": {
      "cleartextTrafficPermitted": true
    },
    "domain-config": [
      {
        "domains": [
          {
            "name": "example.com"
          }
        ],
        "cleartextTrafficPermitted": false
      }
    ],
    "component-config": {
      "Remote Communication Kit": true
    }
  }
}
```

**说明**:
- base-config.cleartextTrafficPermitted: 全局明文传输策略(true允许,false禁止)
- domain-config: 特定域名的明文传输策略
- component-config.Remote Communication Kit: 指定Remote Communication Kit组件配置
- 从API 6.1.0(23)开始支持HTTP明文拦截配置
- 禁止对敏感域名使用明文通信,尝试HTTP请求将触发错误码1007900201

### 步骤5: 配置验证

**验证代码**:
```typescript
// 验证配置完整性示例代码
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function validateConfiguration(): Promise<boolean> {
  try {
    // 尝试创建session验证权限配置
    const session = rcp.createSession();
    console.info('Session created successfully, permissions configured correctly');
    
    // 及时关闭session释放资源
    session.close();
    return true;
  } catch (err) {
    let error: BusinessError = err as BusinessError;
    console.error(`Configuration validation failed: code ${error.code}, message ${error.message}`);
    
    // 根据错误码判断配置问题
    if (error.code === 201) {
      console.error('Permission denied: please check module.json5 permissions configuration');
    } else if (error.code === 1007900994) {
      console.error('Sessions number reached limit: too many session instances');
    }
    return false;
  }
}
```

### 步骤6: 错误处理和降级方案

**错误处理示例**:
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function handleConfigurationError(): Promise<void> {
  const session = rcp.createSession();
  
  try {
    // 测试网络请求
    const response = await session.get('https://www.example.com');
    console.info(`Request succeeded: status ${response.statusCode}`);
  } catch (err) {
    let error: BusinessError = err as BusinessError;
    
    switch (error.code) {
      case 201:
        console.error('Permission denied: configure ohos.permission.INTERNET in module.json5');
        break;
      case 1007900003:
        console.error('URL format error: check URL format');
        break;
      case 1007900006:
        console.error('DNS resolution failed: check network connection and URL');
        break;
      case 1007900007:
        console.error('Cannot connect to server: check network connection');
        break;
      case 1007900028:
        console.error('Timeout reached: check network or increase timeout');
        break;
      case 1007900201:
        console.error('HTTP cleartext not permitted: configure network_config.json or use HTTPS');
        break;
      default:
        console.error(`Unknown error: code ${error.code}, message ${error.message}`);
    }
  } finally {
    session.close();
  }
}
```

## 错误码说明

### 权限相关错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限被拒绝 | 在module.json5中配置ohos.permission.INTERNET和ohos.permission.GET_NETWORK_INFO权限 |
| 401 | 参数错误 | 检查传入的配置参数格式是否正确 |
| 1007900994 | 会话数达到限制 | 减少创建的session数量,不超过1024个 |

### HTTP明文相关错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1007900201 | HTTP明文访问被拦截 | 配置network_config.json或改用HTTPS协议 |

### 网络连接相关错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1007900001 | 不支持的协议 | 检查协议版本,确保服务器支持 |
| 1007900003 | URL格式错误 | 检查URL格式是否正确 |
| 1007900006 | 域名解析失败 | 检查URL和网络连接 |
| 1007900007 | 无法连接服务器 | 检查网络连接状态 |
| 1007900028 | 操作超时 | 检查网络,必要时重新创建Session |

### C API相关错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1007900988 | 文件打开错误 | 检查应用是否有文件读写权限 |
| 1007900987 | 创建目录错误 | 检查应用是否有创建目录权限 |
| 1007900985 | 文件系统IO错误 | 检查文件路径访问权限和合法性 |

## 编译和修复问题

### 依赖声明

**ArkTS API依赖**:
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": "^4.1.0"
  }
}
```

**C API依赖**:
```cmake
target_link_libraries(entry PUBLIC librcp_c.so)
```

### 环境要求

**ArkTS API环境**:
- HarmonyOS API版本: ≥4.1.0(11)
- DevEco Studio版本: ≥3.1
- Node.js版本: ≥14.19.1

**C API环境**:
- HarmonyOS API版本: ≥4.1.0(11)
- CMake版本: ≥3.4.1
- Native SDK路径: 环境变量HMOS_SDK_NATIVE

### 常见编译问题

**问题1: 权限未配置导致编译失败**
```
Error: Permission denied (ohos.permission.INTERNET)
```
**解决方法**:
- 在entry/src/main/module.json5中添加requestPermissions配置
- 配置ohos.permission.INTERNET权限

**问题2: C API链接库找不到**
```
Error: cannot find -librcp_c.so
```
**解决方法**:
- 在CMakeLists.txt中配置target_link_directories
- 设置${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos路径

**问题3: HTTP明文请求被拦截**
```
Error code: 1007900201, HTTP cleartext not permitted
```
**解决方法**:
- 在src/main/resources/base/profile/network_config.json中配置明文传输策略
- 或改用HTTPS协议

**问题4: Session创建数量超限**
```
Error code: 1007900994, Sessions number reached limit
```
**解决方法**:
- 及时关闭不使用的session(session.close())
- 控制并发session数量不超过1024个

## 常见问题与解决方法

### Q1: 配置权限后仍提示权限不足
**原因**: 权限配置格式错误或权限未生效
**解决方法**:
- 检查module.json5中requestPermissions数组格式
- 确保权限名称拼写正确(ohos.permission.INTERNET)
- 重新编译并安装应用

### Q2: C API编译链接失败
**原因**: CMakeLists.txt配置不完整
**解决方法**:
- 添加target_include_directories配置头文件路径
- 添加target_link_directories配置动态库路径
- 添加target_link_libraries链接librcp_c.so

### Q3: HTTP请求返回1007900201错误码
**原因**: HTTP明文访问被拦截
**解决方法**:
- 配置network_config.json允许明文传输
- 或将HTTP请求改为HTTPS请求
- 检查域名是否在禁止明文传输列表中

### Q4: 如何验证配置是否成功
**原因**: 需要验证开发环境配置完整性
**解决方法**:
- 使用rcp.createSession()创建session测试权限
- 发送简单的GET请求测试网络连接
- 检查返回的响应状态码

### Q5: Session数量限制是多少
**原因**: API版本更新导致限制变化
**解决方法**:
- API 5.1.0(18)之前: 最多16个session
- API 5.1.0(18)及之后: 最多1024个session
- 及时关闭不使用的session释放资源

## 输出结果报告

配置完成后输出以下信息:

```json
{
  "status": "success",
  "configurationType": "Remote Communication Kit Development Preparation",
  "permissions": [
    "ohos.permission.INTERNET",
    "ohos.permission.GET_NETWORK_INFO"
  ],
  "apiVersion": "≥4.1.0(11)",
  "capiConfigured": false,
  "httpCleartextConfigured": false,
  "validationResult": {
    "permissionCheck": "passed",
    "sessionCreation": "passed",
    "networkTest": "passed"
  },
  "apiUsed": [
    "rcp.createSession",
    "rcp.Session.get",
    "rcp.Session.close"
  ]
}
```

## 参考文档

- [API开发指南](references/remote-communication-preparations.md)
- [ArkTS API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [错误码说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-error-code)
- [HTTP明文配置说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/http-request)

## 完整示例代码

- [ArkTS权限配置示例](assets/module.json5)
- [C API CMakeLists配置示例](assets/CMakeLists.txt)
- [HTTP明文配置示例](assets/network_config.json)
- [配置验证测试示例](assets/config_validation.ets)

## 测试用例

### 正向测试用例
- [权限配置验证测试](tests/test_permission_config.py): 验证module.json5权限配置正确性
- [Session创建测试](tests/test_session_creation.py): 验证session创建成功
- [网络请求测试](tests/test_network_request.py): 验证基础网络请求功能

### 边界测试用例
- [最大Session数量测试](tests/test_session_limit.py): 测试session创建数量限制(1024个)
- [HTTP明文域名配置测试](tests/test_cleartext_domain.py): 测试域名明文传输策略配置

### 异常测试用例
- [权限缺失测试](tests/test_permission_missing.py): 测试未配置权限时的错误处理
- [URL格式错误测试](tests/test_url_format_error.py): 测试URL格式错误的处理
- [网络连接失败测试](tests/test_network_failure.py): 测试网络异常的降级处理