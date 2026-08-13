---
name: hmos-remote-communication-kit-custom-dns-config
description: 定制DNS配置，支持自定义DNS服务器、静态DNS规则和动态DNS解析函数，适用于网络管理、安全域名解析、性能优化场景
---

# 定制DNS配置技能

## 功能描述

本技能提供DNS（Domain Name System）定制配置能力，允许开发者根据自身需求调整DNS查询行为。支持三种DNS定制方式：
- 自定义DNS服务器：指定自定义的DNS服务器提供解析服务
- 静态DNS规则：当默认DNS不能正常解析部分域名时，手动添加静态DNS映射
- 动态DNS规则：通过函数动态返回域名对应的IP地址

此外，还支持DNS over HTTPS（DOH）配置，通过加密的HTTPS协议进行DNS解析请求，避免原始DNS协议中用户DNS解析请求被窃听或修改，实现保护用户隐私的目的。

## 使用场景

### 触发词
- "定制DNS"
- "配置DNS服务器"
- "自定义DNS"
- "DNS解析"
- "静态DNS"
- "动态DNS"
- "DNS over HTTPS"
- "DOH配置"

### 能做
- 配置自定义DNS服务器IP和端口
- 为特定域名添加静态DNS映射规则
- 实现动态DNS解析函数
- 配置DNS over HTTPS加密解析
- 启用Happy Eyeball竞速连接优化

### 绝不做
- 不处理非DNS相关的网络配置
- 不直接修改系统DNS设置
- 不处理DNS缓存管理
- 不执行DNS服务器搭建

### 补充
- 支持Phone、2in1、Tablet、Wearable设备（4.1.0(11)版本起）
- 支持TV设备（5.1.1(19)版本起）
- 支持Car设备（6.1.0(23)版本起）
- 针对同一域名配置多个静态或动态DNS规则后，默认情况下仅有最后一个IP地址生效
- 从6.0.0(20)版本起，可通过happyEyeballOnDnsRule=true让多个IP地址同时生效

## 调用规范和规则

### 输入约束
- DNS服务器IP：有效的IPv4或IPv6地址字符串
- DNS服务器端口：范围[0, 65535]，默认53
- 主机名（host）：非空字符串
- 端口号（port）：范围[0, 65535]
- IP地址列表（ipAddresses）：非空数组，包含有效的IPv4或IPv6地址

### 执行约束
- 最大DNS解析时间：由transfer.timeout.transferMs控制，默认60000ms
- DNS服务器连接超时：由transfer.timeout.connectMs控制，默认60000ms
- 最大Session实例数：1024个（从5.1.0(18)版本起）
- Session使用完毕后必须调用close()释放资源

### 内容约束
- 禁止使用无效的IP地址格式
- 禁止配置超出范围的端口值
- 禁止在DNS解析函数中返回空数组（除非明确不需要解析）
- 禁止硬编码敏感的DNS服务器信息（建议使用配置文件）

### 降级约束
- DNS解析失败：使用系统默认DNS继续解析
- 自定义DNS服务器不可达：尝试备用DNS服务器或降级到系统DNS
- DNS over HTTPS失败：降级使用普通DNS协议（需在安全配置中允许）
- 动态DNS函数异常：返回空数组，让系统继续使用其他DNS规则

## 调用流程和步骤

### 场景一：定制DNS服务器

#### 步骤1：准备阶段

**导入必要模块**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

**前置校验**：
1. 确认DNS服务器IP地址有效（IPv4或IPv6格式）
2. 确认DNS服务器端口在有效范围内[0, 65535]
3. 确认请求URL格式正确

**参数准备**：
```typescript
const dnsServerIp = '8.8.8.8'; // DNS服务器IP地址
const dnsServerPort = 53; // DNS服务器端口，默认为53
const requestUrl = 'https://example.com'; // 请求URL
```

#### 步骤2：创建Session和Request

**创建会话对象**：
```typescript
const session = rcp.createSession();
```

**创建请求对象**：
```typescript
const request = new rcp.Request(requestUrl);
```

#### 步骤3：配置DNS规则

**配置自定义DNS服务器**：
```typescript
request.configuration = {
  dns: {
    dnsRules: [
      {
        ip: dnsServerIp,
        port: dnsServerPort
      }
    ]
  }
};
```

**参数说明**：
- `ip`: DNS服务器的IP地址（必填）
- `port`: DNS服务器的端口号（可选，默认53）

#### 步骤4：发起网络请求

**发送请求并处理响应**：
```typescript
session.fetch(request).then((response: rcp.Response) => {
  console.info(`The response is ${JSON.stringify(response)}`);
  session.close();
}).catch((err: BusinessError) => {
  console.error(`The error code is ${err.code}, error data is ${err.data}`);
  session.close();
});
```

### 场景二：定制DNS解析函数

#### 步骤1：准备阶段

**导入必要模块**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

**参数准备**：
```typescript
const requestUrl = 'https://example.com';
```

#### 步骤2：创建Session和Request

**创建会话和请求对象**：
```typescript
const session = rcp.createSession();
const request = new rcp.Request(requestUrl);
```

