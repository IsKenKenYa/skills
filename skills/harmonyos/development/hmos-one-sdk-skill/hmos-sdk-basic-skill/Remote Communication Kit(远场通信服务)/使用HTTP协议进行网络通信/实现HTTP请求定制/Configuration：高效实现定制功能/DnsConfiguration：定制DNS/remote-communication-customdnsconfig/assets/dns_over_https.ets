import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

class DnsOverHttpsExample {
  private session: rcp.Session | null = null;

  async makeRequestWithDoh(
    dohUrl: string,
    skipCertValidation: boolean,
    requestUrl: string
  ): Promise<void> {
    try {
      const dohConfig: rcp.DnsOverHttpsConfiguration = {
        url: dohUrl,
        skipCertificatesValidation: skipCertValidation
      };

      console.info(`Using DNS over HTTPS: ${dohUrl}`);
      console.info(`Skip certificate validation: ${skipCertValidation}`);

      this.session = rcp.createSession({
        requestConfiguration: {
          dns: {
            dnsOverHttps: dohConfig
          }
        }
      });

      const request = new rcp.Request(requestUrl);
      
      const response = await this.session.fetch(request);
      
      console.info(`Response status: ${response.statusCode}`);
      
      if (response.timeInfo) {
        console.info(`DNS resolution time: ${response.timeInfo.nameLookupTimeMs}ms`);
        console.info(`Total request time: ${response.timeInfo.totalTimeMs}ms`);
      }

    } catch (error) {
      const err = error as BusinessError;
      console.error(`Request failed: code=${err.code}, message=${err.data}`);
      
      this.handleDohError(err);
    } finally {
      if (this.session) {
        this.session.close();
        this.session = null;
      }
    }
  }

  private handleDohError(error: BusinessError): void {
    if (error.message?.includes('certificate')) {
      console.error('Certificate validation failed:');
      console.error('- Check DOH server certificate');
      console.error('- Or set skipCertificatesValidation=true for testing');
    } else if (error.message?.includes('DNS')) {
      console.error('DOH request failed:');
      console.error('- Check DOH URL is correct');
      console.error('- Check DOH server is accessible');
    } else {
      console.error('Unknown error occurred');
    }
  }

  async testPublicDohServers(): Promise<void> {
    const publicDohServers = [
      {
        url: 'https://dns.google/dns-query',
        name: 'Google DNS'
      },
      {
        url: 'https://cloudflare-dns.com/dns-query',
        name: 'Cloudflare DNS'
      },
      {
        url: 'https://dns.quad9.net/dns-query',
        name: 'Quad9 DNS'
      }
    ];

    for (const server of publicDohServers) {
      console.info(`Testing ${server.name}...`);
      await this.makeRequestWithDoh(
        server.url,
        false,
        'https://www.example.com'
      );
    }
  }

  async testDohWithCustomDns(): Promise<void> {
    try {
      const dohConfig: rcp.DnsOverHttpsConfiguration = {
        url: 'https://dns.google/dns-query',
        skipCertificatesValidation: false
      };

      const staticDnsRules: rcp.StaticDnsRules = [
        {
          host: 'internal.example.com',
          port: 443,
          ipAddresses: ['192.168.1.100']
        }
      ];

      this.session = rcp.createSession({
        requestConfiguration: {
          dns: {
            dnsOverHttps: dohConfig,
            dnsRules: staticDnsRules
          }
        }
      });

      const request = new rcp.Request('https://internal.example.com');
      
      const response = await this.session.fetch(request);
      
      console.info(`Response status: ${response.statusCode}`);

    } catch (error) {
      const err = error as BusinessError;
      console.error(`Request failed: code=${err.code}, message=${err.data}`);
    } finally {
      if (this.session) {
        this.session.close();
        this.session = null;
      }
    }
  }

  async compareDohPerformance(): Promise<void> {
    console.info('Testing regular DNS...');
    
    const regularSession = rcp.createSession();
    const request1 = new rcp.Request('https://www.example.com');
    
    const response1 = await regularSession.fetch(request1);
    if (response1.timeInfo) {
      console.info(`Regular DNS time: ${response1.timeInfo.nameLookupTimeMs}ms`);
    }
    regularSession.close();

    console.info('Testing DNS over HTTPS...');
    await this.makeRequestWithDoh(
      'https://dns.google/dns-query',
      false,
      'https://www.example.com'
    );
  }
}

async function main(): Promise<void> {
  const example = new DnsOverHttpsExample();
  
  await example.makeRequestWithDoh(
    'https://dns.google/dns-query',
    false,
    'https://example.com'
  );
  
  await example.testPublicDohServers();
  
  await example.testDohWithCustomDns();
  
  await example.compareDohPerformance();
}

export { DnsOverHttpsExample };