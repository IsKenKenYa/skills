import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'UDPExample';

export class UDPExample {
  private udpSocket: socket.UDPSocket | null = null;
  private isBound: boolean = false;

  async bindLocal(localIP: string, localPort: number): Promise<void> {
    try {
      this.udpSocket = socket.constructUDPSocketInstance();
      
      let bindAddr: socket.NetAddress = {
        address: localIP,
        port: localPort
      };
      
      await this.udpSocket.bind(bindAddr);
      this.isBound = true;
      hilog.info(DOMAIN, TAG, 'Bound to ' + localIP + ':' + localPort);
      
      this.subscribeEvents();
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Bind failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  private subscribeEvents(): void {
    if (!this.udpSocket) return;
    
    this.udpSocket.on('message', (value: socket.SocketMessageInfo) => {
      hilog.info(DOMAIN, TAG, 'Received message');
      
      let buffer = value.message;
      let dataView = new DataView(buffer);
      let str = '';
      for (let i = 0; i < dataView.byteLength; ++i) {
        str += String.fromCharCode(dataView.getUint8(i));
      }
      
      hilog.info(DOMAIN, TAG, 'Message: ' + str);
      hilog.info(DOMAIN, TAG, 'From: ' + value.remoteInfo.address + ':' + value.remoteInfo.port);
    });
    
    this.udpSocket.on('error', (err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'Socket error: ' + JSON.stringify(err));
    });
    
    this.udpSocket.on('close', () => {
      hilog.info(DOMAIN, TAG, 'Socket closed');
      this.isBound = false;
    });
  }

  async sendData(data: string, remoteIP: string, remotePort: number): Promise<void> {
    if (!this.udpSocket || !this.isBound) {
      hilog.error(DOMAIN, TAG, 'Socket is not bound');
      throw new Error('Socket is not bound');
    }
    
    try {
      let netAddress: socket.NetAddress = {
        address: remoteIP,
        port: remotePort
      };
      
      let sendOptions: socket.UDPSendOptions = {
        data: data,
        address: netAddress
      };
      
      await this.udpSocket.send(sendOptions);
      hilog.info(DOMAIN, TAG, 'Sent to ' + remoteIP + ':' + remotePort + ' - ' + data);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Send failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  async setExtraOptions(options: socket.UDPExtraOptions): Promise<void> {
    if (!this.udpSocket || !this.isBound) {
      hilog.error(DOMAIN, TAG, 'Socket is not bound');
      throw new Error('Socket is not bound');
    }
    
    try {
      await this.udpSocket.setExtraOptions(options);
      hilog.info(DOMAIN, TAG, 'Extra options set successfully');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Set extra options failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  async getState(): Promise<socket.SocketStateBase> {
    if (!this.udpSocket || !this.isBound) {
      throw new Error('Socket is not bound');
    }
    
    try {
      let state = await this.udpSocket.getState();
      hilog.info(DOMAIN, TAG, 'Socket state: ' + JSON.stringify(state));
      return state;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Get state failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  async close(): Promise<void> {
    if (!this.udpSocket) return;
    
    try {
      await this.udpSocket.close();
      
      this.udpSocket.off('message');
      this.udpSocket.off('error');
      this.udpSocket.off('close');
      
      this.isBound = false;
      this.udpSocket = null;
      hilog.info(DOMAIN, TAG, 'Socket closed successfully');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Close failed: ' + JSON.stringify(err));
      throw err;
    }
  }
}

async function main(): Promise<void> {
  let udp = new UDPExample();
  
  try {
    await udp.bindLocal('192.168.1.100', 1234);
    
    let extraOptions: socket.UDPExtraOptions = {
      receiveBufferSize: 8192,
      sendBufferSize: 8192,
      reuseAddress: true,
      socketTimeout: 6000,
      broadcast: true
    };
    await udp.setExtraOptions(extraOptions);
    
    await udp.sendData('Hello, UDP Server!', '192.168.1.200', 5678);
    
    let state = await udp.getState();
    hilog.info(DOMAIN, TAG, 'State: ' + JSON.stringify(state));
    
    setTimeout(async () => {
      await udp.close();
    }, 30 * 1000);
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Error occurred: ' + JSON.stringify(error));
  }
}

main();