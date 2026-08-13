import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'TLSClient';

class SocketInfo {
  public message: ArrayBuffer = new ArrayBuffer(1);
  public remoteInfo: socket.SocketRemoteInfo = {} as socket.SocketRemoteInfo;
}

export class TLSClientExample {
  private tlsSocket: socket.TLSSocket | null = null;
  private isConnected: boolean = false;

  async connect(
    serverIP: string,
    serverPort: number,
    localIP: string,
    localPort: number,
    caCert: string,
    clientKey?: string,
    clientCert?: string,
    keyPassword?: string
  ): Promise<void> {
    try {
      this.tlsSocket = socket.constructTLSSocketInstance();
      
      let ipAddress: socket.NetAddress = {
        address: localIP,
        port: localPort
      };
      
      await this.tlsSocket.bind(ipAddress);
      hilog.info(DOMAIN, TAG, 'Bound to ' + localIP + ':' + localPort);
      
      this.subscribeEvents();
      
      let serverAddress: socket.NetAddress = {
        address: serverIP,
        port: serverPort
      };
      
      let tlsSecureOption: socket.TLSSecureOptions = {} as socket.TLSSecureOptions;
      tlsSecureOption.ca = [caCert];
      tlsSecureOption.protocols = [socket.Protocol.TLSv12];
      tlsSecureOption.useRemoteCipherPrefer = true;
      tlsSecureOption.signatureAlgorithms = "rsa_pss_rsae_sha256:ECDSA+SHA256";
      tlsSecureOption.cipherSuite = "AES256-SHA256";
      
      if (clientKey && clientCert) {
        tlsSecureOption.key = clientKey;
        tlsSecureOption.cert = clientCert;
        if (keyPassword) {
          tlsSecureOption.password = keyPassword;
        }
        hilog.info(DOMAIN, TAG, 'Using two-way TLS authentication');
      } else {
        hilog.info(DOMAIN, TAG, 'Using one-way TLS authentication');
      }
      
      let tlsConnectOption: socket.TLSConnectOptions = {
        address: serverAddress,
        secureOptions: tlsSecureOption,
        ALPNProtocols: ["http/1.1"]
      };
      
      await this.tlsSocket.connect(tlsConnectOption);
      this.isConnected = true;
      hilog.info(DOMAIN, TAG, 'TLS connection established');
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'TLS connect failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  private subscribeEvents(): void {
    if (!this.tlsSocket) return;
    
    this.tlsSocket.on('message', (value: SocketInfo) => {
      hilog.info(DOMAIN, TAG, 'Received encrypted message');
      
      let buffer = value.message;
      let dataView = new DataView(buffer);
      let str = '';
      for (let i = 0; i < dataView.byteLength; ++i) {
        str += String.fromCharCode(dataView.getUint8(i));
      }
      
      hilog.info(DOMAIN, TAG, 'Message: ' + str);
      hilog.info(DOMAIN, TAG, 'From: ' + value.remoteInfo.address + ':' + value.remoteInfo.port);
    });
    
    this.tlsSocket.on('connect', () => {
      hilog.info(DOMAIN, TAG, 'TLS connected');
      this.isConnected = true;
    });
    
    this.tlsSocket.on('close', () => {
      hilog.info(DOMAIN, TAG, 'TLS connection closed');
      this.isConnected = false;
    });
    
    this.tlsSocket.on('error', (err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'TLS error: ' + JSON.stringify(err));
      this.isConnected = false;
    });
  }

  async sendData(data: string): Promise<void> {
    if (!this.tlsSocket || !this.isConnected) {
      hilog.error(DOMAIN, TAG, 'TLS socket is not connected');
      throw new Error('TLS socket is not connected');
    }
    
    try {
      await this.tlsSocket.send(data);
      hilog.info(DOMAIN, TAG, 'Encrypted data sent: ' + data);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Send failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  async close(): Promise<void> {
    if (!this.tlsSocket) return;
    
    try {
      await this.tlsSocket.close();
      
      this.tlsSocket.off('message');
      this.tlsSocket.off('connect');
      this.tlsSocket.off('close');
      this.tlsSocket.off('error');
      
      this.isConnected = false;
      this.tlsSocket = null;
      hilog.info(DOMAIN, TAG, 'TLS socket closed successfully');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Close failed: ' + JSON.stringify(err));
      throw err;
    }
  }
}

async function main(): Promise<void> {
  let tlsClient = new TLSClientExample();
  
  try {
    await tlsClient.connect(
      '192.168.1.200',
      1234,
      '192.168.1.100',
      4512,
      'CA_CERT_CONTENT_HERE',
      'CLIENT_KEY_CONTENT_HERE',
      'CLIENT_CERT_CONTENT_HERE',
      'KEY_PASSWORD_HERE'
    );
    
    await tlsClient.sendData('Hello, TLS Server!');
    
    setTimeout(async () => {
      await tlsClient.sendData('Second encrypted message');
    }, 5000);
    
    setTimeout(async () => {
      await tlsClient.close();
    }, 30 * 1000);
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Error occurred: ' + JSON.stringify(error));
  }
}

main();