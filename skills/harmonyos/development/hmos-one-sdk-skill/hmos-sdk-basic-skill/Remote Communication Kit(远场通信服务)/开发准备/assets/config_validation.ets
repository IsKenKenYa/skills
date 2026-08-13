import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class ConfigValidator {
  private session: rcp.Session | null = null;

  async validatePermissions(): Promise<boolean> {
    try {
      this.session = rcp.createSession();
      console.info('Session created successfully, permissions configured correctly');
      return true;
    } catch (err) {
      let error: BusinessError = err as BusinessError;
      console.error(`Permission validation failed: code ${error.code}, message ${error.message}`);
      
      if (error.code === 201) {
        console.error('Permission denied: please check module.json5 permissions configuration');
      } else if (error.code === 1007900994) {
        console.error('Sessions number reached limit: too many session instances');
      }
      return false;
    }
  }

  async testNetworkConnection(url: string): Promise<boolean> {
    if (!this.session) {
      console.error('Session not created, please validate permissions first');
      return false;
    }

    try {
      const response = await this.session.get(url);
      console.info(`Network test succeeded: status ${response.statusCode}`);
      return true;
    } catch (err) {
      let error: BusinessError = err as BusinessError;
      console.error(`Network test failed: code ${error.code}, message ${error.message}`);
      
      switch (error.code) {
        case 1007900003:
          console.error('URL format error: check URL format');
          break;
        case 1007900006:
          console.error('DNS resolution failed: check network connection and URL');
          break;
        case 1007900007:
          console.error('Cannot connect to server: check network connection');
          break;
        case 1007900201:
          console.error('HTTP cleartext not permitted: configure network_config.json or use HTTPS');
          break;
        default:
          console.error(`Unknown error: code ${error.code}`);
      }
      return false;
    }
  }

  async validateFullConfiguration(): Promise<boolean> {
    const permissionResult = await this.validatePermissions();
    if (!permissionResult) {
      return false;
    }

    const networkResult = await this.testNetworkConnection('https://www.example.com');
    if (!networkResult) {
      return false;
    }

    console.info('Full configuration validation passed');
    return true;
  }

  cleanup(): void {
    if (this.session) {
      this.session.close();
      this.session = null;
      console.info('Session closed successfully');
    }
  }
}

export async function main(): Promise<void> {
  const validator = new ConfigValidator();
  
  try {
    const result = await validator.validateFullConfiguration();
    if (result) {
      console.info('Remote Communication Kit configuration is ready');
    } else {
      console.error('Remote Communication Kit configuration has issues');
    }
  } finally {
    validator.cleanup();
  }
}