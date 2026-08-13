import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'TCPServer';

class SocketInfo {
  public message: ArrayBuffer = new ArrayBuffer(1);
  public remoteInfo: socket.SocketRemoteInfo = {} as socket.SocketRemoteInfo;
}

export class TCPServerExample {
  private tcpServer: socket.TCPSocketServer | null = null;
  private clientConnections: Map<string, socket.TCPSocketConnection> = new Map();

  async startServer(localIP: string, localPort: number): Promise<void> {
    try {
      this.tcpServer = socket.constructTCPSocketServerInstance();
      
      let ipAddress: socket.NetAddress = {
        address: localIP,
        port: localPort
      };
      
      await this.tcpServer.listen(ipAddress);
      hilog.info(DOMAIN, TAG, 'Server started on ' + localIP + ':' + localPort);
      
      this.subscribeServerEvents();
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Start server failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  private subscribeServerEvents(): void {
    if (!this.tcpServer) return;
    
    this.tcpServer.on('connect', (client: socket.TCPSocketConnection) => {
      let clientId = client.toString();
      hilog.info(DOMAIN, TAG, 'Client connected: ' + clientId);
      
      this.clientConnections.set(clientId, client);
      
      this.subscribeClientEvents(client, clientId);
    });
    
    this.tcpServer.on('error', (err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'Server error: ' + JSON.stringify(err));
    });
  }

  private subscribeClientEvents(client: socket.TCPSocketConnection, clientId: string): void {
    client.on('message', (value: SocketInfo) => {
      hilog.info(DOMAIN, TAG, 'Received message from client: ' + clientId);
      
      let buffer = value.message;
      let dataView = new DataView(buffer);
      let str = '';
      for (let i = 0; i < dataView.byteLength; ++i) {
        str += String.fromCharCode(dataView.getUint8(i));
      }
      
      hilog.info(DOMAIN, TAG, 'Message: ' + str);
      hilog.info(DOMAIN, TAG, 'Client address: ' + value.remoteInfo.address);
      hilog.info(DOMAIN, TAG, 'Client port: ' + value.remoteInfo.port);
      
      this.sendToClient(clientId, 'Server response: ' + str);
    });
    
    client.on('close', () => {
      hilog.info(DOMAIN, TAG, 'Client closed: ' + clientId);
      this.clientConnections.delete(clientId);
    });
    
    client.on('error', (err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'Client error: ' + clientId + ' - ' + JSON.stringify(err));
      this.clientConnections.delete(clientId);
    });
  }

  async sendToClient(clientId: string, data: string): Promise<void> {
    let client = this.clientConnections.get(clientId);
    if (!client) {
      hilog.error(DOMAIN, TAG, 'Client not found: ' + clientId);
      throw new Error('Client not found');
    }
    
    try {
      let tcpSendOptions: socket.TCPSendOptions = {
        data: data
      };
      await client.send(tcpSendOptions);
      hilog.info(DOMAIN, TAG, 'Sent to client: ' + clientId + ' - ' + data);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Send to client failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  async closeClient(clientId: string): Promise<void> {
    let client = this.clientConnections.get(clientId);
    if (!client) {
      hilog.error(DOMAIN, TAG, 'Client not found: ' + clientId);
      return;
    }
    
    try {
      await client.close();
      client.off('message');
      client.off('close');
      client.off('error');
      this.clientConnections.delete(clientId);
      hilog.info(DOMAIN, TAG, 'Client closed: ' + clientId);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Close client failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  async stopServer(): Promise<void> {
    if (!this.tcpServer) return;
    
    try {
      for (let [clientId, client] of this.clientConnections) {
        await this.closeClient(clientId);
      }
      
      this.tcpServer.off('connect');
      this.tcpServer.off('error');
      
      await this.tcpServer.close();
      hilog.info(DOMAIN, TAG, 'Server stopped');
      
      this.tcpServer = null;
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Stop server failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  getConnectedClientCount(): number {
    return this.clientConnections.size;
  }
}

async function main(): Promise<void> {
  let server = new TCPServerExample();
  
  try {
    await server.startServer('192.168.1.100', 4651);
    
    hilog.info(DOMAIN, TAG, 'Server is running, waiting for clients...');
    
    setTimeout(async () => {
      hilog.info(DOMAIN, TAG, 'Connected clients: ' + server.getConnectedClientCount());
      await server.stopServer();
    }, 60 * 1000);
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Error occurred: ' + JSON.stringify(error));
  }
}

main();