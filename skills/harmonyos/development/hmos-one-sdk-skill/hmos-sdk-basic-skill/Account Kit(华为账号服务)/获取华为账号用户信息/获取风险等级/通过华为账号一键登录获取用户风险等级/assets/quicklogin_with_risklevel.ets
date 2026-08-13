import { LoginWithHuaweiIDButton, loginComponentManager } from '@kit.AccountKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct QuickLoginWithRiskLevel {
  logTag: string = 'QuickLoginWithRiskLevel';
  domainId: number = 0x0000;
  
  @State anonymousPhone: string = '139******99';
  @State loginStatus: string = '准备登录';
  @State riskLevel: number = -1;
  
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .setAgreementStatus(loginComponentManager.AgreementStatus.NOT_ACCEPTED)
      .onClickLoginWithHuaweiIDButton((error: BusinessError, response: loginComponentManager.HuaweiIDCredential) => {
        if (error) {
          this.handleError(error);
          return;
        }
        if (response) {
          const authorizationCode = response.authorizationCode;
          const openID = response.openID;
          const unionID = response.unionID;
          
          hilog.info(this.domainId, this.logTag, 'Authorization Code获取成功');
          this.loginStatus = 'Authorization Code获取成功，正在获取风险等级...';
          
          this.sendCodeToServer(authorizationCode, openID, unionID);
        }
      });

  handleError(error: BusinessError): void {
    hilog.error(this.domainId, this.logTag, `登录失败: ${error.code}, ${error.message}`);
    this.loginStatus = `登录失败: ${error.message}`;
    
    switch (error.code) {
      case 1001502001:
        this.loginStatus = '用户未登录华为账号，请登录华为账号并重试';
        break;
      case 1001502005:
        this.loginStatus = '网络异常，请检查当前网络状态并重试';
        break;
      case 1001502009:
        this.loginStatus = '内部错误，请尝试使用其他方式登录';
        break;
      case 1001502012:
        this.loginStatus = '用户取消授权';
        break;
      case 12300001:
        this.loginStatus = '系统服务异常，请稍后重试';
        break;
      case 1001502014:
        this.loginStatus = '应用未申请权限，请联系开发者';
        break;
      case 1005300001:
        this.loginStatus = '用户未同意协议';
        break;
      default:
        this.loginStatus = `其他错误: ${error.code}`;
        break;
    }
  }

  async sendCodeToServer(authorizationCode: string, openID: string, unionID: string): void {
    try {
      const response = await this.callServerAPI(authorizationCode);
      if (response.riskLevel !== undefined) {
        this.riskLevel = response.riskLevel;
        this.loginStatus = this.getRiskLevelDescription(response.riskLevel);
        
        if (response.riskTag && response.riskTag.length > 0) {
          hilog.info(this.domainId, this.logTag, `风险标签: ${response.riskTag.join(',')}`);
        }
      }
    } catch (e) {
      hilog.error(this.domainId, this.logTag, `服务端调用失败: ${e.message}`);
      this.loginStatus = `服务端调用失败: ${e.message}`;
    }
  }

  async callServerAPI(authorizationCode: string): Promise<any> {
    return new Promise((resolve, reject) => {
      const httpRequest = http.createHttp();
      
      httpRequest.request(
        'https://your-server-api.com/getRiskLevel',
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: {
            authorizationCode: authorizationCode
          }
        },
        (err, data) => {
          if (!err) {
            try {
              const result = JSON.parse(data.result.toString());
              resolve(result);
            } catch (e) {
              reject(new Error('解析响应失败'));
            }
          } else {
            reject(new Error(err.message));
          }
        }
      );
    });
  }

  getRiskLevelDescription(level: number): string {
    switch (level) {
      case 0:
        return '风险等级: 0 - 未发现显著风险，建议放通';
      case 1:
        return '风险等级: 1 - 低风险，建议简单验证';
      case 2:
        return '风险等级: 2 - 中风险，建议采取一定措施';
      case 3:
        return '风险等级: 3 - 高风险，建议拦截';
      case 4:
        return '风险等级: 4 - 风险未知，建议结合历史行为决策';
      default:
        return '未知风险等级';
    }
  }

  build() {
    Column() {
      Text(this.anonymousPhone)
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 100 })
      
      Text('华为账号绑定号码')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 8 })
      
      LoginWithHuaweiIDButton({
        params: {
          style: loginComponentManager.Style.BUTTON_RED,
          borderRadius: 24,
          loginType: loginComponentManager.LoginType.QUICK_LOGIN,
          supportDarkMode: true,
          verifyPhoneNumber: true,
          riskLevel: true
        },
        controller: this.controller
      })
      .width('90%')
      .height(40)
      .margin({ top: 56 })
      
      Text(this.loginStatus)
        .fontSize(14)
        .fontColor('#333333')
        .margin({ top: 20 })
      
      if (this.riskLevel >= 0) {
        Text(`当前风险等级: ${this.riskLevel}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.riskLevel >= 3 ? '#FF0000' : '#333333')
          .margin({ top: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}