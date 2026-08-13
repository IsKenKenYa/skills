// 请求暂停与恢复示例代码
import { rcp } from '@kit.RemoteCommunicationKit';
import { util } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义调试信息接口
interface StringifiedDebugInfo {
  type: rcp.DebugEvent;
  data: string;
}

// 定义调试信息源类型
type DebugInfoSource = undefined | rcp.DebugInfo[] | rcp.Response;

// 定义调试信息序列化函数
function debugInfoStringify(infoSource: DebugInfoSource): StringifiedDebugInfo[] {
  const debugInfo = Array.isArray(infoSource)
    ? (infoSource as rcp.DebugInfo[])
    : (infoSource as rcp.Response).debugInfo;
  if (!debugInfo) {
    return [];
  }
  const decoder = util.TextDecoder.create('utf-8');
  return debugInfo.map((i: rcp.DebugInfo): StringifiedDebugInfo => {
    return {
      type: i.type,
      data: decoder.decodeToString(new Uint8Array(i.data)).trim(),
    };
  });
}

// 获取发送暂停事件
function getSendPausedEvents(debugInfo: DebugInfoSource) {
  return debugInfoStringify(debugInfo).filter((i) => i.data.startsWith('[[RCP]]: Pause sending'));
}

// 获取发送恢复事件
function getSendResumedEvents(debugInfo: DebugInfoSource) {
  return debugInfoStringify(debugInfo).filter((i) => i.data.startsWith('[[RCP]]: Resume sending'));
}

// 实现请求暂停与恢复的完整示例
async function SendingPauseByTimeout(): Promise<void> {
  const HTTP_SERVER_POST: string = 'https://example.org/anything';
  
  // 创建会话
  const session = rcp.createSession();
  
  // 创建请求
  const request = new rcp.Request(HTTP_SERVER_POST);
  
  // 定义发送暂停策略（超时时间 1ms）
  const sendPolicy: rcp.SendingPausePolicy = {
    kind: 'timeout',
    timeoutMs: 1,
  };
  
  // 定义暂停策略
  const pausePolicy: rcp.PausePolicy = {
    sending: sendPolicy,
  };
  
  // 设置请求配置
  request.configuration = {
    transfer: {
      pausePolicy: pausePolicy,
    },
    tracing: {
      infoToCollect: {
        textual: true,
      },
    },
  };
  
  // 定义请求体数据
  const data = 'TestData';
  
  // 设置请求头
  request.headers = {
    'Content-Length': data.length.toString(),
  };
  
  // 定义请求体内容生成函数
  let isReadCompleted = false;
  request.content = (maxSize) => {
    if (isReadCompleted) {
      return new ArrayBuffer(0);
    }
    isReadCompleted = true;
    const buffer = new ArrayBuffer(data.length);
    util.TextEncoder.create('utf-8').encodeIntoUint8Array(data, new Uint8Array(buffer));
    return buffer;
  };
  
  // 设置请求方法
  request.method = 'POST';
  
  try {
    // 发送请求并等待响应
    const response = await session.fetch(request);
    
    // 从响应的调试信息中获取发送暂停和恢复事件
    const pausedEvents = getSendPausedEvents(response);
    const resumedEvents = getSendResumedEvents(response);
    
    console.info(`发送暂停事件数量: ${pausedEvents.length}`);
    console.info(`发送恢复事件数量: ${resumedEvents.length}`);
    
    // 打印暂停和恢复事件的详细信息
    pausedEvents.forEach((event, index) => {
      console.info(`暂停事件 ${index + 1}: ${event.data}`);
    });
    
    resumedEvents.forEach((event, index) => {
      console.info(`恢复事件 ${index + 1}: ${event.data}`);
    });
    
    // 处理响应数据
    if (response.body) {
      const decoder = util.TextDecoder.create('utf-8');
      const responseBody = decoder.decodeToString(new Uint8Array(response.body));
      console.info(`响应状态码: ${response.statusCode}`);
      console.info(`响应内容: ${responseBody}`);
    }
    
    console.info('请求暂停与恢复示例执行成功');
    
  } catch (error) {
    const err = error as BusinessError;
    console.error(`请求失败: code=${err.code}, message=${err.message}`);
    
    // 错误处理
    switch (err.code) {
      case 401:
        console.error('参数错误: 请检查请求参数');
        break;
      case 1007900994:
        console.error('会话数量达到上限: 最多1024个会话');
        break;
      case 1007900001:
        console.error('网络连接错误: 请检查网络连接和URL');
        break;
      default:
        console.error(`未知错误: ${err.code}`);
    }
    
  } finally {
    // 关闭会话
    session.close();
    console.info('Session 已关闭');
  }
}

// 主函数
@Entry
@Component
struct PauseResumeExample {
  build() {
    Column() {
      Button('执行请求暂停恢复示例')
        .onClick(() => {
          SendingPauseByTimeout();
        })
        .width('80%')
        .height(50)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}