#### 步骤3：配置动态DNS规则

**实现动态DNS解析函数**：
```typescript
request.configuration = {
  dns: {
    dnsRules: (host: string, port: number): rcp.IpAddress[] => {
      if (host === 'example.com') {
        return ['192.168.1.100', '192.168.1.101'];
      }
      return [];
    }
  }
};
```

**函数说明**：
- 输入参数：`host`（主机名）和`port`（端口号）
- 返回值：`IpAddress[]`（IP地址数组）
- 如果匹配到特定域名，返回对应的IP地址列表
- 如果不匹配，返回空数组让系统继续使用其他DNS规则

#### 步骤4：发起网络请求

**发送请求并处理响应**：
```typescript
session.fetch(request).then((response: rcp.Response) => {
  console.info(`The response is ${JSON.stringify(response)}`);
  session.close();
}).catch((err: BusinessError) => {
  console.error(`The error code is ${err.code}, error data is ${err.data}`);
  session.close();
});
```

### 场景三：配置静态DNS规则

#### 步骤1：准备阶段

**导入必要模块**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

#### 步骤2：创建Session和Request

**创建会话和请求对象**：
```typescript
const session = rcp.createSession();
const request = new rcp.Request('https://example.com');
```

#### 步骤3：配置静态DNS规则

**配置静态DNS映射**：
```typescript
request.configuration = {
  dns: {
    dnsRules: [
      {
        host: 'example.com',
        port: 443,
        ipAddresses: ['192.168.1.100', '192.168.1.101']
      },
      {
        host: 'sub.example.com',
        port: 443,
        ipAddresses: ['192.168.2.100']
      }
    ],
    happyEyeballOnDnsRule: true // 启用多个IP同时生效（需要6.0.0(20)版本）
  }
};
```

**参数说明**：
- `host`: 应用静态DNS规则的主机名（必填）
- `port`: 应用静态DNS规则的端口号（必填，范围[0, 65535])
- `ipAddresses`: 关联的IP地址数组（必填）
- `happyEyeballOnDnsRule`: 是否启用Happy Eyeball竞速连接（可选，默认false）

#### 步骤4：发起网络请求

**发送请求并处理响应**：
```typescript
session.fetch(request).then((response: rcp.Response) => {
  console.info(`The response is ${JSON.stringify(response)}`);
  session.close();
}).catch((err: BusinessError) => {
  console.error(`The error code is ${err.code}, error data is ${err.data}`);
  session.close();
});
```

### 场景四：配置DNS over HTTPS

#### 步骤1：准备阶段

**导入必要模块**：
```typescript
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

#### 步骤2：创建Session

**创建会话对象并配置DOH**：
```typescript
const dohConfig: rcp.DnsOverHttpsConfiguration = {
  url: 'https://dns.example.com/dns-query',
  skipCertificatesValidation: false
};

const session = rcp.createSession({
  requestConfiguration: {
    dns: {
      dnsOverHttps: dohConfig
    }
  }
});
```

**参数说明**：
- `url`: DOH端点的URL（必填）
- `skipCertificatesValidation`: 是否跳过SSL/TLS证书验证（可选，默认false）

#### 步骤3：创建Request并发送请求

**创建请求并发送**：
```typescript
const request = new rcp.Request('https://example.com');

session.fetch(request).then((response: rcp.Response) => {
  console.info(`The response is ${JSON.stringify(response)}`);
  session.close();
}).catch((err: BusinessError) => {
  console.error(`The error code is ${err.code}, error data is ${err.data}`);
  session.close();
});
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error | 检查参数格式和取值范围是否正确 |
| 1007900994 | Sessions number reached limit | 关闭未使用的Session，确保不超过1024个实例 |
| DNS解析失败 | DNS服务器无法解析域名 | 检查DNS服务器是否可用，或添加静态DNS规则 |
| DNS服务器连接超时 | 无法连接到自定义DNS服务器 | 检查DNS服务器IP和端口是否正确，网络是否连通 |
| DOH请求失败 | DNS over HTTPS请求失败 | 检查DOH URL是否正确，证书是否有效 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.RemoteCommunicationKit": "4.1.0(11)+",
    "@kit.BasicServicesKit": "4.1.0(11)+"
  }
}
```

### 环境要求
- HarmonyOS SDK: 4.1.0(11)或更高版本
- DevEco Studio: 3.1或更高版本
- API版本要求：
  - 基础DNS配置：4.1.0(11)
  - DNS over HTTPS：4.1.0(11)
  - Happy Eyeball优化：6.0.0(20)

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.RemoteCommunicationKit'
```
**解决方法**：
1. 确认HarmonyOS SDK版本>= 4.1.0(11)
2. 在module.json5中添加依赖声明
3. 执行npm install或ohpm install

**问题2：Session数量超限**
```
Error: 1007900994 - Sessions number reached limit
```
**解决方法**：
1. 检查代码中是否有未关闭的Session
2. 在请求完成后立即调用session.close()
3. 使用Session池管理，复用Session实例

