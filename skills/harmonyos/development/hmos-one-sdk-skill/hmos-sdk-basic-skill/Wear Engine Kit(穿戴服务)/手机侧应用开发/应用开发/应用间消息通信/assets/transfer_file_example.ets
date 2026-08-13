/**
 * 文件传输示例
 * 仅包含文件传输功能
 */

import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';

export class FileTransfer {
  private p2pClient: wearEngine.P2pClient;
  private targetDevice: wearEngine.Device;
  private bundleName: string;
  private fingerprint: string;
  private currentProgress: number = 0;
  
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
   * 发送文件到穿戴设备
   * @param filePath 文件路径（最大100MB）
   * @returns Promise<boolean> 发送是否成功
   */
  async sendFile(filePath: string): Promise<boolean> {
    // 构造应用参数
    let appInfo: wearEngine.AppInfo = {
      bundleName: this.bundleName,
      fingerprint: this.fingerprint
    };
    
    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };
    
    // 检查文件大小
    try {
      let stat = fileIo.statSync(filePath);
      let fileSize = stat.size;
      
      if (fileSize > 100 * 1024 * 1024) { // 100MB
        console.error('File size exceeds 100MB limit');
        return false;
      }
    } catch (error) {
      console.error('Failed to get file size');
      return false;
    }
    
    // 打开文件
    let p2pFile: wearEngine.P2pFile;
    try {
      p2pFile = {
        file: fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
      };
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to open file. Code: ${err.code}, message: ${err.message}`);
      return false;
    }
    
    // 发送文件并监听传输进度
    try {
      await new Promise<void>((resolve, reject) => {
        this.p2pClient.transferFile(
          this.targetDevice.randomId,
          appParam,
          p2pFile,
          (error: BusinessError, p2pResult: wearEngine.P2pResult) => {
            if (error) {
              this.handleTransferError(error);
              reject(error);
              return;
            }
            
            if (p2pResult.code) {
              if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
                console.info('Succeeded in transferring file');
                this.currentProgress = 100;
                resolve();
              } else {
                console.error(`Failed to transfer file, result code: ${p2pResult.code}`);
                reject(new Error(`Transfer failed with code ${p2pResult.code}`));
              }
            }
            
            if (p2pResult.progress) {
              this.currentProgress = p2pResult.progress;
              console.info(`Transfer progress: ${this.currentProgress}%`);
            }
          }
        );
      });
      
      return true;
    } catch (error) {
      console.error('File transfer failed');
      return false;
    } finally {
      // 关闭文件
      try {
        fileIo.close(p2pFile.file);
      } catch (error) {
        console.error('Failed to close file');
      }
    }
  }
  
  /**
   * 取消文件传输
   * @param filePath 文件路径
   * @returns Promise<boolean> 取消是否成功
   */
  async cancelTransfer(filePath: string): Promise<boolean> {
    // 构造应用参数
    let appInfo: wearEngine.AppInfo = {
      bundleName: this.bundleName,
      fingerprint: this.fingerprint
    };
    
    let appParam: wearEngine.P2pAppParam = {
      remoteApp: appInfo
    };
    
    // 打开文件
    let p2pFile: wearEngine.P2pFile;
    try {
      p2pFile = {
        file: fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
      };
    } catch (error) {
      console.error('Failed to open file');
      return false;
    }
    
    try {
      let p2pResult = await this.p2pClient.cancelFileTransfer(
        this.targetDevice.randomId,
        appParam,
        p2pFile
      );
      
      if (p2pResult.code === wearEngine.P2pResultCode.COMMUNICATION_SUCCESS) {
        console.info('Succeeded in cancelling file transfer');
        this.currentProgress = 0;
        return true;
      } else {
        console.error('Failed to cancel file transfer');
        return false;
      }
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Failed to cancel file transfer. Code: ${err.code}, message: ${err.message}`);
      return false;
    } finally {
      // 关闭文件
      try {
        fileIo.close(p2pFile.file);
      } catch (error) {
        console.error('Failed to close file');
      }
    }
  }
  
  /**
   * 处理传输错误
   */
  private handleTransferError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        console.error('Parameter error: Check file path and parameters');
        break;
      case 1008500001:
        console.error('Network error: Check network connection');
        break;
      case 1008500003:
        console.error('Device disconnected: Reconnect device');
        break;
      case 1008500011:
        console.error('File is invalid: Check file exists and accessible');
        break;
      default:
        console.error(`Unknown error: ${error.code}`);
    }
  }
  
  /**
   * 获取当前传输进度
   */
  getProgress(): number {
    return this.currentProgress;
  }
}

// 使用示例
async function fileTransferExample(): void {
  // 初始化FileTransfer
  let deviceClient = wearEngine.getDeviceClient(context);
  let deviceList = await deviceClient.getConnectedDevices();
  let targetDevice = deviceList[0];
  
  let fileTransfer = new FileTransfer(
    context,
    targetDevice,
    'com.example.wearapp',
    'your_app_fingerprint'
  );
  
  // 发送文件
  let filePath = '/data/local/tmp/test.txt';
  let success = await fileTransfer.sendFile(filePath);
  
  if (success) {
    console.info('File sent successfully');
  } else {
    console.error('Failed to send file');
    
    // 如果传输失败，可以取消传输
    await fileTransfer.cancelTransfer(filePath);
  }
  
  // 监听传输进度
  let progress = fileTransfer.getProgress();
  console.info(`Current progress: ${progress}%`);
}