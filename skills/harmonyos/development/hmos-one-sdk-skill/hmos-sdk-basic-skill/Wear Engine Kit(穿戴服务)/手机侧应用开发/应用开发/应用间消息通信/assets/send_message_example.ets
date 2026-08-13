/**
 * 消息发送示例
 * 仅包含消息发送功能
 */

import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';

export class MessageSender {
  private p2pClient: wearEngine.P2pClient;
  private targetDevice: wearEngine.Device;
  private bundleName: string;
  private fingerprint: string;
  
  constructor(
    context: common.Context,
    targetDevice: wearEngine.Device,
    bundleName: string,
    fingerprint: string
  ) {
    this.p2pClient = wearEngine.getP2pClient(context);
    this.targetDevice = targetDevice;
    this.bundleName = bundleName;
    this.fingerprint = fingerprint;
  }
  
  /**
   * 发送消息到穿戴设备
   * @param messageContent 消息内容（最大4096字节）
   * @returns Promise<boolean> 发送是否成功
   */
  async sendMessage(messageContent: string): Promise<boolean> {
    // 构造应用参数
    let appInfo: wearEngine.AppInfo = {
      bundleName: this.bundleName,
      fingerprint: this.fingerprint
    };
    
    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };
    
    // 构造消息内容
    let textEncoder: util.TextEncoder = new util.TextEncoder();
    let encodedContent = textEncoder.encodeInto(messageContent);
    
    // 检查消息长度
    if (encodedContent.length >= 4096) {
      console.error('Message length exceeds 4096 bytes limit');
      return false;
    }
    
    let message: wearEngine.P2pMessage = {
      content: encodedContent
    };
    
    try {
      let p2pResult = await this.p2pClient.sendMessage(
        this.targetDevice.randomId,
        appParam,
        message
      );
      
      if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
        console.info('Succeeded in sending message');
        return true;
      } else {
        console.error(`Failed to send message, result code: ${p2pResult.code}`);
        return false;
      }
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to send message. Code: ${err.code}, message: ${err.message}`);
      this.handleSendError(err);
      return false;
    }
  }
  
  /**
   * 处理发送错误
   */
  private handleSendError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        console.error('Parameter error: Check bundleName and fingerprint');
        break;
      case 1008500001:
        console.error('Network error: Check network connection');
        break;
      case 1008500003:
        console.error('Device disconnected: Reconnect device');
        break;
      case 1008500004:
        console.error('App not applied for Wear Engine service');
        break;
      default:
        console.error(`Unknown error: ${error.code}`);
    }
  }
  
  /**
   * 批量发送多条消息
   * @param messages 消息列表
   * @returns Promise<number> 成功发送的消息数量
   */
  async sendMultipleMessages(messages: string[]): Promise<number> {
    let successCount = 0;
    
    for (let message of messages) {
      let result = await this.sendMessage(message);
      if (result) {
        successCount++;
      }
      
      // 添加延迟避免频繁调用
      await new Promise(resolve => setTimeout(resolve, 100));
    }
    
    console.info(`Sent ${successCount} of ${messages.length} messages`);
    return successCount;
  }
}

// 使用示例
async function sendMessageExample(): void {
  // 初始化MessageSender
  let deviceClient = wearEngine.getDeviceClient(context);
  let deviceList = await deviceClient.getConnectedDevices();
  let targetDevice = deviceList[0]; // 选择第一个设备
  
  let sender = new MessageSender(
    context,
    targetDevice,
    'com.example.wearapp',
    'your_app_fingerprint'
  );
  
  // 发送单条消息
  let success = await sender.sendMessage('Hello from phone');
  if (success) {
    console.info('Message sent successfully');
  }
  
  // 批量发送消息
  let messages = ['Message 1', 'Message 2', 'Message 3'];
  let count = await sender.sendMultipleMessages(messages);
  console.info(`Successfully sent ${count} messages`);
}