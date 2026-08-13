import { minorsProtection } from '@kit.AccountKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { commonEventManager } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

const TAG = 'MinorsProtectionDemo';
const DOMAIN = 0x0000;

@Entry
@Component
struct MinorsProtectionTurnOffDemo {
  @State userTurnOffFlag: boolean = false;
  @State minorsProtectionMode: boolean = false;
  @State ageGroupInfo: string = '';
  @State verifyResult: boolean = false;
  @State message: string = '';
  
  private onSubscriber?: commonEventManager.CommonEventSubscriber;
  private offSubscriber?: commonEventManager.CommonEventSubscriber;

  aboutToAppear(): void {
    hilog.info(DOMAIN, TAG, 'Page about to appear');
    this.subscribeMinorsModeEvents();
    this.getMinorsModeStatus();
  }

  aboutToDisappear(): void {
    hilog.info(DOMAIN, TAG, 'Page about to disappear');
    this.unsubscribeMinorsModeEvents();
  }

  subscribeMinorsModeEvents(): void {
    try {
      this.onSubscriber = commonEventManager.subscribeCommonEvent(
        {
          events: [commonEventManager.Support.COMMON_EVENT_MINORSMODE_ON]
        },
        (err, data) => {
          if (err) {
            hilog.error(DOMAIN, TAG, `Failed to subscribe MINORSMODE_ON. Code: ${err.code}`);
            return;
          }
          hilog.info(DOMAIN, TAG, 'MINORSMODE_ON event received');
          this.userTurnOffFlag = false;
          this.getMinorsModeStatus();
        }
      );

      this.offSubscriber = commonEventManager.subscribeCommonEvent(
        {
          events: [commonEventManager.Support.COMMON_EVENT_MINORSMODE_OFF]
        },
        (err, data) => {
          if (err) {
            hilog.error(DOMAIN, TAG, `Failed to subscribe MINORSMODE_OFF. Code: ${err.code}`);
            return;
          }
          hilog.info(DOMAIN, TAG, 'MINORSMODE_OFF event received');
          this.userTurnOffFlag = false;
          this.minorsProtectionMode = false;
        }
      );
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to subscribe events. Code: ${error.code}`);
    }
  }

  unsubscribeMinorsModeEvents(): void {
    try {
      if (this.onSubscriber) {
        commonEventManager.unsubscribeCommonEvent(this.onSubscriber);
      }
      if (this.offSubscriber) {
        commonEventManager.unsubscribeCommonEvent(this.offSubscriber);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to unsubscribe events. Code: ${error.code}`);
    }
  }

  getMinorsModeStatus(): void {
    if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
      this.message = '当前设备不支持未成年人保护功能';
      hilog.info(DOMAIN, TAG, 'Device does not support minors protection');
      return;
    }

    try {
      if (!minorsProtection.supportMinorsMode()) {
        this.message = '当前设备环境不支持未成年人模式';
        hilog.info(DOMAIN, TAG, 'Environment does not support minors mode');
        return;
      }

      const minorsProtectionInfo = minorsProtection.getMinorsProtectionInfoSync();
      this.minorsProtectionMode = minorsProtectionInfo.minorsProtectionMode;

      hilog.info(DOMAIN, TAG, `Minors mode status: ${this.minorsProtectionMode}`);

      if (this.minorsProtectionMode) {
        const ageGroup = minorsProtectionInfo.ageGroup;
        if (ageGroup) {
          this.ageGroupInfo = `[${ageGroup.lowerAge}, ${ageGroup.upperAge})`;
          hilog.info(DOMAIN, TAG, `Age group: ${this.ageGroupInfo}`);
        }
        this.message = `系统未成年人模式已开启，年龄段: ${this.ageGroupInfo}`;
      } else {
        this.message = '系统未成年人模式已关闭';
        this.userTurnOffFlag = false;
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to get minors protection info. Code: ${error.code}`);
      this.message = `获取未成年人模式状态失败: ${error.message}`;
    }
  }

  async verifyAndTurnOffAppMinorsMode(): Promise<void> {
    if (!canIUse('SystemCapability.AuthenticationServices.HuaweiID.MinorsProtection')) {
      this.message = '当前设备不支持未成年人保护功能';
      return;
    }

    try {
      if (!minorsProtection.supportMinorsMode()) {
        this.message = '当前设备环境不支持未成年人模式';
        return;
      }

      if (!this.minorsProtectionMode) {
        this.message = '未成年人模式未开启，无法验证密码';
        hilog.warn(DOMAIN, TAG, 'Minors mode not enabled');
        return;
      }

      this.message = '正在验证家长密码...';
      hilog.info(DOMAIN, TAG, 'Starting credential verification');

      const context = this.getUIContext().getHostContext();
      const verifyResult = await minorsProtection.verifyMinorsProtectionCredential(context);

      hilog.info(DOMAIN, TAG, `Verify result: ${verifyResult}`);

      if (verifyResult) {
        this.userTurnOffFlag = true;
        this.verifyResult = true;
        this.message = '密码验证成功！应用的未成年人模式已关闭（系统未成年人模式仍保持开启）';
        hilog.info(DOMAIN, TAG, 'App minors mode turned off successfully');
      } else {
        this.verifyResult = false;
        this.message = '密码验证失败，请重新输入';
        hilog.warn(DOMAIN, TAG, 'Password verification failed');
      }
    } catch (error) {
      const businessError = error as BusinessError<Object>;
      this.handleVerifyError(businessError);
    }
  }

  handleVerifyError(error: BusinessError<Object>): void {
    hilog.error(DOMAIN, TAG, `Failed to verify. Code: ${error.code}, message: ${error.message}`);

    switch (error.code) {
      case 1009900002:
        this.message = '未成年人模式未开启，请先开启系统未成年人模式';
        break;
      case 1009900003:
        this.message = '用户取消了操作';
        this.verifyResult = false;
        break;
      case 401:
        this.message = '参数错误，请检查Context参数';
        break;
      case 1001502009:
        this.message = '服务内部错误，请稍后重试';
        break;
      default:
        this.message = `验证失败: ${error.message}`;
    }
  }

  restoreMinorsModeStatus(): void {
    hilog.info(DOMAIN, TAG, `Restoring minors mode status, userTurnOffFlag: ${this.userTurnOffFlag}`);

    if (this.userTurnOffFlag) {
      this.message = '应用的未成年人模式保持关闭状态（用户之前主动关闭）';
      hilog.info(DOMAIN, TAG, 'App minors mode remains off as user requested');
    } else {
      this.getMinorsModeStatus();
    }
  }

  build() {
    Column() {
      Text('未成年人模式管理示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 });

      Text(`系统未成年人模式状态: ${this.minorsProtectionMode ? '已开启' : '已关闭'}`)
        .fontSize(16)
        .margin({ bottom: 10 });

      if (this.minorsProtectionMode) {
        Text(`年龄段信息: ${this.ageGroupInfo}`)
          .fontSize(16)
          .margin({ bottom: 10 });
      }

      Text(`应用单独关闭标记: ${this.userTurnOffFlag ? '已关闭' : '未关闭'}`)
        .fontSize(16)
        .margin({ bottom: 10 });

      Divider().margin({ bottom: 20 });

      Text(this.message)
        .fontSize(14)
        .margin({ bottom: 20 })
        .textAlign(TextAlign.Center);

      Button('获取未成年人模式状态')
        .width('80%')
        .onClick(() => {
          this.getMinorsModeStatus();
        })
        .margin({ bottom: 10 });

      Button('验证密码并关闭应用未成年人模式')
        .width('80%')
        .enabled(this.minorsProtectionMode && !this.userTurnOffFlag)
        .onClick(() => {
          this.verifyAndTurnOffAppMinorsMode();
        })
        .margin({ bottom: 10 });

      Button('恢复状态')
        .width('80%')
        .onClick(() => {
          this.restoreMinorsModeStatus();
        })
        .margin({ bottom: 10 });

      if (this.userTurnOffFlag) {
        Text('提示：当前仅关闭应用的未成年人模式，但系统的未成年人模式仍保持开启')
          .fontSize(12)
          .fontColor('#FF9800')
          .margin({ top: 20 });
      }
    }
    .width('100%')
    .height('100%')
    .padding(20);
  }
}