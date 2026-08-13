import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

class DynamicDnsResolverExample {
  private session: rcp.Session | null = null;
  private dnsMapping: Map<string, string[]> = new Map();

  constructor() {
    this.initDnsMapping();
  }

  private initDnsMapping(): void {
    this.dnsMapping.set('example.com', ['192.168.1.100', '192.168.1.101']);
    this.dnsMapping.set('api.example.com', ['192.168.2.100']);
    this.dnsMapping.set('cdn.example.com', ['192.168.3.100', '192.168.3.101']);
  }

  private dynamicDnsRule(host: string, port: number): rcp.IpAddress[] {
    console.info(`Dynamic DNS resolution for ${host}:${port}`);
    
    const ipAddresses = this.dnsMapping.get(host);
    
    if (ipAddresses && ipAddresses.length > 0) {
      console.info(`Found static mapping for ${host}: ${ipAddresses.join(',')}`);
      return ipAddresses;
    }
    
    if (host.endsWith('.local')) {
      console.info(`Resolving local domain: ${host}`);
      return ['127.0.0.1'];
    }
    
    if (host.includes('test-')) {
      console.info(`Resolving test domain: ${host}`);
      return ['10.0.0.100'];
    }
    
    console.info(`No custom mapping for ${host}, return empty array`);
    return [];
  }

  async makeRequestWithDynamicDns(requestUrl: string): Promise<void> {
    try {
      this.session = rcp.createSession();
      
      const request = new rcp.Request(requestUrl);
      
      request.configuration = {
        dns: {
          dnsRules: (host: string, port: number): rcp.IpAddress[] => {
            return this.dynamicDnsRule(host, port);
          }
        }
      };

      const response = await this.session.fetch(request);
      
      console.info(`Response status: ${response.statusCode}`);
      console.info(`Response effective URL: ${response.effectiveUrl?.href}`);
      
      if (response.timeInfo) {
        console.info(`DNS resolution time: ${response.timeInfo.nameLookupTimeMs}ms`);
      }

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

  addDnsMapping(host: string, ipAddresses: string[]): void {
    this.dnsMapping.set(host, ipAddresses);
    console.info(`Added DNS mapping: ${host} -> ${ipAddresses.join(',')}`);
  }

  removeDnsMapping(host: string): void {
    if (this.dnsMapping.has(host)) {
      this.dnsMapping.delete(host);
      console.info(`Removed DNS mapping for: ${host}`);
    }
  }

  async testMultipleDomains(): Promise<void> {
    const testUrls = [
      'https://example.com',
      'https://api.example.com/users',
      'https://cdn.example.com/static/image.jpg',
      'https://test-server.local/api',
      'https://test-api.example.com/v1'
    ];

    for (const url of testUrls) {
      await this.makeRequestWithDynamicDns(url);
    }
  }
}

async function main(): Promise<void> {
  const resolver = new DynamicDnsResolverExample();
  
  resolver.addDnsMapping('custom.example.com', ['192.168.100.1']);
  
  await resolver.makeRequestWithDynamicDns('https://example.com');
  
  await resolver.testMultipleDomains();
}

export { DynamicDnsResolverExample };