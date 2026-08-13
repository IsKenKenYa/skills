import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'TLSServer';

class SocketInfo {
  public message: ArrayBuffer = new ArrayBuffer(1);
  public remoteInfo: socket.SocketRemoteInfo = {} as socket.SocketRemoteInfo;
}

export class TLSServerExample {
  private tlsServer: socket.TLSSocketServer | null = null;
  private clientConnections: Map<string, socket.TLSSocketConnection> = new Map();
  private isListening: boolean = false;

  async startServer(
    serverIP: string,
    serverPort: number,
    serverKey: string,
    serverCert: string,
    caCert: string,
    keyPassword?: string
  ): Promise<void> {
    try {
      this.tlsServer = socket.constructTLSSocketServerInstance();
      
      let netAddress: socket.NetAddress = {
        address: serverIP,
        port: serverPort
      };
      
      let tlsSecureOptions: socket.TLSSecureOptions = {
        key: serverKey,
        cert: serverCert,
        ca: [caCert],
        protocols: socket.Protocol.TLSv12,
        useRemoteCipherPrefer: true,
        signatureAlgorithms: "rsa_pss_rsae_sha256:ECDSA+SHA256",
        cipherSuite: "AES256-SHA256"
      };
      
      if (keyPassword) {
        tlsSecureOptions.password = keyPassword;
      }
      
      let tlsConnectOptions: socket.TLSConnectOptions = {
        address: netAddress,
        secureOptions: tlsSecureOptions,
        ALPNProtocols: ["http/1.1"]
      };
      
      await this.tlsServer.listen(tlsConnectOptions);
      this.isListening = true;
      hilog.info(DOMAIN, TAG, 'TLS server started on ' + serverIP + ':' + serverPort);
      
      this.subscribeServerEvents();
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Start TLS server failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  private subscribeServerEvents(): void {
    if (!this.tlsServer) return;
    
    this.tlsServer.on('connect', (client: socket.TLSSocketConnection) => {
      let clientId = client.toString();
      hilog.info(DOMAIN, TAG, 'TLS client connected: ' + clientId);
      
      this.clientConnections.set(clientId, client);
      this.subscribeClientEvents(client, clientId);
    });
    
    this.tlsServer.on('error', (err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'TLS server error: ' + JSON.stringify(err));
    });
  }

  private subscribeClientEvents(client: socket.TLSSocketConnection, clientId: string): void {
    let messageCallback = (value: SocketInfo) => {
      hilog.info(DOMAIN, TAG, 'Received encrypted message from client: ' + clientId);
      
      let messageView = '';
      for (let i: number = 0; i < value.message.byteLength; i++) {
        let uint8Array = new Uint8Array(value.message);
        let message = String.fromCharCode(uint8Array[i]);
        messageView += message;
      }
      
      hilog.info(DOMAIN, TAG, 'Message: ' + messageView);
      hilog.info(DOMAIN, TAG, 'Remote info: ' + JSON.stringify(value.remoteInfo));
      
      this.sendToClient(clientId, 'TLS Server response: ' + messageView);
    };
    
    client.on('message', messageCallback);
    
    client.on('error', (err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'TLS client error: ' + clientId + ' - ' + JSON.stringify(err));
      this.clientConnections.delete(clientId);
    });
    
    client.on('close', () => {
      hilog.info(DOMAIN, TAG, 'TLS client closed: ' + clientId);
      this.clientConnections.delete(clientId);
    });
  }

  async sendToClient(clientId: string, data: string): Promise<void> {
    let client = this.clientConnections.get(clientId);
    if (!client) {
      hilog.error(DOMAIN, TAG, 'TLS client not found: ' + clientId);
      throw new Error('TLS client not found');
    }
    
    try {
      await client.send(data);
      hilog.info(DOMAIN, TAG, 'Sent to TLS client: ' + clientId + ' - ' + data);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Send to TLS client failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  async closeClient(clientId: string): Promise<void> {
    let client = this.clientConnections.get(clientId);
    if (!client) {
      hilog.error(DOMAIN, TAG, 'TLS client not found: ' + clientId);
      return;
    }
    
    try {
      await client.close();
      client.off('message');
      client.off('error');
      client.off('close');
      this.clientConnections.delete(clientId);
      hilog.info(DOMAIN, TAG, 'TLS client closed: ' + clientId);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Close TLS client failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  async stopServer(): Promise<void> {
    if (!this.tlsServer) return;
    
    try {
      for (let [clientId, client] of this.clientConnections) {
        await this.closeClient(clientId);
      }
      
      this.tlsServer.off('connect');
      this.tlsServer.off('error');
      
      await this.tlsServer.close();
      this.isListening = false;
      this.tlsServer = null;
      hilog.info(DOMAIN, TAG, 'TLS server stopped');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Stop TLS server failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  getConnectedClientCount(): number {
    return this.clientConnections.size;
  }
}

async function main(): Promise<void> {
  let tlsServer = new TLSServerExample();
  
  try {
    await tlsServer.startServer(
      '192.168.1.100',
      8080,
      'SERVER_KEY_CONTENT_HERE',
      'SERVER_CERT_CONTENT_HERE',
      'CA_CERT_CONTENT_HERE',
      'KEY_PASSWORD_HERE'
    );
    
    hilog.info(DOMAIN, TAG, 'TLS server is running, waiting for clients...');
    
    setTimeout(() => {
      hilog.info(DOMAIN, TAG, 'Connected TLS clients: ' + tlsServer.getConnectedClientCount());
    }, 10 * 1000);
    
    setTimeout(async () => {
      await tlsServer.stopServer();
    }, 60 * 1000);
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Error occurred: ' + JSON.stringify(error));
  }
}

main();