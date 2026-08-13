import { fido } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { UIContext } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct FidoAuthenticatePage {
  private uiContext = this.getUIContext().getHostContext();
  
  async authenticateFido(authMessage: string): Promise<fido.UAFMessage | null> {
    try {
      console.info('Starting FIDO authentication process...');
      
      let discoverData = await fido.discover(this.uiContext);
      console.info('Succeeded in discover:', JSON.stringify(discoverData));
      
      let uafAuthMessage: fido.UAFMessage = {
        uafProtocolMessage: authMessage,
        additionalData: ''
      };
      
      await fido.checkPolicy(this.uiContext, uafAuthMessage);
      console.info('checkPolicy succeeded. User has registered.');
      
      let uafRegMessage: fido.UAFMessage = {
        uafProtocolMessage: authMessage,
        additionalData: '{"navigationButtonText": "Use other authentication method"}'
      };
      
      let channelBinding: fido.ChannelBinding = {};
      let messageResp = await fido.processUAFOperation(this.uiContext, uafRegMessage, channelBinding);
      console.info('processUAFOperation response:', JSON.stringify(messageResp));
      
      console.info('FIDO authentication completed successfully.');
      return messageResp;
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to authenticate FIDO. Code: ${err.code}, message: ${err.message}`);
      this.handleFidoError(err);
      return null;
    }
  }
  
  handleFidoError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        console.error('Parameter error. Please check input parameters.');
        break;
      case 801:
        console.error('Device type error. Current device does not support FIDO.');
        break;
      case 1005900003:
        console.error('User canceled operation. Can retry authentication.');
        break;
      case 1005900005:
        console.error('No authenticator available. User may not have registered.');
        break;
      case 1005900006:
        console.error('UAF protocol violation. Please check message format.');
        break;
      case 1005900009:
        console.error('Authenticator denied request. Please deregister and register again.');
        break;
      case 1005900014:
        console.error('User has not set biometric features. Guiding user to settings...');
        this.guideUserToSetBiometrics();
        break;
      case 1005900015:
        console.error('System interruption. Please restart device.');
        break;
      case 1005900016:
        console.error('Unknown error. Please retry or restart device.');
        break;
      case 1005900017:
        console.info('User switched to custom authentication process.');
        this.launchCustomAuthentication();
        break;
      default:
        console.error(`Unknown error code: ${error.code}, message: ${error.message}`);
    }
  }
  
  async guideUserToSetBiometrics(): Promise<void> {
    try {
      let uafMessage: fido.UAFMessage = {
        uafProtocolMessage: '',
        additionalData: '{"isGuideToSetBiometrics": true}'
      };
      await fido.processUAFOperation(this.uiContext, uafMessage);
    } catch (error) {
      console.error('Failed to guide user to set biometrics:', error);
    }
  }
  
  launchCustomAuthentication(): void {
    console.info('Launching custom authentication interface...');
  }
  
  async fallbackAuthentication(): Promise<void> {
    console.warn('FIDO authentication failed. Trying fallback authentication method.');
  }
  
  build() {
    Column() {
      Text('FIDO Authentication Demo')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50, bottom: 30 });
      
      Button('Authenticate with FIDO')
        .width('80%')
        .height(50)
        .onClick(async () => {
          let authMessage = '[{"header":{"upv":{"major":1,"minor":0},"op":"Auth","appID":"","serverData":"test server data"},"challenge":"test challenge","policy":{"accepted":[[{"aaid":["001B#1001"],"keyIDs":["test keyIDs"],"authenticationAlgorithms":[1]}]]}}]';
          let result = await this.authenticateFido(authMessage);
          if (result) {
            console.info('Authentication successful! Response:', JSON.stringify(result));
          }
        });
      
      Button('Fallback Authentication')
        .width('80%')
        .height(50)
        .margin({ top: 20 })
        .onClick(() => {
          this.fallbackAuthentication();
        });
      
      Text('Note: This is a demo. In production, authMessage should be obtained from FIDO server.')
        .fontSize(12)
        .fontColor(Color.Gray)
        .margin({ top: 20 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}