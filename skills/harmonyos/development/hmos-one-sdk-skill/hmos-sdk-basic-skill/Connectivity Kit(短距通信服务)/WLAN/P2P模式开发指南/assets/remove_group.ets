import { wifiManager } from '@kit.ConnectivityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'P2P_RemoveGroup';
const DOMAIN = 0xFF00;

export class P2PGroupRemover {
  
  async removeGroup(): Promise<boolean> {
    try {
      const linkedInfo = await wifiManager.getP2pLinkedInfo();
      
      if (linkedInfo.connectState === wifiManager.P2pConnectState.DISCONNECTED) {
        hilog.warn(DOMAIN, TAG, 'P2P is not connected, no group to remove');
        return false;
      }
      
      wifiManager.removeGroup();
      
      hilog.info(DOMAIN, TAG, 'P2P group removed successfully');
      
      const newLinkedInfo = await wifiManager.getP2pLinkedInfo();
      
      if (newLinkedInfo.connectState === wifiManager.P2pConnectState.DISCONNECTED) {
        hilog.info(DOMAIN, TAG, 'P2P connection state confirmed: DISCONNECTED');
        return true;
      } else {
        hilog.warn(DOMAIN, TAG, 'P2P connection state unexpected: %{public}d', newLinkedInfo.connectState);
        return false;
      }
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'removeGroup failed: %{public}s', JSON.stringify(error));
      this.handleError(error);
      return false;
    }
  }
  
  async cancelConnect(): Promise<void> {
    try {
      wifiManager.p2pCancelConnect();
      hilog.info(DOMAIN, TAG, 'P2P connection canceled');
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'p2pCancelConnect failed: %{public}s', JSON.stringify(error));
      this.handleError(error);
    }
  }
  
  async cleanupP2P(): Promise<void> {
    try {
      await this.removeGroup();
      
      wifiManager.stopDiscoverDevices();
      hilog.info(DOMAIN, TAG, 'P2P discovery stopped');
      
      hilog.info(DOMAIN, TAG, 'P2P cleanup completed');
      
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'cleanupP2P failed: %{public}s', JSON.stringify(error));
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