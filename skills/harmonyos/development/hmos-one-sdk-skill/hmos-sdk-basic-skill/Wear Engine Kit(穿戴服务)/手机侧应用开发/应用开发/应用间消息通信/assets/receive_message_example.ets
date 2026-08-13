/**
 * 消息接收示例
 * 仅包含消息接收功能
 */

import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';

export class MessageReceiver {
  private p2pClient: wearEngine.P2pClient;
  private targetDevice: wearEngine.Device;
  private bundleName: string;
  private fingerprint: string;
  private messageCallback: (p2pMessage: wearEngine.P2pMessage) => void | null = null;
  private receivedMessages: string[] = [];
  
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
   * 注册消息接收监听
   * @returns Promise<boolean> 注册是否成功
   */
  async registerReceiver(): Promise<boolean> {
    // 构造应用参数
    let appInfo: wearEngine.AppInfo = {
      bundleName: this.bundleName,
      fingerprint: this.fingerprint
    };
    
    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };
    
    // 定义消息接收回调函数
    this.messageCallback = (p2pMessage: wearEngine.P2pMessage) => {
      console.info('Received message from wear device');
      
      if (p2pMessage.content) {
        let textDecoder = util.TextDecoder.create('utf-8');
        let messageStr = textDecoder.decodeToString(p2pMessage.content);
        
        // 存储接收到的消息
        this.receivedMessages.push(messageStr);
        console.info(`Message content: ${messageStr}`);
        
        // 触发消息处理回调（可自定义）
        this.onMessageReceived(messageStr);
      }
    };
    
    try {
      await this.p2pClient.registerMessageReceiver(
        this.targetDevice.randomId,
        appParam,
        this.messageCallback
      );
      console.info('Succeeded in registering message receiver');
      return true;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to register message receiver. Code: ${err.code}, message: ${err.message}`);
      this.handleRegisterError(err);
      return false;
    }
  }
  
  /**
   * 取消消息接收监听
   * @returns Promise<boolean> 取消是否成功
   */
  async unregisterReceiver(): Promise<boolean> {
    if (!this.messageCallback) {
      console.warn('Message receiver not registered');
      return false;
    }
    
    // 构造应用参数
    let appInfo: wearEngine.AppInfo = {
      bundleName: this.bundleName,
      fingerprint: this.fingerprint
    };
    
    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };
    
    try {
      await this.p2pClient.unregisterMessageReceiver(
        this.targetDevice.randomId,
        appParam,
        this.messageCallback
      );
      console.info('Succeeded in unregistering message receiver');
      this.messageCallback = null;
      return true;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to unregister message receiver. Code: ${err.code}, message: ${err.message}`);
      return false;
    }
  }
  
  /**
   * 处理注册错误
   */
  private handleRegisterError(error: BusinessError): void {
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
      case 1008500012:
        console.error('Too many callbacks: Same callback already registered');
        break;
      default:
        console.error(`Unknown error: ${error.code}`);
    }
  }
  
  /**
   * 消息接收回调（可自定义实现）
   */
  private onMessageReceived(message: string): void {
    // 用户可自定义消息处理逻辑
    console.info(`Processing received message: ${message}`);
    
    // 示例：解析JSON消息
    try {
      let jsonMessage = JSON.parse(message);
      console.info('Received JSON message:', jsonMessage);
    } catch (error) {
      // 非JSON格式，当作普通文本处理
    }
  }
  
  /**
   * 获取所有接收到的消息
   */
  getReceivedMessages(): string[] {
    return this.receivedMessages;
  }
  
  /**
   * 清空消息列表
   */
  clearMessages(): void {
    this.receivedMessages = [];
  }
  
  /**
   * 获取最新消息
   */
  getLastMessage(): string | null {
    if (this.receivedMessages.length > 0) {
      return this.receivedMessages[this.receivedMessages.length - 1];
    }
    return null;
  }
}

// 使用示例
async function messageReceiverExample(): void {
  // 初始化MessageReceiver
  let deviceClient = wearEngine.getDeviceClient(context);
  let deviceList = await deviceClient.getConnectedDevices();
  let targetDevice = deviceList[0];
  
  let receiver = new MessageReceiver(
    context,
    targetDevice,
    'com.example.wearapp',
    'your_app_fingerprint'
  );
  
  // 注册消息接收监听
  let registered = await receiver.registerReceiver();
  if (registered) {
    console.info('Message receiver registered');
  }
  
  // 等待接收消息
  setTimeout(() => {
    // 获取接收到的消息
    let messages = receiver.getReceivedMessages();
    console.info(`Received ${messages.length} messages`);
    
    // 获取最新消息
    let lastMessage = receiver.getLastMessage();
    if (lastMessage) {
      console.info(`Last message: ${lastMessage}`);
    }
    
    // 取消消息接收监听
    receiver.unregisterReceiver();
  }, 10000); // 10秒后取消监听
}