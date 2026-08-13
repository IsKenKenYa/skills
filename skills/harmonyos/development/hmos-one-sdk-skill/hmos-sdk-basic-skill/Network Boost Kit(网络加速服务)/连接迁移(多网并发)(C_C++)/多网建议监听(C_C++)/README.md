# hmos-network-boost-kit-multipath-recommendation-listener

## 概述

多网建议监听(C/C++)技能，用于监听系统多网建议变化事件。当系统感知到应用可能需要使用多网络加速的场景时（如弱网、网络切换等），会给出建议。应用通过监听多网络加速的建议，决策发起多网络加速的请求。

## 目录结构

```
hmos-network-boost-kit-multipath-recommendation-listener/
├── networkboost-netmultipath-recommendcallback-c.md  # 主技能定义文件
├── references/                                        # 参考文档
│   ├── api-guide.md                                  # API开发指南
│   └── api-reference.md                              # API参考说明
├── assets/                                            # 代码示例和资源
│   ├── multipath_recommendation_listener_example.cpp # C++完整示例
│   └── cmake_example.txt                             # CMake配置示例
└── tests/                                             # 测试用例
    ├── test_register_success.cpp                     # 正向测试
    ├── test_receive_recommendation.cpp               # 正向测试
    ├── test_unregister_success.cpp                   # 正向测试
    ├── test_null_pointer.cpp                         # 异常测试
    ├── test_invalid_callbackid.cpp                   # 异常测试
    ├── test_permission_denied.cpp                    # 异常测试
    ├── test_service_exception.cpp                    # 异常测试
    ├── test_callbackid_boundary.cpp                  # 边界测试
    └── test_multiple_register_unregister.cpp         # 边界测试
```

## 使用方法

### 1. 注册回调

```cpp
#include "NetworkBoostKit/network_boost_handover.h"

void onMultiPathRecommendationCallback(NetworkBoost_MultiPathRecommendation* recommendation) {
    // 处理多网建议
}

uint32_t callbackId = 0;
int32_t ret = HMS_NetworkBoost_RegisterMultiPathRecommendationCallback(
    onMultiPathRecommendationCallback, 
    &callbackId
);
```

### 2. 处理建议

在回调函数中根据系统建议决策：

```cpp
if (recommendation->action == NB_MULTIPATH_ACTION_REQUEST) {
    // 系统建议发起多网请求
} else if (recommendation->action == NB_MULTIPATH_ACTION_RELEASE) {
    // 系统建议释放多网请求
}
```

### 3. 取消注册

```cpp
int32_t ret = HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback(callbackId);
```

## API说明

### HMS_NetworkBoost_RegisterMultiPathRecommendationCallback

注册系统多网建议变化事件。

**参数**：
- callback: 系统多网建议变化回调函数
- callbackId: 回调的ID，由系统分配

**返回值**：
- 0: 成功
- 201: 权限不足
- 1013600001: 内部处理异常
- 1013600002: 系统处理异常
- 1013600041: 参数错误或注册达到上限

### HMS_NetworkBoost_UnregisterMultiPathRecommendationCallback

取消注册系统多网建议变化事件。

**参数**：
- callbackId: 注册时系统分配的回调ID

**返回值**：
- 0: 成功
- 201: 权限不足
- 1013600001: 内部处理异常
- 1013600002: 系统处理异常

## 权限要求

需要在module.json5中申请以下权限：

```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.LINKTURBO"
      }
    ]
  }
}
```

## 系统要求

- HarmonyOS版本：>= 6.0.2(22)
- 系统能力：SystemCapability.Communication.NetworkBoost.Core

## 依赖

- 库文件：libnetwork_boost.so
- 头文件：NetworkBoostKit/network_boost_handover.h

## 编译配置

在CMakeLists.txt中添加：

```cmake
find_library(network_boost_lib libnetwork_boost.so)

target_link_libraries(your_target
    ${network_boost_lib}
)
```

## 参考文档

- [API开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-netmultipath-recommendcallback-c)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)

## 测试

运行测试用例验证功能：

```bash
# 编译测试
cd tests
cmake ..
make

# 运行测试
./test_register_success
./test_receive_recommendation
./test_unregister_success
```

## 版本信息

- 技能名称：hmos-network-boost-kit-multipath-recommendation-listener
- 起始版本：6.0.2(22)
- 更新日期：2026-07-03