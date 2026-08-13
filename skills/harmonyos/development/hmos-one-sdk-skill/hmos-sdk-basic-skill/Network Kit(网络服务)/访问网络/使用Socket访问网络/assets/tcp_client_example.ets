import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'TCPClient';

class SocketInfo {
  public message: ArrayBuffer = new ArrayBuffer(1);
  public remoteInfo: socket.SocketRemoteInfo = {} as socket.SocketRemoteInfo;
}

export class TCPClientExample {
  private tcpClient: socket.TCPSocket | null = null;
  private isConnected: boolean = false;

  async connect(serverIP: string, serverPort: number, localIP?: string, localPort?: number): Promise<void> {
    try {
      this.tcpClient = socket.constructTCPSocketInstance();
      
      this.subscribeEvents();
      
      if (localIP && localPort) {
        let localAddress: socket.NetAddress = {
          address: localIP,
          port: localPort
        };
        await this.bindLocal(localAddress);
      }
      
      let serverAddress: socket.NetAddress = {
        address: serverIP,
        port: serverPort
      };
      
      let tcpConnect: socket.TCPConnectOptions = {
        address: serverAddress,
        timeout: 6000
      };
      
      await this.tcpClient.connect(tcpConnect);
      this.isConnected = true;
      hilog.info(DOMAIN, TAG, 'Connected to server successfully');
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Connect failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  private subscribeEvents(): void {
    if (!this.tcpClient) return;
    
    this.tcpClient.on('message', (value: SocketInfo) => {
      hilog.info(DOMAIN, TAG, 'Received message');
      let buffer = value.message;
      let dataView = new DataView(buffer);
      let str = '';
      for (let i = 0; i < dataView.byteLength; ++i) {
        str += String.fromCharCode(dataView.getUint8(i));
      }
      hilog.info(DOMAIN, TAG, 'Message content: ' + str);
      hilog.info(DOMAIN, TAG, 'From: ' + value.remoteInfo.address + ':' + value.remoteInfo.port);
    });
    
    this.tcpClient.on('connect', () => {
      hilog.info(DOMAIN, TAG, 'Connection established');
    });
    
    this.tcpClient.on('close', () => {
      hilog.info(DOMAIN, TAG, 'Connection closed');
      this.isConnected = false;
    });
    
    this.tcpClient.on('error', (err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'Socket error: ' + JSON.stringify(err));
      this.isConnected = false;
    });
  }

  private async bindLocal(address: socket.NetAddress): Promise<void> {
    if (!this.tcpClient) return;
    
    try {
      await this.tcpClient.bind(address);
      hilog.info(DOMAIN, TAG, 'Bound to local address: ' + address.address + ':' + address.port);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Bind failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  async sendData(data: string): Promise<void> {
    if (!this.tcpClient || !this.isConnected) {
      hilog.error(DOMAIN, TAG, 'Socket is not connected');
      throw new Error('Socket is not connected');
    }
    
    try {
      let tcpSendOptions: socket.TCPSendOptions = {
        data: data
      };
      await this.tcpClient.send(tcpSendOptions);
      hilog.info(DOMAIN, TAG, 'Data sent successfully: ' + data);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Send failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  async close(): Promise<void> {
    if (!this.tcpClient) return;
    
    try {
      await this.tcpClient.close();
      hilog.info(DOMAIN, TAG, 'Socket closed successfully');
      
      this.tcpClient.off('message');
      this.tcpClient.off('connect');
      this.tcpClient.off('close');
      this.tcpClient.off('error');
      
      this.isConnected = false;
      this.tcpClient = null;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Close failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  getState(): Promise<socket.SocketStateBase> {
    if (!this.tcpClient) {
      throw new Error('Socket is not initialized');
    }
    return this.tcpClient.getState();
  }
}

async function main(): Promise<void> {
  let client = new TCPClientExample();
  
  try {
    await client.connect('192.168.1.200', 5678, '192.168.1.100', 1234);
    
    await client.sendData('Hello, Server!');
    
    let state = await client.getState();
    hilog.info(DOMAIN, TAG, 'Socket state: ' + JSON.stringify(state));
    
    setTimeout(async () => {
      await client.close();
    }, 30 * 1000);
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Error occurred: ' + JSON.stringify(error));
  }
}

main();