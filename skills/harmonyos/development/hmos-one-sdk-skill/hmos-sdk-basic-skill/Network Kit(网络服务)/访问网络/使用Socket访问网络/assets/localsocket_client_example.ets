import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'LocalSocketClient';

export class LocalSocketClientExample {
  private client: socket.LocalSocket | null = null;
  private isConnected: boolean = false;

  async connect(socketPath: string): Promise<void> {
    try {
      this.client = socket.constructLocalSocketInstance();
      
      this.subscribeEvents();
      
      let localAddress: socket.LocalAddress = {
        address: socketPath
      };
      
      let connectOpt: socket.LocalConnectOptions = {
        address: localAddress,
        timeout: 6000
      };
      
      await this.client.connect(connectOpt);
      this.isConnected = true;
      hilog.info(DOMAIN, TAG, 'Connected to server: ' + socketPath);
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Connect failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  private subscribeEvents(): void {
    if (!this.client) return;
    
    this.client.on('message', (value: socket.LocalSocketMessageInfo) => {
      hilog.info(DOMAIN, TAG, 'Received message');
      
      const uintArray = new Uint8Array(value.message);
      let messageView = '';
      for (let i = 0; i < uintArray.length; i++) {
        messageView += String.fromCharCode(uintArray[i]);
      }
      
      hilog.info(DOMAIN, TAG, 'Message: ' + messageView);
      hilog.info(DOMAIN, TAG, 'Total receive: ' + JSON.stringify(value));
    });
    
    this.client.on('connect', () => {
      hilog.info(DOMAIN, TAG, 'Connected');
      this.isConnected = true;
    });
    
    this.client.on('close', () => {
      hilog.info(DOMAIN, TAG, 'Connection closed');
      this.isConnected = false;
    });
    
    this.client.on('error', (err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'Socket error: ' + JSON.stringify(err));
      this.isConnected = false;
    });
  }

  async sendData(data: string): Promise<void> {
    if (!this.client || !this.isConnected) {
      hilog.error(DOMAIN, TAG, 'Socket is not connected');
      throw new Error('Socket is not connected');
    }
    
    try {
      let sendOpt: socket.LocalSendOptions = {
        data: data
      };
      
      await this.client.send(sendOpt);
      hilog.info(DOMAIN, TAG, 'Data sent: ' + data);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Send failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  async close(): Promise<void> {
    if (!this.client) return;
    
    try {
      this.client.off('message');
      this.client.off('connect');
      this.client.off('close');
      this.client.off('error');
      
      await this.client.close();
      this.isConnected = false;
      this.client = null;
      hilog.info(DOMAIN, TAG, 'Client closed successfully');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Close failed: ' + JSON.stringify(err));
      throw err;
    }
  }
}

export async function startLocalSocketClientExample(context: common.UIAbilityContext): Promise<void> {
  let client = new LocalSocketClientExample();
  
  try {
    let socketPath = context.filesDir + '/testSocket';
    await client.connect(socketPath);
    
    await client.sendData('Hello from LocalSocket client!');
    
    setTimeout(async () => {
      await client.sendData('Second message from client');
    }, 5000);
    
    setTimeout(async () => {
      await client.close();
    }, 30 * 1000);
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Error occurred: ' + JSON.stringify(error));
  }
}