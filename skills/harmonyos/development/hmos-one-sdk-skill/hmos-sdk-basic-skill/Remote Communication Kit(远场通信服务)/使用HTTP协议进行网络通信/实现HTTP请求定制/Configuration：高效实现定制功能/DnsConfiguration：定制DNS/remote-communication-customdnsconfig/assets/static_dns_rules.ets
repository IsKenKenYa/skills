import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

class StaticDnsRulesExample {
  private session: rcp.Session | null = null;

  async makeRequestWithStaticDns(
    host: string,
    port: number,
    ipAddresses: string[],
    enableHappyEyeball: boolean = false
  ): Promise<void> {
    try {
      this.session = rcp.createSession();
      
      const requestUrl = `https://${host}`;
      const request = new rcp.Request(requestUrl);
      
      const staticDnsRules: rcp.StaticDnsRules = [
        {
          host: host,
          port: port,
          ipAddresses: ipAddresses
        }
      ];

      request.configuration = {
        dns: {
          dnsRules: staticDnsRules,
          happyEyeballOnDnsRule: enableHappyEyeball
        }
      };

      console.info(`Requesting ${host}:${port} with static DNS mapping`);
      console.info(`Mapped IP addresses: ${ipAddresses.join(',')}`);
      console.info(`Happy Eyeball enabled: ${enableHappyEyeball}`);

      const response = await this.session.fetch(request);
      
      console.info(`Response status: ${response.statusCode}`);
      
      if (response.timeInfo) {
        console.info(`Total request time: ${response.timeInfo.totalTimeMs}ms`);
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

  async makeRequestWithMultipleStaticRules(): Promise<void> {
    try {
      this.session = rcp.createSession();
      
      const request = new rcp.Request('https://api.example.com');
      
      const staticDnsRules: rcp.StaticDnsRules = [
        {
          host: 'api.example.com',
          port: 443,
          ipAddresses: ['192.168.1.100', '192.168.1.101']
        },
        {
          host: 'cdn.example.com',
          port: 443,
          ipAddresses: ['192.168.2.100']
        }
      ];

      request.configuration = {
        dns: {
          dnsRules: staticDnsRules,
          happyEyeballOnDnsRule: true
        }
      };

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

  async testSingleIpMapping(): Promise<void> {
    await this.makeRequestWithStaticDns(
      'example.com',
      443,
      ['192.168.1.100'],
      false
    );
  }

  async testMultipleIpMapping(): Promise<void> {
    await this.makeRequestWithStaticDns(
      'example.com',
      443,
      ['192.168.1.100', '192.168.1.101', '192.168.1.102'],
      true
    );
  }

  async compareHappyEyeball(): Promise<void> {
    console.info('Testing without Happy Eyeball...');
    await this.makeRequestWithStaticDns(
      'test.example.com',
      443,
      ['192.168.1.100', '192.168.1.101'],
      false
    );

    console.info('Testing with Happy Eyeball...');
    await this.makeRequestWithStaticDns(
      'test.example.com',
      443,
      ['192.168.1.100', '192.168.1.101'],
      true
    );
  }
}

async function main(): Promise<void> {
  const example = new StaticDnsRulesExample();
  
  await example.testSingleIpMapping();
  
  await example.testMultipleIpMapping();
  
  await example.makeRequestWithMultipleStaticRules();
  
  await example.compareHappyEyeball();
}

export { StaticDnsRulesExample };