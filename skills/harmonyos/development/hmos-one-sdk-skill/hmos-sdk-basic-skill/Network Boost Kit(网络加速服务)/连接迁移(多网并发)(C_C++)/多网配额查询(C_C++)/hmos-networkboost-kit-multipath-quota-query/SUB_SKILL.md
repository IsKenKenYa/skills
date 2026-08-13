---
name: hmos-networkboost-kit-multipath-quota-query
description: 查询多网并发配额使用情况+获取已使用配额和剩余配额信息（次数和时长）+配额24小时周期刷新+适用于多网并发场景配额管理
---

# 多网配额查询技能

## 功能描述

本技能用于查询应用多网并发配额使用情况。由于多网络加速受到配额管控，应用可以获取当前剩余的多网并发配额信息，合理分配使用多网络加速的次数和时长。应用配额以24小时的周期进行刷新。配额（次数或时长）耗尽会限制使用，此时请求多网会抛出错误码，24小时后会重新分配。

**核心能力**：
- 获取已使用配额信息（次数和时长）
- 获取剩余配额信息（次数和时长）
- 配额状态实时查询
- 支持配额管理决策

**适用范围**：
- API版本：6.0.2(22)及以上
- 语言：C/C++
- Kit：Network Boost Kit

**限制条件**：
- 需要申请ohos.permission.LINKTURBO权限（受限ACL权限）
- 配额24小时周期刷新
- 配额耗尽时会限制使用

**典型场景**：
- 多网并发前查询配额余量
- 配额使用监控和统计
- 多网策略决策辅助
- 业务场景配额规划

## 使用场景

### 触发词
- "查询多网配额"
- "获取多网配额信息"
- "多网配额查询"
- "检查配额余量"
- "多网并发配额"

### 能做
- 查询应用当前多网配额使用情况
- 获取已使用配额次数和时长信息
- 获取剩余配额次数和时长信息
- 辅助应用进行配额管理决策
- 监控配额消耗状态

### 绝不做
- 不直接修改配额值（配额由系统管理）
- 不处理非多网并发场景的网络请求
- 不替代系统的配额分配机制
- 不处理配额刷新周期调整

### 补充
- 配额信息包含次数和时长两个维度
- 配额以24小时为周期自动刷新
- 配额耗尽时多网请求会返回错误码
- 需在发起多网请求前查询配额状态

## 调用规范和规则

### 输入约束
- 无需额外输入参数（查询当前应用的配额）
- 需确保已申请ohos.permission.LINKTURBO权限
- 需确保已配置libnetwork_boost.so动态库链接
- API版本需≥6.0.2(22)

### 执行约束
- API调用为同步调用，立即返回结果
- 单次查询即可获取完整配额信息
- 无最大调用频次限制
- 执行耗时通常<10ms

### 内容约束
- 禁止伪造配额数据
- 禁止绕过配额检查直接发起多网请求
- 禁止将配额信息用于非授权用途
- 禁止私自修改配额限制值

### 降级约束
- 权限不足：提示用户申请ohos.permission.LINKTURBO权限
- 内部错误：记录错误日志，建议稍后重试
- 系统服务异常：降级为单网模式，避免多网并发
- 参数错误：检查结构体初始化，确保参数有效

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查API版本是否≥6.0.2(22)
2. 确认已申请ohos.permission.LINKTURBO权限
3. 确认已配置libnetwork_boost.so动态库链接
4. 检查头文件路径配置正确

**参数准备**：
```cpp
// 定义配额结构体变量
NetworkBoost_MultiPathQuota quota = { 0 };
```

**权限检查**：
```cpp
// 确认已配置权限（在module.json5中）
"requestPermissions": [{
  "name": "ohos.permission.LINKTURBO"
}]
```

### 步骤2：调用API

**示例代码**：
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>