**问题3：DNS配置不生效**
```
DNS解析仍然使用系统默认DNS
```
**解决方法**：
1. 确认DNS配置设置在request.configuration中
2. 检查dnsRules参数格式是否正确
3. 确认DNS服务器IP地址和端口是否正确

## 常见问题与解决方法

### Q1：如何同时使用自定义DNS服务器和静态DNS规则？

**原因**：dnsRules参数只能配置一种类型（DnsServers、StaticDnsRules或DynamicDnsRule）

**解决方法**：
- 方案一：在Session级别配置DNS服务器，在Request级别配置静态DNS规则
```typescript
const session = rcp.createSession({
  requestConfiguration: {
    dns: {
      dnsRules: [{ ip: '8.8.8.8', port: 53 }]
    }
  }
});

const request = new rcp.Request('https://example.com');
request.configuration = {
  dns: {
    dnsRules: [
      { host: 'example.com', port: 443, ipAddresses: ['192.168.1.100'] }
    ]
  }
};
```

- 方案二：使用动态DNS函数，在函数内部判断并返回不同的IP地址

### Q2：配置多个静态DNS规则后，只有最后一个生效？

**原因**：默认情况下，针对同一域名配置多个静态DNS规则后，仅有最后一个IP地址生效

**解决方法**：
- 从6.0.0(20)版本起，设置happyEyeballOnDnsRule=true
```typescript
request.configuration = {
  dns: {
    dnsRules: [
      { host: 'example.com', port: 443, ipAddresses: ['192.168.1.100', '192.168.1.101'] }
    ],
    happyEyeballOnDnsRule: true
  }
};
```

### Q3：DNS over HTTPS配置失败？

**原因**：DOH URL不正确或证书验证失败

**解决方法**：
1. 确认DOH URL格式正确（如：https://dns.google/dns-query）
2. 检查DOH服务器是否支持HTTPS
3. 如果测试环境，可以设置skipCertificatesValidation=true
4. 生产环境建议配置正确的CA证书

### Q4：动态DNS解析函数返回空数组后如何处理？

**原因**：动态DNS函数返回空数组表示不匹配当前域名

**解决方法**：
- 返回空数组后，系统会继续使用其他DNS规则（Session级别配置或系统默认DNS）
- 如果希望完全自定义DNS解析，建议不要返回空数组
- 可以在函数中添加日志，追踪DNS解析过程

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "dnsConfig": {
    "type": "custom_dns_server | static_dns_rules | dynamic_dns_rule | dns_over_https",
    "details": "具体配置信息"
  },
  "apiUsed": [
    "rcp.createSession",
    "rcp.Request",
    "rcp.Configuration",
    "rcp.DnsConfiguration",
    "rcp.DnsServers",
    "rcp.StaticDnsRules",
    "rcp.DynamicDnsRule",
    "rcp.DnsOverHttpsConfiguration",
    "rcp.IpAddress",
    "rcp.IpAndPort"
  ],
  "sessionInfo": {
    "id": "session_id",
    "status": "closed"
  }
}
```

## 参考文档

- [API开发指南：定制DNS](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-customdnsconfig)
- [API参考说明：DnsConfiguration](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [API参考说明：DnsServers](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [API参考说明：StaticDnsRules](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [API参考说明：DynamicDnsRule](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)
- [API参考说明：DnsOverHttpsConfiguration](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-rcp)

## 完整示例代码

- [ArkTS示例：定制DNS服务器](assets/custom_dns_server.ets)
- [ArkTS示例：定制DNS解析函数](assets/dynamic_dns_resolver.ets)
- [ArkTS示例：静态DNS规则配置](assets/static_dns_rules.ets)
- [ArkTS示例：DNS over HTTPS配置](assets/dns_over_https.ets)
- [配置文件示例](assets/dns_config.json)

## 测试用例

### 正向测试用例
- [定制DNS服务器成功解析](tests/test_custom_dns_server.py)：验证自定义DNS服务器能正常解析域名
- [静态DNS规则匹配成功](tests/test_static_dns_rules.py)：验证静态DNS规则能正确映射域名到IP
- [动态DNS函数返回有效IP](tests/test_dynamic_dns_rule.py)：验证动态DNS函数能正确返回IP地址
- [DNS over HTTPS加密解析成功](tests/test_dns_over_https.py)：验证DOH配置能正常工作

### 边界测试用例
- [DNS服务器端口边界值测试](tests/test_dns_port_boundary.py)：测试端口范围[0, 65535]边界值
- [多个IP地址同时生效测试](tests/test_happy_eyeball.py)：测试happyEyeballOnDnsRule=true时多个IP同时生效
- [Session数量上限测试](tests/test_session_limit.py)：测试最多1024个Session实例

### 异常测试用例
- [无效DNS服务器IP测试](tests/test_invalid_dns_ip.py)：测试无效IP地址格式的错误处理
- [DNS解析失败降级测试](tests/test_dns_fallback.py)：测试DNS解析失败后的降级方案
- [DNS服务器不可达测试](tests/test_dns_unreachable.py)：测试DNS服务器不可达时的错误处理
- [DOH证书验证失败测试](tests/test_doh_cert_fail.py)：测试DOH证书验证失败时的处理