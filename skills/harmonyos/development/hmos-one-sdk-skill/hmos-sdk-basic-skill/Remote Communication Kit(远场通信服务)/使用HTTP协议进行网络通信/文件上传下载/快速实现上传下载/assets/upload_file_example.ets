import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';

const UPLOAD_FILE_PATH = '/data/storage/el1/bundle/entry_test/resources/resfile/upload_file.txt';
const UPLOAD_URL = 'https://httpbin.org/anything';

class FdReadFile {
  readonly fd: number;
  
  constructor(fd: number) {
    this.fd = fd;
  }
  
  async read(buffer: ArrayBuffer): Promise<number> {
    return fileIo.read(this.fd, buffer);
  }
}

let SESSION_CONFIG: rcp.SessionConfiguration = {
  requestConfiguration: {
    transfer: {
      timeout: {
        connectMs: 6000
      }
    },
    security: {
      remoteValidation: 'skip',
      tlsOptions: {
        tlsVersion: 'TlsV1.3'
      }
    }
  }
};

async function uploadFile(): Promise<void> {
  const session = rcp.createSession(SESSION_CONFIG);
  
  try {
    const file = fileIo.openSync(UPLOAD_FILE_PATH, fileIo.OpenMode.READ_ONLY);
    
    if (!file) {
      console.error('fileIo.openSync failed');
      return;
    }
    
    const fdReadFile = new FdReadFile(file.fd);
    const buffer = new ArrayBuffer(1024 * 1024);
    await fdReadFile.read(buffer);
    
    const response = await session.uploadFromFile(UPLOAD_URL, new rcp.UploadFromFile(fdReadFile));
    console.info(`Upload succeeded: statusCode ${response.statusCode}`);
    
    fileIo.closeSync(file.fd);
    
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Upload failed: error code is ${error.code}, error data is ${error.data}`);
    
    switch (error.code) {
      case 1007900025:
        console.error('上传失败，可能文件过大或网络问题');
        break;
      case 1007900026:
        console.error('无法读取文件，请检查应用文件读取权限');
        break;
      case 1007900988:
        console.error('文件打开失败，请检查路径和权限');
        break;
      default:
        console.error(`上传失败: ${error.message}`);
    }
  } finally {
    session.close();
  }
}

uploadFile();