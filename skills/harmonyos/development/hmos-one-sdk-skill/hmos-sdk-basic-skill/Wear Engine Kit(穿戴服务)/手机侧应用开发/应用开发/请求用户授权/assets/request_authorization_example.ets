/**
 * 申请用户授权示例代码
 * 演示如何使用wearEngine.requestAuthorization向用户申请穿戴设备权限
 */
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

/**
 * 示例1：在UIAbility中申请单个权限
 */
export class EntryAbility extends common.UIAbility {
  async onCreate(want: common.Want, launchParam: common.AbilityConstant.LaunchParam): void {
    console.info('[WearEngine] EntryAbility onCreate');
    
    // 获取AuthClient
    const authClient: wearEngine.AuthClient = wearEngine.getAuthClient(this.context);
    console.info('[WearEngine] Succeeded in getting auth client');
    
    // 定义权限请求（申请用户状态权限）
    const request: wearEngine.AuthorizationRequest = {
      permissions: [wearEngine.Permission.USER_STATUS]
    };
    
    // 调用requestAuthorization
    authClient.requestAuthorization(request).then((result: wearEngine.AuthorizationResponse) => {
      console.info(`[WearEngine] Succeeded in requesting authorization`);
      console.info(`[WearEngine] Authorized permissions: ${JSON.stringify(result.permissions)}`);
      
      // 检查是否获得授权
      if (result.permissions.includes(wearEngine.Permission.USER_STATUS)) {
        console.info('[WearEngine] USER_STATUS permission granted');
        // 可以继续调用其他Wear Engine API
        this.proceedWithWearEngineFeatures();
      } else {
        console.warn('[WearEngine] USER_STATUS permission denied');
        // 提示用户功能受限
        this.showLimitedFeaturesPrompt();
      }
    }).catch((error: BusinessError) => {
      console.error(`[WearEngine] Failed to request authorization. Code: ${error.code}, Message: ${error.message}`);
      this.handleAuthorizationError(error);
    });
  }
  
  private proceedWithWearEngineFeatures(): void {
    console.info('[WearEngine] Proceeding with Wear Engine features...');
    // 在这里调用其他Wear Engine API
  }
  
  private showLimitedFeaturesPrompt(): void {
    console.warn('[WearEngine] Some features will be limited due to missing permissions');
  }
  
  private handleAuthorizationError(error: BusinessError): void {
    switch (error.code) {
      case 401:
        console.error('[WearEngine] Parameter error');
        break;
      case 801:
        console.error('[WearEngine] Device not supported');
        break;
      case 1008500001:
        console.error('[WearEngine] Network error');
        break;
      case 1008500004:
        console.error('[WearEngine] App has not applied for Wear Engine service');
        break;
      case 1008500006:
        console.error('[WearEngine] User privacy not agreed');
        break;
      case 1008500008:
        console.error('[WearEngine] User not logged in with HUAWEI ID');
        break;
      case 1008500009:
        console.error('[WearEngine] Account error');
        break;
      default:
        console.error(`[WearEngine] Unknown error: ${error.code}`);
    }
  }
}

/**
 * 示例2：申请多个权限
 */
async function requestMultiplePermissions(context: common.Context): Promise<wearEngine.Permission[]> {
  const authClient: wearEngine.AuthClient = wearEngine.getAuthClient(context);
  
  // 定义多个权限请求
  const request: wearEngine.AuthorizationRequest = {
    permissions: [
      wearEngine.Permission.USER_STATUS,
      wearEngine.Permission.MOTION_SENSOR,
      wearEngine.Permission.HEALTH_SENSOR
    ]
  };
  
  try {
    const response: wearEngine.AuthorizationResponse = await authClient.requestAuthorization(request);
    console.info(`[WearEngine] Authorized permissions: ${JSON.stringify(response.permissions)}`);
    return response.permissions;
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`[WearEngine] Failed to request authorization: ${err.code}`);
    throw err;
  }
}

/**
 * 示例3：动态申请权限（根据业务需求）
 */
