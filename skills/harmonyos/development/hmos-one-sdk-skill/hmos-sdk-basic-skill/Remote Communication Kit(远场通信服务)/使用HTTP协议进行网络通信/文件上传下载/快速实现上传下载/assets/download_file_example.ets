import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';

const DOWNLOAD_TO_PATH = '/data/storage/el2/base/haps/entry/files';
const DOWNLOAD_URL = 'https://example.com/test.png';

const securityConfig: rcp.SecurityConfiguration = {
  remoteValidation: 'skip'
};

const downloadToFile: rcp.DownloadToFile = {
  kind: 'folder',
  path: DOWNLOAD_TO_PATH
};

const session = rcp.createSession({
  requestConfiguration: {
    transfer: { 
      timeout: { 
        connectMs: 6000, 
        transferMs: 60000, 
        inactivityMs: 6000 
      } 
    },
    security: securityConfig
  }
});

async function downloadFile(): Promise<void> {
  try {
    if (fileIo.accessSync(DOWNLOAD_TO_PATH)) {
      fileIo.rmdirSync(DOWNLOAD_TO_PATH);
    }
    
    const response = await session.downloadToFile(DOWNLOAD_URL, downloadToFile);
    console.info(`Successfully downloaded the file, statusCode: ${JSON.stringify(response.statusCode)}`);
    
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Failed to download, the error code is ${error.code}, error data is ${error.data}`);
    
    switch (error.code) {
      case 1007900006:
        console.error('域名解析失败，请检查URL和网络连接');
        break;
      case 1007900007:
        console.error('无法连接到服务器，请检查网络状态');
        break;
      case 1007900028:
        console.error('操作超时，建议关闭Session后重新创建');
        break;
      case 1007900985:
        console.error('文件系统IO错误，请检查路径权限');
        break;
      default:
        console.error(`下载失败: ${error.message}`);
    }
  } finally {
    session.close();
  }
}

downloadFile();