import { socket } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'LocalSocketServer';

export class LocalSocketServerExample {
  private server: socket.LocalSocketServer | null = null;
  private clientConnections: Map<string, socket.LocalSocketConnection> = new Map();
  private isListening: boolean = false;

  async startServer(socketPath: string): Promise<void> {
    try {
      this.server = socket.constructLocalSocketServerInstance();
      
      let listenAddr: socket.LocalAddress = {
        address: socketPath
      };
      
      await this.server.listen(listenAddr);
      this.isListening = true;
      hilog.info(DOMAIN, TAG, 'Server started on: ' + socketPath);
      
      this.subscribeServerEvents();
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Start server failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  private subscribeServerEvents(): void {
    if (!this.server) return;
    
    this.server.on('connect', (connection: socket.LocalSocketConnection) => {
      let clientId = connection.toString();
      hilog.info(DOMAIN, TAG, 'Client connected: ' + clientId);
      
      this.clientConnections.set(clientId, connection);
      this.subscribeClientEvents(connection, clientId);
    });
    
    this.server.on('error', (err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'Server error: ' + JSON.stringify(err));
    });
  }

  private subscribeClientEvents(connection: socket.LocalSocketConnection, clientId: string): void {
    connection.on('message', (value: socket.LocalSocketMessageInfo) => {
      hilog.info(DOMAIN, TAG, 'Received message from client: ' + clientId);
      
      const uintArray = new Uint8Array(value.message);
      let messageView = '';
      for (let i = 0; i < uintArray.length; i++) {
        messageView += String.fromCharCode(uintArray[i]);
      }
      
      hilog.info(DOMAIN, TAG, 'Message: ' + messageView);
      
      this.sendToClient(clientId, 'Server response: ' + messageView);
    });
    
    connection.on('error', (err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'Client error: ' + clientId + ' - ' + JSON.stringify(err));
      this.clientConnections.delete(clientId);
    });
    
    connection.on('close', () => {
      hilog.info(DOMAIN, TAG, 'Client closed: ' + clientId);
      this.clientConnections.delete(clientId);
    });
  }

  async sendToClient(clientId: string, data: string): Promise<void> {
    let connection = this.clientConnections.get(clientId);
    if (!connection) {
      hilog.error(DOMAIN, TAG, 'Client not found: ' + clientId);
      throw new Error('Client not found');
    }
    
    try {
      let sendOpt: socket.LocalSendOptions = {
        data: data
      };
      
      await connection.send(sendOpt);
      hilog.info(DOMAIN, TAG, 'Sent to client: ' + clientId + ' - ' + data);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Send to client failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  async closeClient(clientId: string): Promise<void> {
    let connection = this.clientConnections.get(clientId);
    if (!connection) {
      hilog.error(DOMAIN, TAG, 'Client not found: ' + clientId);
      return;
    }
    
    try {
      connection.off('message');
      connection.off('error');
      connection.off('close');
      
      await connection.close();
      this.clientConnections.delete(clientId);
      hilog.info(DOMAIN, TAG, 'Client closed: ' + clientId);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Close client failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  async stopServer(): Promise<void> {
    if (!this.server) return;
    
    try {
      for (let [clientId, connection] of this.clientConnections) {
        await this.closeClient(clientId);
      }
      
      this.server.off('connect');
      this.server.off('error');
      
      await this.server.close();
      this.isListening = false;
      this.server = null;
      hilog.info(DOMAIN, TAG, 'Server stopped');
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

export async function startLocalSocketServerExample(context: common.UIAbilityContext): Promise<void> {
  let server = new LocalSocketServerExample();
  
  try {
    let socketPath = context.filesDir + '/testSocket';
    await server.startServer(socketPath);
    
    hilog.info(DOMAIN, TAG, 'Server is running, waiting for clients...');
    
    setTimeout(() => {
      hilog.info(DOMAIN, TAG, 'Connected clients: ' + server.getConnectedClientCount());
    }, 10 * 1000);
    
    setTimeout(async () => {
      await server.stopServer();
    }, 60 * 1000);
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Error occurred: ' + JSON.stringify(error));
  }
}