async function requestPermissionsDynamically(
  context: common.Context,
  requiredFeatures: string[]
): Promise<void> {
  const authClient: wearEngine.AuthClient = wearEngine.getAuthClient(context);
  
  // 根据业务需求确定需要申请的权限
  const permissions: wearEngine.Permission[] = [];
  
  if (requiredFeatures.includes('wear_status')) {
    permissions.push(wearEngine.Permission.USER_STATUS);
  }
  
  if (requiredFeatures.includes('motion_data')) {
    permissions.push(wearEngine.Permission.MOTION_SENSOR);
  }
  
  if (requiredFeatures.includes('health_data')) {
    permissions.push(wearEngine.Permission.HEALTH_SENSOR);
  }
  
  if (requiredFeatures.includes('device_info')) {
    permissions.push(wearEngine.Permission.DEVICE_IDENTIFIER);
  }
  
  if (permissions.length === 0) {
    console.warn('[WearEngine] No permissions required');
    return;
  }
  
  const request: wearEngine.AuthorizationRequest = {
    permissions: permissions
  };
  
  try {
    const response = await authClient.requestAuthorization(request);
    console.info(`[WearEngine] Successfully authorized: ${JSON.stringify(response.permissions)}`);
    
    // 检查是否获得全部所需权限
    const missingPermissions = permissions.filter(p => !response.permissions.includes(p));
    if (missingPermissions.length > 0) {
      console.warn(`[WearEngine] Missing permissions: ${JSON.stringify(missingPermissions)}`);
    }
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`[WearEngine] Authorization failed: ${err.code}`);
    throw err;
  }
}

/**
 * 示例4：检查权限申请状态并提示用户
 */
async function requestWithUserPrompt(context: common.Context): Promise<void> {
  const authClient: wearEngine.AuthClient = wearEngine.getAuthClient(context);
  
  // 先查询已授权的权限
  try {
    const currentAuth = await authClient.getAuthorization();
    console.info(`[WearEngine] Current authorized permissions: ${JSON.stringify(currentAuth.permissions)}`);
    
    // 检查是否已有USER_STATUS权限
    if (!currentAuth.permissions.includes(wearEngine.Permission.USER_STATUS)) {
      console.info('[WearEngine] USER_STATUS not authorized, requesting...');
      
      // 申请权限
      const request: wearEngine.AuthorizationRequest = {
        permissions: [wearEngine.Permission.USER_STATUS]
      };
      
      const newAuth = await authClient.requestAuthorization(request);
      
      if (newAuth.permissions.includes(wearEngine.Permission.USER_STATUS)) {
        console.info('[WearEngine] USER_STATUS permission newly granted');
      } else {
        console.warn('[WearEngine] USER_STATUS permission still denied');
        // 提示用户权限的重要性
        showPermissionImportancePrompt();
      }
    } else {
      console.info('[WearEngine] USER_STATUS already authorized');
    }
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`[WearEngine] Error: ${err.code}`);
    throw err;
  }
}

function showPermissionImportancePrompt(): void {
  console.warn('[WearEngine] Please note: USER_STATUS permission is required for device wear status detection');
  // 在实际应用中，这里可以显示一个对话框提示用户权限的重要性
}

/**
 * 示例5：处理用户部分授权的场景
 */
async function handlePartialAuthorization(context: common.Context): Promise<void> {
  const authClient: wearEngine.AuthClient = wearEngine.getAuthClient(context);
  
  // 申请多个权限
  const request: wearEngine.AuthorizationRequest = {
    permissions: [
      wearEngine.Permission.USER_STATUS,
      wearEngine.Permission.HEALTH_SENSOR,
      wearEngine.Permission.DEVICE_IDENTIFIER
    ]
  };
  
  try {
    const response = await authClient.requestAuthorization(request);
    
    // 分析授权结果
    const requestedPermissions = request.permissions;
    const grantedPermissions = response.permissions;
    const deniedPermissions = requestedPermissions.filter(p => !grantedPermissions.includes(p));
    
    console.info(`[WearEngine] Granted: ${JSON.stringify(grantedPermissions)}`);
    
    if (deniedPermissions.length > 0) {
      console.warn(`[WearEngine] Denied: ${JSON.stringify(deniedPermissions)}`);
      
      // 对于拒绝的权限，提供替代方案或功能受限说明
      if (deniedPermissions.includes(wearEngine.Permission.HEALTH_SENSOR)) {
        console.warn('[WearEngine] Health sensor features will be limited');
        // 提供替代方案或降级功能
      }
      
      if (deniedPermissions.includes(wearEngine.Permission.DEVICE_IDENTIFIER)) {
        console.warn('[WearEngine] Device identification features will be limited');
      }
    }
    
    // 根据实际授权的权限继续业务逻辑
    proceedWithGrantedPermissions(grantedPermissions);
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`[WearEngine] Authorization error: ${err.code}`);
    throw err;
  }
}

function proceedWithGrantedPermissions(grantedPermissions: wearEngine.Permission[]): void {
  console.info(`[WearEngine] Proceeding with granted permissions: ${JSON.stringify(grantedPermissions)}`);
  
  // 根据实际授权的权限调用相应的API
  if (grantedPermissions.includes(wearEngine.Permission.USER_STATUS)) {
    console.info('[WearEngine] Can query wear status');
    // 调用wear status相关API
  }
  
  if (grantedPermissions.includes(wearEngine.Permission.HEALTH_SENSOR)) {
    console.info('[WearEngine] Can access health sensor data');
    // 调用health sensor相关API
  }
}