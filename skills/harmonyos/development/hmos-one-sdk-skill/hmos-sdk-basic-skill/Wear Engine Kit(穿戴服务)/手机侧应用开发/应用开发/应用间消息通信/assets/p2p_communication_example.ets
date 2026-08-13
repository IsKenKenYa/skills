/**
 * P2P消息通信完整示例
 * 实现手机应用与穿戴设备应用之间的消息和文件收发功能
 */

import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct P2pCommunicationPage {
  @State deviceList: wearEngine.Device[] = [];
  @State targetDevice: wearEngine.Device | null = null;
  @State messageText: string = '';
  @State filePath: string = '';
  @State receivedMessage: string = '';
  @State transferProgress: number = 0;
  
  private deviceClient: wearEngine.DeviceClient | null = null;
  private p2pClient: wearEngine.P2pClient | null = null;
  private messageCallback: (p2pMessage: wearEngine.P2pMessage) => void | null = null;
  private fileCallback: (p2pFile: wearEngine.P2pFile) => void | null = null;
  
  async aboutToAppear(): void {
    try {
      // 初始化客户端
      this.deviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());
      this.p2pClient = wearEngine.getP2pClient(this.getUIContext().getHostContext());
      
      // 获取已连接设备列表
      this.deviceList = await this.deviceClient.getConnectedDevices();
      
      // 选择目标设备
      await this.selectTargetDevice();
      
      // 注册消息接收监听
      await this.registerMessageReceiver();
      
      console.info('P2P communication initialized successfully');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to initialize. Code: ${err.code}, message: ${err.message}`);
    }
  }
  
  aboutToDisappear(): void {
    // 取消消息接收监听
    if (this.p2pClient && this.messageCallback && this.targetDevice) {
      this.unregisterMessageReceiver();
    }
    
    // 取消文件接收监听
    if (this.p2pClient && this.fileCallback && this.targetDevice) {
      this.unregisterFileReceiver();
    }
  }
  
  /**
   * 选择目标设备（支持应用安装的设备）
   */
  async selectTargetDevice(): Promise<void> {
    for (let device of this.deviceList) {
      let isSupported = await device.isDeviceCapabilitySupported(
        wearEngine.DeviceCapability.APP_INSTALLATION
      );
      if (isSupported) {
        this.targetDevice = device;
        console.info(`Selected device: ${device.name}`);
        break;
      }
    }
    
    if (!this.targetDevice) {
      console.error('Cannot find target device with app installation capability');
    }
  }
  
  /**
   * 检测应用是否安装
   */
  async checkAppInstalled(bundleName: string): Promise<boolean> {
    if (!this.p2pClient || !this.targetDevice) {
      console.error('P2pClient or target device not initialized');
      return false;
    }
    
    try {
      let isInstall = await this.p2pClient.isRemoteAppInstalled(
        this.targetDevice.randomId,
        bundleName
      );
      console.info(`App ${bundleName} installed: ${isInstall}`);
      return isInstall;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to check app install. Code: ${err.code}, message: ${err.message}`);
      return false;
    }
  }
  
  /**
   * 获取应用版本号
   */
  async getAppVersion(bundleName: string): Promise<number> {
    if (!this.p2pClient || !this.targetDevice) {
      console.error('P2pClient or target device not initialized');
      return 0;
    }
    
    try {
      let version = await this.p2pClient.getRemoteAppVersion(
        this.targetDevice.randomId,
        bundleName
      );
      console.info(`App ${bundleName} version: ${version}`);
      return version;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to get app version. Code: ${err.code}, message: ${err.message}`);
      return 0;
    }
  }
  
  /**
   * 拉起穿戴设备应用
   */
  async startRemoteApp(bundleName: string): Promise<void> {
    if (!this.p2pClient || !this.targetDevice) {
      console.error('P2pClient or target device not initialized');
      return;
    }
    
    try {
      let p2pResult = await this.p2pClient.startRemoteApp(
        this.targetDevice.randomId,
        bundleName
      );
      
      if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
        console.info('Succeeded in starting remote app');
      } else {
        console.error(`Failed to start remote app, result code: ${p2pResult.code}`);
      }
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to start remote app. Code: ${err.code}, message: ${err.message}`);
    }
  }
  
  /**
   * 发送消息到穿戴设备
   */
  async sendMessage(bundleName: string, fingerprint: string): Promise<void> {
    if (!this.p2pClient || !this.targetDevice || !this.messageText) {
      console.error('P2pClient, target device or message not initialized');
      return;
    }
    
    // 构造应用参数
    let appInfo: wearEngine.AppInfo = {
      bundleName: bundleName,
      fingerprint: fingerprint
    };
    
    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };
    
    // 构造消息内容（最大4096字节）
    let textEncoder: util.TextEncoder = new util.TextEncoder();
    let message: wearEngine.P2pMessage = {
      content: textEncoder.encodeInto(this.messageText)
    };
    
    try {
      let p2pResult = await this.p2pClient.sendMessage(
        this.targetDevice.randomId,
        appParam,
        message
      );
      
      if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
        console.info('Succeeded in sending message');
        this.messageText = ''; // 清空消息文本
      } else {
        console.error(`Failed to send message, result code: ${p2pResult.code}`);
      }
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to send message. Code: ${err.code}, message: ${err.message}`);
    }
  }
  
  /**
   * 发送文件到穿戴设备
   */
  async transferFile(bundleName: string, fingerprint: string): Promise<void> {
    if (!this.p2pClient || !this.targetDevice || !this.filePath) {
      console.error('P2pClient, target device or file path not initialized');
      return;
    }
    
    // 构造应用参数
    let appInfo: wearEngine.AppInfo = {
      bundleName: bundleName,
      fingerprint: fingerprint
    };
    
    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };
    
    // 打开文件
    let p2pFile: wearEngine.P2pFile;
    try {
      p2pFile = {
        file: fileIo.openSync(this.filePath, fileIo.OpenMode.READ_ONLY)
      };
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to open file. Code: ${err.code}, message: ${err.message}`);
      return;
    }
    
    // 发送文件并监听传输进度
    this.p2pClient.transferFile(
      this.targetDevice.randomId,
      appParam,
      p2pFile,
      (error: BusinessError, p2pResult: wearEngine.P2pResult) => {
        if (error) {
          console.error(`Failed to transfer file. Code: ${error.code}, message: ${error.message}`);
          return;
        }
        
        if (p2pResult.code) {
          if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
            console.info('Succeeded in transferring file');
          } else {
            console.error(`Failed to transfer file, result code: ${p2pResult.code}`);
          }
        }
        
        if (p2pResult.progress) {
          this.transferProgress = p2pResult.progress;
          console.info(`Transfer progress: ${this.transferProgress}%`);
        }
      }
    );
    
    // 完成后关闭文件
    try {
      fileIo.close(p2pFile.file);
    } catch (error) {
      console.error('Failed to close file');
    }
  }
  
  /**
   * 取消文件传输
   */
  async cancelFileTransfer(bundleName: string, fingerprint: string): Promise<void> {
    if (!this.p2pClient || !this.targetDevice || !this.filePath) {
      console.error('P2pClient, target device or file path not initialized');
      return;
    }
    
    // 构造应用参数
    let appInfo: wearEngine.AppInfo = {
      bundleName: bundleName,
      fingerprint: fingerprint
    };
    
    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };
    
    // 构造文件对象
    let p2pFile: wearEngine.P2pFile;
    try {
      p2pFile = {
        file: fileIo.openSync(this.filePath, fileIo.OpenMode.READ_ONLY)
      };
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to open file. Code: ${err.code}, message: ${err.message}`);
      return;
    }
    
    try {
      let p2pResult = await this.p2pClient.cancelFileTransfer(
        this.targetDevice.randomId,
        appParam,
        p2pFile
      );
      
      if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
        console.info('Succeeded in cancelling file transfer');
        this.transferProgress = 0;
      }
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to cancel file transfer. Code: ${err.code}, message: ${err.message}`);
    }
    
    // 关闭文件
    try {
      fileIo.close(p2pFile.file);
    } catch (error) {
      console.error('Failed to close file');
    }
  }
  
  /**
   * 注册消息接收监听
   */
  async registerMessageReceiver(): Promise<void> {
    if (!this.p2pClient || !this.targetDevice) {
      console.error('P2pClient or target device not initialized');
      return;
    }
    
    // 构造应用参数
    let appInfo: wearEngine.AppInfo = {
      bundleName: 'com.example.wearapp', // 替换为实际的穿戴设备应用包名
      fingerprint: 'your_app_fingerprint' // 替换为实际的应用指纹
    };
    
    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };
    
    // 定义消息接收回调函数
    this.messageCallback = (p2pMessage: wearEngine.P2pMessage) => {
      console.info('Received message from wear device');
      
      if (p2pMessage.content) {
        let textDecoder = util.TextDecoder.create('utf-8');
        this.receivedMessage = textDecoder.decodeToString(p2pMessage.content);
        console.info(`Message content: ${this.receivedMessage}`);
      }
    };
    
    try {
      await this.p2pClient.registerMessageReceiver(
        this.targetDevice.randomId,
        appParam,
        this.messageCallback
      );
      console.info('Succeeded in registering message receiver');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to register message receiver. Code: ${err.code}, message: ${err.message}`);
    }
  }
  
  /**
   * 取消消息接收监听
   */
  async unregisterMessageReceiver(): Promise<void> {
    if (!this.p2pClient || !this.targetDevice || !this.messageCallback) {
      console.error('P2pClient, target device or message callback not initialized');
      return;
    }
    
    // 构造应用参数
    let appInfo: wearEngine.AppInfo = {
      bundleName: 'com.example.wearapp',
      fingerprint: 'your_app_fingerprint'
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
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to unregister message receiver. Code: ${err.code}, message: ${err.message}`);
    }
  }
  
  /**
   * 注册文件接收监听
   */
  async registerFileReceiver(): Promise<void> {
    if (!this.p2pClient || !this.targetDevice) {
      console.error('P2pClient or target device not initialized');
      return;
    }
    
    // 构造应用参数
    let appInfo: wearEngine.AppInfo = {
      bundleName: 'com.example.wearapp',
      fingerprint: 'your_app_fingerprint'
    };
    
    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };
    
    // 定义文件接收回调函数
    this.fileCallback = (p2pFile: wearEngine.P2pFile) => {
      console.info('Received file from wear device');
      
      if (p2pFile.file) {
        console.info('File received successfully');
        // 处理接收到的文件
      }
      
      if (p2pFile.progress) {
        console.info(`File transfer progress: ${p2pFile.progress}%`);
      }
    };
    
    try {
      await this.p2pClient.registerFileReceiver(
        this.targetDevice.randomId,
        appParam,
        this.fileCallback
      );
      console.info('Succeeded in registering file receiver');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to register file receiver. Code: ${err.code}, message: ${err.message}`);
    }
  }
  
  /**
   * 取消文件接收监听
   */
  async unregisterFileReceiver(): Promise<void> {
    if (!this.p2pClient || !this.targetDevice || !this.fileCallback) {
      console.error('P2pClient, target device or file callback not initialized');
      return;
    }
    
    // 构造应用参数
    let appInfo: wearEngine.AppInfo = {
      bundleName: 'com.example.wearapp',
      fingerprint: 'your_app_fingerprint'
    };
    
    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };
    
    try {
      await this.p2pClient.unregisterFileReceiver(
        this.targetDevice.randomId,
        appParam,
        this.fileCallback
      );
      console.info('Succeeded in unregistering file receiver');
      this.fileCallback = null;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to unregister file receiver. Code: ${err.code}, message: ${err.message}`);
    }
  }
  
  build() {
    Column() {
      Text('P2P消息通信示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });
      
      // 设备信息
      if (this.targetDevice) {
        Text(`目标设备: ${this.targetDevice.name}`)
          .fontSize(16)
          .margin({ bottom: 10 });
      }
      
      // 发送消息
      TextInput({ placeholder: '输入消息内容（最大4096字节）' })
        .width('80%')
        .height(40)
        .onChange((value: string) => {
          this.messageText = value;
        })
        .margin({ bottom: 10 });
      
      Button('发送消息')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.sendMessage('com.example.wearapp', 'your_app_fingerprint');
        })
        .margin({ bottom: 20 });
      
      // 发送文件
      TextInput({ placeholder: '输入文件路径' })
        .width('80%')
        .height(40)
        .onChange((value: string) => {
          this.filePath = value;
        })
        .margin({ bottom: 10 });
      
      Button('发送文件')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.transferFile('com.example.wearapp', 'your_app_fingerprint');
        })
        .margin({ bottom: 10 });
      
      if (this.transferProgress > 0) {
        Text(`传输进度: ${this.transferProgress}%`)
          .fontSize(14)
          .margin({ bottom: 10 });
        
        Button('取消传输')
          .width('80%')
          .height(40)
          .onClick(() => {
            this.cancelFileTransfer('com.example.wearapp', 'your_app_fingerprint');
          })
          .margin({ bottom: 20 });
      }
      
      // 接收消息
      if (this.receivedMessage) {
        Text('接收到的消息:')
          .fontSize(16)
          .margin({ top: 20, bottom: 10 });
        
        Text(this.receivedMessage)
          .fontSize(14)
          .margin({ bottom: 20 });
      }
      
      // 检测应用安装状态
      Button('检测应用安装状态')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.checkAppInstalled('com.example.wearapp');
        })
        .margin({ bottom: 10 });
      
      // 拉起设备应用
      Button('拉起穿戴设备应用')
        .width('80%')
        .height(40)
        .onClick(() => {
          this.startRemoteApp('com.example.wearapp');
        })
        .margin({ bottom: 10 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}