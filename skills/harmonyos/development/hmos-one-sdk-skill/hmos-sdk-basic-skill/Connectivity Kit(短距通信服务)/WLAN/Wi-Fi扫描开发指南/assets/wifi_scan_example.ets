import { wifiManager } from '@kit.ConnectivityKit';

interface WifiNetworkInfo {
  ssid: string;
  bssid: string;
  rssi: number;
  band: number;
  frequency: number;
  channelWidth: number;
  securityType: number;
  capabilities: string;
  timestamp: number;
  supportedWifiCategory?: number;
  isHiLinkNetwork?: boolean;
}

class WifiScanner {
  private scanCallback: (result: number) => void | null = null;
  private isScanCompleted: boolean = false;

  checkWifiEnabled(): boolean {
    try {
      const isActive = wifiManager.isWifiActive();
      if (!isActive) {
        console.error('WiFi is not enabled');
        return false;
      }
      console.info('WiFi is enabled');
      return true;
    } catch (error) {
      console.error(`Check WiFi status failed: ${JSON.stringify(error)}`);
      return false;
    }
  }

  registerScanListener(): void {
    this.scanCallback = (result: number) => {
      this.isScanCompleted = true;
      if (result === 1) {
        console.info('WiFi scan completed successfully');
      } else {
        console.error('WiFi scan failed (result code: 0)');
      }
    };

    try {
      wifiManager.on('wifiScanStateChange', this.scanCallback);
      console.info('Scan listener registered');
    } catch (error) {
      console.error(`Register scan listener failed: ${JSON.stringify(error)}`);
    }
  }

  unregisterScanListener(): void {
    if (this.scanCallback) {
      try {
        wifiManager.off('wifiScanStateChange', this.scanCallback);
        console.info('Scan listener unregistered');
        this.scanCallback = null;
      } catch (error) {
        console.error(`Unregister scan listener failed: ${JSON.stringify(error)}`);
      }
    }
  }

  startScan(): boolean {
    try {
      wifiManager.startScan();
      console.info('WiFi scan started');
      return true;
    } catch (error) {
      console.error(`Start scan failed: ${JSON.stringify(error)}`);
      return false;
    }
  }

  getScanResults(): WifiNetworkInfo[] {
    try {
      const scanInfoList = wifiManager.getScanInfoList();
      const networkCount = scanInfoList.length;
      console.info(`Found ${networkCount} WiFi networks`);

      const results: WifiNetworkInfo[] = [];
      for (let i = 0; i < networkCount; i++) {
        const info = scanInfoList[i];
        const network: WifiNetworkInfo = {
          ssid: info.ssid,
          bssid: info.bssid,
          rssi: info.rssi,
          band: info.band,
          frequency: info.frequency,
          channelWidth: info.channelWidth,
          securityType: info.securityType,
          capabilities: info.capabilities,
          timestamp: info.timestamp,
          supportedWifiCategory: info.supportedWifiCategory,
          isHiLinkNetwork: info.isHiLinkNetwork
        };
        results.push(network);

        console.info(`[${i + 1}] SSID: ${network.ssid}`);
        console.info(`    BSSID: ${network.bssid}`);
        console.info(`    RSSI: ${network.rssi} dBm`);
        console.info(`    Band: ${network.band === 1 ? '2.4GHz' : '5GHz'}`);
        console.info(`    Frequency: ${network.frequency} MHz`);
        console.info(`    Security: ${this.getSecurityTypeName(network.securityType)}`);
        console.info(`    WiFi Category: ${network.supportedWifiCategory || 'Unknown'}`);
        console.info(`    HiLink: ${network.isHiLinkNetwork || false}`);
      }

      return results;
    } catch (error) {
      console.error(`Get scan results failed: ${JSON.stringify(error)}`);
      return [];
    }
  }

  getSecurityTypeName(type: number): string {
    const securityTypes = {
      0: 'Invalid',
      1: 'Open',
      2: 'WEP',
      3: 'PSK/WPA2-PSK',
      4: 'SAE/WPA3',
      5: 'EAP',
      6: 'EAP-Suite-B',
      7: 'OWE',
      8: 'WAPI-CERT',
      9: 'WAPI-PSK'
    };
    return securityTypes[type] || 'Unknown';
  }

  async performFullScan(timeoutMs: number = 5000): Promise<WifiNetworkInfo[]> {
    if (!this.checkWifiEnabled()) {
      console.error('Cannot perform scan: WiFi is disabled');
      return [];
    }

    this.registerScanListener();
    this.isScanCompleted = false;

    if (!this.startScan()) {
      this.unregisterScanListener();
      return [];
    }

    const startTime = Date.now();
    while (!this.isScanCompleted && (Date.now() - startTime) < timeoutMs) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }

    if (!this.isScanCompleted) {
      console.warn('Scan did not complete within timeout');
    }

    const results = this.getScanResults();
    this.unregisterScanListener();

    return results;
  }

  filterBySignalStrength(minRssi: number, networks: WifiNetworkInfo[]): WifiNetworkInfo[] {
    return networks.filter(network => network.rssi >= minRssi);
  }

  filterByBand(band: number, networks: WifiNetworkInfo[]): WifiNetworkInfo[] {
    return networks.filter(network => network.band === band);
  }

  sortBySignalStrength(networks: WifiNetworkInfo[], ascending: boolean = false): WifiNetworkInfo[] {
    return networks.sort((a, b) => {
      return ascending ? a.rssi - b.rssi : b.rssi - a.rssi;
    });
  }
}

async function main() {
  const scanner = new WifiScanner();
  
  console.info('=== Starting WiFi Scan ===');
  const networks = await scanner.performFullScan(5000);
  
  if (networks.length > 0) {
    console.info('\n=== Top 5 Strongest Networks ===');
    const sortedNetworks = scanner.sortBySignalStrength(networks);
    const top5 = sortedNetworks.slice(0, 5);
    
    for (const network of top5) {
      console.info(`SSID: ${network.ssid}, RSSI: ${network.rssi} dBm`);
    }
    
    console.info('\n=== 2.4GHz Networks ===');
    const 2gNetworks = scanner.filterByBand(1, networks);
    console.info(`Found ${2gNetworks.length} 2.4GHz networks`);
    
    console.info('\n=== 5GHz Networks ===');
    const 5gNetworks = scanner.filterByBand(2, networks);
    console.info(`Found ${5gNetworks.length} 5GHz networks`);
    
    console.info('\n=== Strong Networks (RSSI >= -60 dBm) ===');
    const strongNetworks = scanner.filterBySignalStrength(-60, networks);
    console.info(`Found ${strongNetworks.length} strong networks`);
  } else {
    console.warn('No WiFi networks found');
  }
}

export { WifiScanner, WifiNetworkInfo, main };