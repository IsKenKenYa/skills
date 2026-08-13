import { wifiManager } from '@kit.ConnectivityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'P2P_DiscoverConnect';
const DOMAIN = 0xFF00;

export class P2PDiscoverConnect {
  private targetDeviceName: string = '';
  
  async startDiscovery(): Promise<void> {
    try {
      if (!wifiManager.isWifiActive()) {
        hilog.error(DOMAIN, TAG, 'WiFi is not active, please enable WiFi first');
        return;
      }
      
      const recvP2pPeerDeviceChangeFunc = (result: wifiManager.WifiP2pDevice[]) => {
        hilog.info(DOMAIN, TAG, 'p2p peer device change receive event: %{public}s', JSON.stringify(result));
        
        wifiManager.getP2pPeerDevices((err, data) => {
          if (err) {
            hilog.error(DOMAIN, TAG, 'failed to get peer devices: %{public}s', JSON.stringify(err));
            return;
          }
          
          hilog.info(DOMAIN, TAG, 'get peer devices count: %{public}d', data.length);
          
          for (let i = 0; i < data.length; ++i) {
            hilog.info(DOMAIN, TAG, 'Device %{public}d: %{public}s (%{public}s)', 
              i, data[i].deviceName, data[i].deviceAddress);
            
            if (data[i].deviceName === this.targetDeviceName) {
              hilog.info(DOMAIN, TAG, 'Found target device: %{public}s', data[i].deviceAddress);
              this.connectToDevice(data[i].deviceAddress);
            }
          }
        });
      };
      
      wifiManager.on('p2pPeerDeviceChange', recvP2pPeerDeviceChangeFunc);
      
      wifiManager.startDiscoverDevices();
      hilog.info(DOMAIN, TAG, 'P2P device discovery started');
      
      setTimeout(() => {
        wifiManager.off('p2pPeerDeviceChange', recvP2pPeerDeviceChangeFunc);
        hilog.info(DOMAIN, TAG, 'Unregistered p2pPeerDeviceChange callback');
      }, 125 * 1000);
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'discover devices failed: %{public}s', JSON.stringify(error));
      this.handleError(error);
    }
  }
  
  private connectToDevice(deviceAddress: string): void {
    try {
      const recvP2pConnectionChangeFunc = (result: wifiManager.WifiP2pLinkedInfo) => {
        hilog.info(DOMAIN, TAG, 'p2p connection change: %{public}s', JSON.stringify(result));
        
        if (result.connectState === wifiManager.P2pConnectState.CONNECTED) {
          hilog.info(DOMAIN, TAG, 'P2P connection established successfully');
          hilog.info(DOMAIN, TAG, 'Is Group Owner: %{public}s', result.isGroupOwner.toString());
          hilog.info(DOMAIN, TAG, 'Group Owner Address: %{public}s', result.groupOwnerAddr);
          
          wifiManager.getCurrentGroup((err, data) => {
            if (err) {
              hilog.error(DOMAIN, TAG, 'failed to get current group: %{public}s', JSON.stringify(err));
              return;
            }
            
            hilog.info(DOMAIN, TAG, 'Group Owner IP: %{public}s', data.goIpAddress);
          });
        }
      };
      
      wifiManager.on('p2pConnectionChange', recvP2pConnectionChangeFunc);
      
      const config: wifiManager.WifiP2PConfig = {
        deviceAddress: deviceAddress,
        deviceAddressType: 1,
        netId: -2,
        passphrase: '',
        groupName: '',
        goBand: wifiManager.GroupOwnerBand.GO_BAND_AUTO
      };
      
      wifiManager.p2pConnect(config);
      hilog.info(DOMAIN, TAG, 'P2P connect request sent to %{public}s', deviceAddress);
      
      setTimeout(() => {
        wifiManager.off('p2pConnectionChange', recvP2pConnectionChangeFunc);
        hilog.info(DOMAIN, TAG, 'Unregistered p2pConnectionChange callback');
      }, 125 * 1000);
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'connectToDevice failed: %{public}s', JSON.stringify(error));
      this.handleError(error);
    }
  }
  
  setTargetDevice(deviceName: string): void {
    this.targetDeviceName = deviceName;
    hilog.info(DOMAIN, TAG, 'Target device set to: %{public}s', deviceName);
  }
  
  async stopDiscovery(): Promise<void> {
    try {
      wifiManager.stopDiscoverDevices();
      hilog.info(DOMAIN, TAG, 'P2P device discovery stopped');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'stopDiscoverDevices failed: %{public}s', JSON.stringify(error));
    }
  }
  
  private handleError(error: any): void {
    switch (error.code) {
      case 201:
        hilog.error(DOMAIN, TAG, 'Permission denied. Please request ohos.permission.GET_WIFI_INFO');
        break;
      case 2801000:
        hilog.error(DOMAIN, TAG, 'Operation failed. Please retry the operation');
        break;
      case 2801001:
        hilog.error(DOMAIN, TAG, 'Wi-Fi STA disabled. Please enable WiFi first');
        break;
      default:
        hilog.error(DOMAIN, TAG, 'Unknown error: %{public}s', JSON.stringify(error));
    }
  }
}