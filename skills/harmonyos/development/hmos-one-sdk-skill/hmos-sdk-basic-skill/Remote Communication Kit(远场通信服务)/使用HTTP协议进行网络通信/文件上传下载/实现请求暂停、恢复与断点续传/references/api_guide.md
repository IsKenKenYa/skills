# API 开发指南参考

本文件包含原始 API 开发指南文档的引用信息。

## 原始文档

- **文档路径**: `D:\z00810349\APIDevice\output\md_output\harmonyos-guides\系统\网络\Remote Communication Kit（远场通信服务）\使用HTTP协议进行网络通信\文件上传下载\实现请求暂停、恢复与断点续传\remote-communication-pauseresume.md`
- **在线链接**: [实现请求暂停、恢复与断点续传](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-pauseresume)

## 文档内容摘要

### 约束与限制
- 设备支持：Phone、2in1、Tablet、Wearable
- 从 API 5.1.0(19) 开始支持 TV 设备
- 从 API 6.1.0(23) 开始支持 Car 设备

### 请求暂停、恢复

#### 场景介绍
Remote Communication Kit 提供完善的功能支持，包括请求的暂停和恢复功能。这不仅涵盖接收暂停，还包括发送暂停。

#### 核心功能
1. 定义调试信息接口和序列化函数
2. 获取发送暂停和恢复事件
3. 配置暂停策略（SendingPausePolicy）
4. 设置请求配置和跟踪信息
5. 发送请求并分析调试信息

### 断点续传

#### 场景介绍
在需要接续数据请求的场景中，用户可以通过定义 TransferRange 对象的 from 和 to 属性来控制数据的截取范围。下载的内容可以被准确地截取并拼接到目标文件中，确保数据的完整性和一致性。

#### 核心功能
1. 创建 session 和 request
2. 获取文件总大小（通过 content-range 响应头）
3. 实现分片下载函数
4. 实现开始、暂停、继续、停止下载功能

## 相关 API

详见 [API 参考说明](api_reference.md)