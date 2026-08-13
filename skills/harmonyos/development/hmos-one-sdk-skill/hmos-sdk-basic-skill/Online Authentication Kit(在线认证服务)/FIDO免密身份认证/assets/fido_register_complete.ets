import { fido } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { UIContext } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct FidoRegisterPage {
  private uiContext = this.getUIContext().getHostContext();
  
  async registerFido(regMessage: string): Promise<void> {
    try {
      console.info('Starting FIDO registration process...');
      
      let discoverData = await fido.discover(this.uiContext);
      console.info('Succeeded in discover:', JSON.stringify(discoverData));
      
      let uafAuthMessage: fido.UAFMessage = {
        uafProtocolMessage: regMessage,
        additionalData: ''
      };
      
      let isRegistered: boolean = true;
      try {
        await fido.checkPolicy(this.uiContext, uafAuthMessage);
        console.info('User has already registered, no need to register again.');
        return;
      } catch (error) {
        isRegistered = false;
        const err: BusinessError = error as BusinessError;
        console.error(`checkPolicy failed. Code: ${err.code}, Message: ${err.message}`);
      }
      
      if (!isRegistered) {
        let uafRegMessage: fido.UAFMessage = {
          uafProtocolMessage: regMessage,
          additionalData: ''
        };
        
        let channelBinding: fido.ChannelBinding = {};
        let messageResp = await fido.processUAFOperation(this.uiContext, uafRegMessage, channelBinding);
        console.info('processUAFOperation response:', JSON.stringify(messageResp));
        
        let notifyMessage: fido.UAFMessage = {
          uafProtocolMessage: messageResp.uafProtocolMessage,
          additionalData: ''
        };
        
        await fido.notifyUAFResult(this.uiContext, notifyMessage);
        console.info('Succeeded in notifyUAFResult. FIDO registration completed.');
      }
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to register FIDO. Code: ${err.code}, message: ${err.message}`);
      this.handleFidoError(err);
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
      case 1005900005:
        console.error('No authenticator available. Please check authenticator policy.');
        break;
      case 1005900006:
        console.error('UAF protocol violation. Please check message format.');
        break;
      case 1005900007:
        console.error('Facet ID mismatch. Please check server configuration.');
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
  
  build() {
    Column() {
      Text('FIDO Registration Demo')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50, bottom: 30 });
      
      Button('Register FIDO Authentication')
        .width('80%')
        .height(50)
        .onClick(() => {
          let regMessage = '[{"header":{"upv":{"major":1,"minor":0},"op":"Reg","appID":"","serverData":"test server data"},"challenge":"test challenge","username":"test user name","policy":{"accepted":[[{"aaid":["001B#1001"],"attachmentHint":1,"authenticationAlgorithms":[1],"authenticatorVersion":1}]]}}]';
          this.registerFido(regMessage);
        });
      
      Text('Note: This is a demo. In production, regMessage should be obtained from FIDO server.')
        .fontSize(12)
        .fontColor(Color.Gray)
        .margin({ top: 20 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}