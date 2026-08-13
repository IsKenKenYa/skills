import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'MulticastExample';

class SocketInfo {
  public message: ArrayBuffer = new ArrayBuffer(1);
  public remoteInfo: socket.SocketRemoteInfo = {} as socket.SocketRemoteInfo;
}

export class MulticastExample {
  private multicast: socket.MulticastSocket | null = null;
  private isInGroup: boolean = false;
  private groupAddress: socket.NetAddress | null = null;

  async joinGroup(groupIP: string, groupPort: number): Promise<void> {
    try {
      this.multicast = socket.constructMulticastSocketInstance();
      
      this.groupAddress = {
        address: groupIP,
        port: groupPort,
        family: 1
      };
      
      await this.multicast.addMembership(this.groupAddress);
      this.isInGroup = true;
      hilog.info(DOMAIN, TAG, 'Joined multicast group: ' + groupIP + ':' + groupPort);
      
      this.subscribeEvents();
      
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Join group failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  private subscribeEvents(): void {
    if (!this.multicast) return;
    
    this.multicast.on('message', (data: SocketInfo) => {
      hilog.info(DOMAIN, TAG, 'Received multicast message');
      
      const uintArray = new Uint8Array(data.message);
      let str = '';
      for (let i = 0; i < uintArray.length; ++i) {
        str += String.fromCharCode(uintArray[i]);
      }
      
      hilog.info(DOMAIN, TAG, 'Message: ' + str);
      hilog.info(DOMAIN, TAG, 'From: ' + data.remoteInfo.address + ':' + data.remoteInfo.port);
      hilog.info(DOMAIN, TAG, 'Remote info: ' + JSON.stringify(data.remoteInfo));
    });
    
    this.multicast.on('error', (err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'Multicast error: ' + JSON.stringify(err));
    });
  }

  async sendToGroup(data: string): Promise<void> {
    if (!this.multicast || !this.isInGroup || !this.groupAddress) {
      hilog.error(DOMAIN, TAG, 'Not in multicast group');
      throw new Error('Not in multicast group');
    }
    
    try {
      await this.multicast.send({
        data: data,
        address: this.groupAddress
      });
      hilog.info(DOMAIN, TAG, 'Sent to group: ' + data);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Send to group failed: ' + JSON.stringify(err));
      throw err;
    }
  }

  async leaveGroup(): Promise<void> {
    if (!this.multicast || !this.isInGroup || !this.groupAddress) {
      hilog.error(DOMAIN, TAG, 'Not in multicast group');
      return;
    }
    
    try {
      this.multicast.off('message');
      this.multicast.off('error');
      
      await this.multicast.dropMembership(this.groupAddress);
      this.isInGroup = false;
      this.groupAddress = null;
      this.multicast = null;
      hilog.info(DOMAIN, TAG, 'Left multicast group');
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.error(DOMAIN, TAG, 'Leave group failed: ' + JSON.stringify(err));
      throw err;
    }
  }
}

async function main(): Promise<void> {
  let multicast = new MulticastExample();
  
  try {
    await multicast.joinGroup('239.255.0.1', 32123);
    
    setTimeout(async () => {
      await multicast.sendToGroup('Hello multicast group!');
    }, 1000);
    
    setTimeout(async () => {
      await multicast.sendToGroup('Multicast test message');
    }, 5000);
    
    setTimeout(async () => {
      await multicast.leaveGroup();
      hilog.info(DOMAIN, TAG, 'Multicast example finished');
    }, 30 * 1000);
    
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Error occurred: ' + JSON.stringify(error));
  }
}

main();