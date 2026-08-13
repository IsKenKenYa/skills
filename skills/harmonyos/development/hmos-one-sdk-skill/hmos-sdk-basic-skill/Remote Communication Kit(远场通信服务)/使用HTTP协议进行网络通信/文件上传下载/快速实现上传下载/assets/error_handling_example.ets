import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';

class FileTransferErrorHandler {
  private maxRetries: number = 3;
  private retryDelay: number = 2000;
  
  async handleDownloadError(error: BusinessError, url: string, localPath: string): Promise<void> {
    switch (error.code) {
      case 1007900006:
        console.error('域名解析失败，请检查URL和网络连接');
        await this.retryWithDelay(url, localPath);
        break;
        
      case 1007900007:
        console.error('无法连接到服务器，请检查网络状态');
        await this.retryWithDelay(url, localPath);
        break;
        
      case 1007900028:
        console.error('操作超时，建议关闭Session后重新创建');
        break;
        
      case 1007900985:
        console.error('文件系统IO错误，请检查路径权限');
        this.checkAndRequestPermission();
        break;
        
      case 1007900994:
        console.error('Session数量达到限制，建议关闭已有Session');
        this.cleanUpSessions();
        break;
        
      case 1007900993:
        console.error('Session已关闭，需要重新创建');
        break;
        
      case 201:
        console.error('权限被拒绝，请检查应用权限配置');
        this.checkAndRequestPermission();
        break;
        
      default:
        console.error(`未知错误: ${error.message} (code: ${error.code})`);
    }
  }
  
  async handleUploadError(error: BusinessError, filePath: string, serverUrl: string): Promise<void> {
    switch (error.code) {
      case 1007900025:
        console.error('上传失败，可能文件过大或网络问题');
        const fileSize = this.getFileSize(filePath);
        if (fileSize > 100 * 1024 * 1024) {
          console.warn('文件超过100MB，建议使用流式传输');
          await this.useStreamUpload(filePath, serverUrl);
        }
        break;
        
      case 1007900026:
        console.error('无法读取文件，请检查应用文件读取权限');
        this.checkAndRequestPermission();
        break;
        
      case 1007900988:
        console.error('文件打开失败，请检查路径和权限');
        break;
        
      default:
        console.error(`上传失败: ${error.message}`);
    }
  }
  
  private async retryWithDelay(url: string, localPath: string): Promise<void> {
    for (let retryCount = 1; retryCount <= this.maxRetries; retryCount++) {
      console.warn(`第${retryCount}次重试...`);
      await new Promise(resolve => setTimeout(resolve, this.retryDelay));
      
      try {
        const session = rcp.createSession();
        const downloadToFile: rcp.DownloadToFile = {
          kind: 'folder',
          path: localPath
        };
        
        await session.downloadToFile(url, downloadToFile);
        console.info('重试成功');
        session.close();
        return;
        
      } catch (retryError) {
        const err = retryError as BusinessError;
        if (retryCount === this.maxRetries) {
          throw new Error(`网络连接失败，已达到最大重试次数 (${this.maxRetries})`);
        }
      }
    }
  }
  
  private async useStreamUpload(filePath: string, serverUrl: string): Promise<void> {
    console.info('使用流式上传...');
    
    const uploadFromStream: rcp.UploadFromStream = {
      stream: {
        async read(buffer: ArrayBuffer): Promise<number> {
          const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
          const bytesRead = await fileIo.read(file.fd, buffer);
          fileIo.closeSync(file.fd);
          return bytesRead;
        }
      }
    };
    
    const session = rcp.createSession();
    await session.uploadFromStream(serverUrl, uploadFromStream);
    session.close();
  }
  
  private getFileSize(filePath: string): number {
    try {
      const stat = fileIo.statSync(filePath);
      return stat.size;
    } catch (error) {
      console.error('无法获取文件大小');
      return 0;
    }
  }
  
  private checkAndRequestPermission(): void {
    console.warn('建议检查module.json5中的权限配置:');
    console.warn('  - ohos.permission.INTERNET (必需)');
    console.warn('  - ohos.permission.GET_NETWORK_INFO (如使用cellular模式)');
  }
  
  private cleanUpSessions(): void {
    console.warn('建议关闭不活跃的Session以释放资源');
    console.warn('Session数量上限为1024个 (5.1.0(18)版本起)');
  }
}

export { FileTransferErrorHandler };