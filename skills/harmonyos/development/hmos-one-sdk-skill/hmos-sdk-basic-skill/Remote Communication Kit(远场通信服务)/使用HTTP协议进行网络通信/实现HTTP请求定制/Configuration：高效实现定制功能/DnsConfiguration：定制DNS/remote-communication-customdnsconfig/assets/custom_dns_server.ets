import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

class CustomDnsServerExample {
  private session: rcp.Session | null = null;

  async makeRequestWithCustomDns(
    dnsServerIp: string,
    dnsServerPort: number,
    requestUrl: string
  ): Promise<void> {
    try {
      this.session = rcp.createSession();
      
      const request = new rcp.Request(requestUrl);
      
      request.configuration = {
        dns: {
          dnsRules: [
            {
              ip: dnsServerIp,
              port: dnsServerPort
            }
          ]
        }
      };

      const response = await this.session.fetch(request);
      
      console.info(`Response status: ${response.statusCode}`);
      console.info(`Response headers: ${JSON.stringify(response.headers)}`);
      
      if (response.body) {
        const responseBody = response.toString();
        console.info(`Response body: ${responseBody}`);
      }

    } catch (error) {
      const err = error as BusinessError;
      console.error(`Request failed: code=${err.code}, message=${err.data}`);
      
      this.handleDnsError(err);
    } finally {
      if (this.session) {
        this.session.close();
        this.session = null;
      }
    }
  }

  private handleDnsError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        console.error('Parameter error: Check DNS server IP and port format');
        break;
      case 1007900994:
        console.error('Session limit reached: Close unused sessions');
        break;
      default:
        if (error.message?.includes('DNS')) {
          console.error('DNS resolution failed: Check DNS server availability');
        } else {
          console.error('Unknown error occurred');
        }
    }
  }

  async testMultipleDnsServers(): Promise<void> {
    const dnsServers = [
      { ip: '8.8.8.8', port: 53 },
      { ip: '8.8.4.4', port: 53 },
      { ip: '1.1.1.1', port: 53 }
    ];

    for (const dnsServer of dnsServers) {
      console.info(`Testing DNS server: ${dnsServer.ip}:${dnsServer.port}`);
      await this.makeRequestWithCustomDns(
        dnsServer.ip,
        dnsServer.port,
        'https://www.example.com'
      );
    }
  }
}

async function main(): Promise<void> {
  const example = new CustomDnsServerExample();
  
  await example.makeRequestWithCustomDns(
    '8.8.8.8',
    53,
    'https://example.com'
  );
}

export { CustomDnsServerExample };