import { wifiManager } from '@kit.ConnectivityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'P2P_GetGroupInfo';
const DOMAIN = 0xFF00;

export class P2PGroupInfoGetter {
  
  async getLinkedInfo(): Promise<wifiManager.WifiP2pLinkedInfo | null> {
    try {
      const linkedInfo = await wifiManager.getP2pLinkedInfo();
      
      hilog.info(DOMAIN, TAG, 'P2P Linked Info: %{public}s', JSON.stringify(linkedInfo));
      hilog.info(DOMAIN, TAG, 'Connect State: %{public}d', linkedInfo.connectState);
      hilog.info(DOMAIN, TAG, 'Is Group Owner: %{public}s', linkedInfo.isGroupOwner.toString());
      hilog.info(DOMAIN, TAG, 'Group Owner Address: %{public}s', linkedInfo.groupOwnerAddr);
      
      return linkedInfo;
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'getP2pLinkedInfo failed: %{public}s', JSON.stringify(error));
      this.handleError(error);
      return null;
    }
  }
  
  async getCurrentGroupInfo(): Promise<wifiManager.WifiP2pGroupInfo | null> {
    try {
      const groupInfo = await wifiManager.getCurrentGroup();
      
      hilog.info(DOMAIN, TAG, 'Current Group Info: %{public}s', JSON.stringify(groupInfo));
      hilog.info(DOMAIN, TAG, 'Is P2P GO: %{public}s', groupInfo.isP2pGo.toString());
      hilog.info(DOMAIN, TAG, 'Group Name: %{public}s', groupInfo.groupName);
      hilog.info(DOMAIN, TAG, 'Passphrase: %{public}s', groupInfo.passphrase);
      hilog.info(DOMAIN, TAG, 'Group Owner IP: %{public}s', groupInfo.goIpAddress);
      hilog.info(DOMAIN, TAG, 'Network ID: %{public}d', groupInfo.networkId);
      hilog.info(DOMAIN, TAG, 'Frequency: %{public}d', groupInfo.frequency);
      
      if (groupInfo.clientDevices && groupInfo.clientDevices.length > 0) {
        hilog.info(DOMAIN, TAG, 'Client Devices Count: %{public}d', groupInfo.clientDevices.length);
        
        for (let i = 0; i < groupInfo.clientDevices.length; ++i) {
          hilog.info(DOMAIN, TAG, 'Client %{public}d: %{public}s (%{public}s)', 
            i, groupInfo.clientDevices[i].deviceName, groupInfo.clientDevices[i].deviceAddress);
        }
      }
      
      return groupInfo;
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'getCurrentGroup failed: %{public}s', JSON.stringify(error));
      this.handleError(error);
      return null;
    }
  }
  
  async getLocalDevice(): Promise<wifiManager.WifiP2pDevice | null> {
    try {
      const localDevice = await wifiManager.getP2pLocalDevice();
      
      hilog.info(DOMAIN, TAG, 'Local Device Info: %{public}s', JSON.stringify(localDevice));
      hilog.info(DOMAIN, TAG, 'Device Name: %{public}s', localDevice.deviceName);
      hilog.info(DOMAIN, TAG, 'Device Address: %{public}s', localDevice.deviceAddress);
      hilog.info(DOMAIN, TAG, 'Device Status: %{public}d', localDevice.deviceStatus);
      hilog.info(DOMAIN, TAG, 'Primary Device Type: %{public}s', localDevice.primaryDeviceType);
      
      return localDevice;
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'getP2pLocalDevice failed: %{public}s', JSON.stringify(error));
      this.handleError(error);
      return null;
    }
  }
  
  async getPeerDevices(): Promise<wifiManager.WifiP2pDevice[] | null> {
    try {
      const peerDevices = await wifiManager.getP2pPeerDevices();
      
      hilog.info(DOMAIN, TAG, 'Peer Devices Count: %{public}d', peerDevices.length);
      
      for (let i = 0; i < peerDevices.length; ++i) {
        hilog.info(DOMAIN, TAG, 'Peer %{public}d: %{public}s (%{public}s) - Status: %{public}d', 
          i, peerDevices[i].deviceName, peerDevices[i].deviceAddress, peerDevices[i].deviceStatus);
      }
      
      return peerDevices;
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'getP2pPeerDevices failed: %{public}s', JSON.stringify(error));
      this.handleError(error);
      return null;
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