int32_t GetMultiPathQuotaStats()
{
    NetworkBoost_MultiPathQuota quota = { 0 };
    
    int32_t ret = HMS_NetworkBoost_GetMultiPathQuotaStats(&quota);
    
    if (ret == 0) {
        printf("获取多网配额信息成功\n");
        printf("已使用时长: %d秒\n", quota.used.duration);
        printf("已使用次数: %d次\n", quota.used.count);
        printf("剩余总时长: %d秒\n", quota.remaining.duration);
        printf("剩余总次数: %d次\n", quota.remaining.count);
    } else {
        printf("获取多网配额信息失败，错误码: %d\n", ret);
    }
    
    return ret;
}
```

### 步骤3：错误处理

```cpp
int32_t QueryQuotaWithErrorHandling()
{
    NetworkBoost_MultiPathQuota quota = { 0 };
    
    int32_t ret = HMS_NetworkBoost_GetMultiPathQuotaStats(&quota);
    
    switch (ret) {
        case 0:
            printf("配额查询成功\n");
            break;
        case 201:
            printf("权限不足，请申请ohos.permission.LINKTURBO权限\n");
            return -1;
        case 1013600001:
            printf("内部错误，建议稍后重试\n");
            return -1;
        case 1013600002:
            printf("系统处理异常，IPC调用失败或服务启动失败\n");
            return -1;
        case 1013600041:
            printf("参数错误，请检查结构体初始化\n");
            return -1;
        default:
            printf("未知错误: %d\n", ret);
            return -1;
    }
    
    return ret;
}
```

### 步骤4：降级处理

```cpp
void HandleQuotaExhausted()
{
    NetworkBoost_MultiPathQuota quota = { 0 };
    int32_t ret = HMS_NetworkBoost_GetMultiPathQuotaStats(&quota);
    
    if (ret == 0) {
        if (quota.remaining.count <= 0 || quota.remaining.duration <= 0) {
            printf("配额已耗尽，24小时后将重新分配\n");
            printf("建议：使用单网模式或等待配额刷新\n");
        } else {
            printf("配额充足，可以发起多网请求\n");
        }
    } else {
        printf("无法获取配额信息，降级为单网模式\n");
    }
}
```

### 步骤5：业务决策辅助

```cpp
bool CanRequestMultiPath()
{
    NetworkBoost_MultiPathQuota quota = { 0 };
    int32_t ret = HMS_NetworkBoost_GetMultiPathQuotaStats(&quota);
    
    if (ret != 0) {
        return false;
    }
    
    if (quota.remaining.count <= 0) {
        printf("剩余次数不足\n");
        return false;
    }
    
    if (quota.remaining.duration <= 0) {
        printf("剩余时长不足\n");
        return false;
    }
    
    printf("配额充足，剩余次数: %d, 剩余时长: %d秒\n", 
           quota.remaining.count, quota.remaining.duration);
    return true;
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功获取配额信息 | 无需处理 |
| 201 | 权限不足 | 在module.json5中申请ohos.permission.LINKTURBO权限，并在AGC中申请受限ACL权限 |
| 1013600001 | 内部错误 | 记录日志，稍后重试；检查系统服务状态 |
| 1013600002 | 系统处理异常 | 检查IPC跨进程调用状态，检查网络管理服务是否启动 |
| 1013600041 | 传入参数有误 | 检查NetworkBoost_MultiPathQuota结构体初始化，确保不为空指针 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

**module.json5权限配置**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      },
      {
        "name": "ohos.permission.INTERNET"
      },
      {
        "name": "ohos.permission.LINKTURBO"
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS API版本：≥6.0.2(22)
- 开发环境：DevEco Studio 4.0及以上
- SDK：HarmonyOS Native SDK
- 编译工具：CMake 3.16及以上

### 常见编译问题

**问题1：找不到头文件**
```
fatal error: NetworkBoostKit/network_boost_handover.h: No such file or directory
```
**解决方法**：
- 检查CMakeLists.txt中target_include_directories配置
- 确认${HMOS_SDK_NATIVE}环境变量正确设置
- 确保SDK路径指向HarmonyOS Native SDK

**问题2：链接库失败**
```
undefined reference to `HMS_NetworkBoost_GetMultiPathQuotaStats'
```
**解决方法**：
- 在CMakeLists.txt中添加target_link_libraries(entry PUBLIC libnetwork_boost.so)
- 检查target_link_directories配置的库路径是否正确

**问题3：权限不足运行错误**
```
运行时返回错误码201
```
**解决方法**：
- 在AGC中申请ohos.permission.LINKTURBO受限ACL权限
- 在module.json5中声明权限
- 配置正确的签名Profile文件

## 常见问题与解决方法

### Q1：配额信息为什么全是0？
**原因**：应用未使用过多网并发功能，或配额刚刚刷新
**解决方法**：
- 确认应用是否已发起过多网请求
- 检查配额刷新周期（24小时）
- 确认系统是否正常分配配额

### Q2：如何申请ohos.permission.LINKTURBO权限？
**原因**：LINKTURBO为受限ACL权限，需要特殊申请流程
**解决方法**：
- 在AGC互动中心申请受限ACL权限
- 在Profile申请时勾选LINKTURBO权限
- 填写申请原因并提交审核（1个工作日）
- 配置新的Profile文件
- 在module.json5中声明权限

### Q3：配额耗尽后如何处理？
**原因**：配额（次数或时长）耗尽会限制多网使用
**解决方法**：
- 等待24小时配额自动刷新
- 降级为单网模式继续业务
- 合理规划配额使用策略
- 避免频繁发起多网请求

### Q4：配额查询失败如何排查？
**原因**：可能是权限、参数或系统服务问题
**解决方法**：
- 检查错误码，根据错误码定位问题
- 确认权限配置正确
- 检查结构体初始化是否有效
- 检查系统服务运行状态

### Q5：配额的次数和时长含义是什么？
**原因**：配额包含两个维度的限制
**解决方法**：
- count：表示可以发起多网请求的次数上限
- duration：表示多网并发可使用的总时长（秒）
- 任一维度耗尽都会限制使用
- 合理规划业务场景的配额分配

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success/failed",
  "errorCode": 0,
  "quotaInfo": {
    "used": {
      "count": 5,
      "duration": 120
    },
    "remaining": {
      "count": 10,
      "duration": 300
    }
  },
  "apiUsed": [
    "HMS_NetworkBoost_GetMultiPathQuotaStats"
  ],
  "message": "配额查询成功，剩余次数充足"
}
```

## 参考文档

- [API开发指南](references/networkboost-netmultipath-getmultipathquota-c.md)
- [API参考说明](references/network-boost-c-overview.md)
- [开发准备](references/networkboost-preparations.md)
- [NetworkBoost_MultiPathQuota结构体](references/network-boost-c-struct-multipath_quota.md)
- [NetworkBoost_MultiPathQuotaInfo结构体](references/network-boost-c-struct-multipath_quotainfo.md)

## 完整示例代码

- [C++示例代码](assets/example_multipath_quota.cpp)
- [CMake配置示例](assets/example_cmake.txt)
- [权限配置示例](assets/example_permissions.json)

## 测试用例

### 正向测试用例
- [配额查询成功](tests/test_positive.cpp)：正常调用API获取配额信息
- [配额充足判断](tests/test_positive.cpp)：验证配额充足场景的业务逻辑

### 边界测试用例
- [配额刚耗尽](tests/test_boundary.cpp)：配额remaining为0的处理
- [配额即将耗尽](tests/test_boundary.cpp)：配额remaining接近0的预警

### 异常测试用例
- [权限不足](tests/test_exception.cpp)：未申请LINKTURBO权限的场景
- [参数错误](tests/test_exception.cpp)：传入空指针或未初始化结构体
- [系统服务异常](tests/test_exception.cpp)：模拟系统服务启动失败场景