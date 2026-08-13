import { wifiManager } from '@kit.ConnectivityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'P2P_CreateGroup';
const DOMAIN = 0xFF00;

export class P2PGroupCreator {
  
  async createPermanentGroup(): Promise<void> {
    try {
      if (!wifiManager.isWifiActive()) {
        hilog.error(DOMAIN, TAG, 'WiFi is not active, please enable WiFi first');
        return;
      }
      
      const recvP2pPersistentGroupChangeFunc = () => {
        hilog.info(DOMAIN, TAG, 'p2p persistent group change receive event');
        
        wifiManager.getCurrentGroup((err, data) => {
          if (err) {
            hilog.error(DOMAIN, TAG, 'failed to get current group: %{public}s', JSON.stringify(err));
            return;
          }
          
          hilog.info(DOMAIN, TAG, 'get current group: %{public}s', JSON.stringify(data));
          hilog.info(DOMAIN, TAG, 'Group Owner IP: %{public}s', data.goIpAddress);
          hilog.info(DOMAIN, TAG, 'Is Group Owner: %{public}s', data.isP2pGo.toString());
        });
      };
      
      wifiManager.on('p2pPersistentGroupChange', recvP2pPersistentGroupChangeFunc);
      
      const deviceInfo = await wifiManager.getP2pLocalDevice();
      
      const config: wifiManager.WifiP2PConfig = {
        deviceAddress: deviceInfo.deviceAddress,
        deviceAddressType: 1,
        netId: -2,
        passphrase: '12345678',
        groupName: 'MyP2PGroup',
        goBand: wifiManager.GroupOwnerBand.GO_BAND_AUTO
      };
      
      wifiManager.createGroup(config);
      
      hilog.info(DOMAIN, TAG, 'Permanent P2P group created successfully');
      hilog.info(DOMAIN, TAG, 'Group Name: %{public}s', config.groupName);
      hilog.info(DOMAIN, TAG, 'Passphrase: %{public}s', config.passphrase);
      
      setTimeout(() => {
        wifiManager.off('p2pPersistentGroupChange', recvP2pPersistentGroupChangeFunc);
        hilog.info(DOMAIN, TAG, 'Unregistered p2pPersistentGroupChange callback');
      }, 125 * 1000);
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'createGroup failed: %{public}s', JSON.stringify(error));
      this.handleError(error);
    }
  }
  
  async createTemporaryGroup(): Promise<void> {
    try {
      if (!wifiManager.isWifiActive()) {
        hilog.error(DOMAIN, TAG, 'WiFi is not active, please enable WiFi first');
        return;
      }
      
      const deviceInfo = await wifiManager.getP2pLocalDevice();
      
      const config: wifiManager.WifiP2PConfig = {
        deviceAddress: deviceInfo.deviceAddress,
        deviceAddressType: 1,
        netId: -1,
        passphrase: 'temp12345',
        groupName: 'TempP2PGroup',
        goBand: wifiManager.GroupOwnerBand.GO_BAND_2GHZ
      };
      
      wifiManager.createGroup(config);
      
      hilog.info(DOMAIN, TAG, 'Temporary P2P group created successfully');
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'createTemporaryGroup failed: %{public}s', JSON.stringify(error));
      this.handleError(error);
    }
  }
  
  private handleError(error: any): void {
    switch (error.code) {
      case 201:
        hilog.error(DOMAIN, TAG, 'Permission denied. Please request ohos.permission.GET_WIFI_INFO');
        break;
      case 401:
        hilog.error(DOMAIN, TAG, 'Invalid parameters. Please check deviceAddress, netId, passphrase format');
        break;
      case 801:
        hilog.error(DOMAIN, TAG, 'Capability not supported. System does not support P2P');
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