import { fido } from '@kit.OnlineAuthenticationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { UIContext } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct FidoDeregisterPage {
  private uiContext = this.getUIContext().getHostContext();
  
  async deregisterFido(deregMessage: string): Promise<void> {
    try {
      console.info('Starting FIDO deregistration process...');
      
      let discoverData = await fido.discover(this.uiContext);
      console.info('Succeeded in discover:', JSON.stringify(discoverData));
      
      let uafRegMessage: fido.UAFMessage = {
        uafProtocolMessage: deregMessage,
        additionalData: ''
      };
      
      let channelBinding: fido.ChannelBinding = {};
      let messageResp = await fido.processUAFOperation(this.uiContext, uafRegMessage, channelBinding);
      console.info('processUAFOperation response:', JSON.stringify(messageResp));
      
      console.info('FIDO deregistration completed successfully.');
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to deregister FIDO. Code: ${err.code}, message: ${err.message}`);
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
      case 1005900003:
        console.error('User canceled operation. Can retry deregistration.');
        break;
      case 1005900005:
        console.error('No authenticator available. User may not have registered.');
        break;
      case 1005900006:
        console.error('UAF protocol violation. Please check message format.');
        break;
      case 1005900014:
        console.error('User has not set biometric features.');
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
  
  build() {
    Column() {
      Text('FIDO Deregistration Demo')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50, bottom: 30 });
      
      Button('Deregister FIDO Authentication')
        .width('80%')
        .height(50)
        .onClick(() => {
          let deregMessage = '[{"header":{"upv":{"major":1,"minor":0},"op":"Dereg","appID":""},"authenticators":[{"aaid":"001B#1001","keyID":"test keyID"}]}]';
          this.deregisterFido(deregMessage);
        });
      
      Text('Note: This is a demo. In production, deregMessage should be obtained from FIDO server.')
        .fontSize(12)
        .fontColor(Color.Gray)
        .margin({ top: 20 });
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center);
  }
}