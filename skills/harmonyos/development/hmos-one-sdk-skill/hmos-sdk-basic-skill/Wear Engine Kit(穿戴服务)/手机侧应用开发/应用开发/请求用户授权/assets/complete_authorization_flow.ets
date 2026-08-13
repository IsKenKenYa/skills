/**
 * 完整授权流程示例代码
 * 演示完整的授权流程：查询 -> 申请 -> 检查 -> 使用
 */
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

/**
 * 完整的授权管理类
 * 提供完整的授权流程管理和错误处理
 */
export class WearEngineAuthorizationManager {
  private authClient: wearEngine.AuthClient;
  private context: common.Context;
  
  constructor(context: common.Context) {
    this.context = context;
    this.authClient = wearEngine.getAuthClient(context);
  }
  
  /**
   * 完整授权流程：查询 -> 申请 -> 验证
   * @param requiredPermissions - 需要的权限列表
   * @returns 是否成功获得所有所需权限
   */
  async ensurePermissionsGranted(requiredPermissions: wearEngine.Permission[]): Promise<boolean> {
    console.info('[AuthManager] === Starting authorization flow ===');
    console.info(`[AuthManager] Required permissions: ${JSON.stringify(requiredPermissions)}`);
    
    // 步骤1：查询当前授权状态
    console.info('[AuthManager] Step 1: Querying current authorization');
    let currentPermissions: wearEngine.Permission[] = [];
    
    try {
      const response = await this.authClient.getAuthorization();
      currentPermissions = response.permissions;
      console.info(`[AuthManager] Current permissions: ${JSON.stringify(currentPermissions)}`);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[AuthManager] Failed to query: ${err.code}`);
      
      // 如果查询失败（如网络错误），尝试继续申请流程
      if (err.code !== 1008500001 && err.code !== 1008500008) {
        // 非网络或账号错误，直接返回失败
        return false;
      }
    }
    
    // 步骤2：检查是否已有所需权限
    console.info('[AuthManager] Step 2: Checking required permissions');
    const missingPermissions = requiredPermissions.filter(
      perm => !currentPermissions.includes(perm)
    );
    
    if (missingPermissions.length === 0) {
      console.info('[AuthManager] All required permissions already granted');
      console.info('[AuthManager] === Authorization flow completed successfully ===');
      return true;
    }
    
    console.info(`[AuthManager] Missing permissions: ${JSON.stringify(missingPermissions)}`);
    
    // 步骤3：申请缺失的权限
    console.info('[AuthManager] Step 3: Requesting missing permissions');
    const request: wearEngine.AuthorizationRequest = {
      permissions: missingPermissions
    };
    
    try {
      const response = await this.authClient.requestAuthorization(request);
      console.info(`[AuthManager] Authorization response: ${JSON.stringify(response.permissions)}`);
      
      // 步骤4：验证授权结果
      console.info('[AuthManager] Step 4: Verifying authorization result');
      const stillMissing = missingPermissions.filter(
        perm => !response.permissions.includes(perm)
      );
      
      if (stillMissing.length === 0) {
        console.info('[AuthManager] All requested permissions granted');
        console.info('[AuthManager] === Authorization flow completed successfully ===');
        return true;
      } else {
        console.warn(`[AuthManager] User denied: ${JSON.stringify(stillMissing)}`);
        console.info('[AuthManager] === Authorization flow completed with partial success ===');
        
        // 处理用户拒绝的情况
        this.handleUserDeniedPermissions(stillMissing);
        return false;
      }
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[AuthManager] Failed to request: ${err.code}`);
      console.info('[AuthManager] === Authorization flow failed ===');
      
      // 处理申请失败
      this.handleRequestError(err);
      return false;
    }
  }
  
  /**
   * 处理用户拒绝授权
   */
  private handleUserDeniedPermissions(deniedPermissions: wearEngine.Permission[]): void {
    console.warn('[AuthManager] Handling user denied permissions');
    
    for (const permission of deniedPermissions) {
      switch (permission) {
        case wearEngine.Permission.USER_STATUS:
          console.warn('[AuthManager] USER_STATUS denied - wear status features limited');
          break;
        case wearEngine.Permission.MOTION_SENSOR:
          console.warn('[AuthManager] MOTION_SENSOR denied - motion data features limited');
          break;
        case wearEngine.Permission.HEALTH_SENSOR:
          console.warn('[AuthManager] HEALTH_SENSOR denied - health data features limited');
          break;
        case wearEngine.Permission.DEVICE_IDENTIFIER:
          console.warn('[AuthManager] DEVICE_IDENTIFIER denied - device info features limited');
          break;
      }
    }
    
    // 可以在这里提示用户权限的重要性
    // 或者提供降级功能
  }
  
  /**
   * 处理授权请求错误
   */
  private handleRequestError(error: BusinessError): void {
    console.error('[AuthManager] Handling authorization request error');
    
    switch (error.code) {
      case 401:
        console.error('[AuthManager] Parameter error - check request parameters');
        this.showParameterErrorPrompt();
        break;
        
      case 801:
        console.error('[AuthManager] Device not supported - use Phone/Tablet only');
        this.showDeviceNotSupportedPrompt();
        break;
        
      case 1008500001:
        console.error('[AuthManager] Network error - check network connection');
        this.showNetworkErrorPrompt();
        break;
        
      case 1008500004:
        console.error('[AuthManager] App not applied for service');
        this.showServiceNotAppliedPrompt();
        break;
        
      case 1008500006:
        console.error('[AuthManager] User privacy not agreed');
        this.showPrivacyNotAgreedPrompt();
        break;
        
      case 1008500007:
        console.error('[AuthManager] Device capability not supported');
        this.showCapabilityNotSupportedPrompt();
        break;
        
      case 1008500008:
        console.error('[AuthManager] User not logged in');
        // 这个错误通常会自动弹出登录界面
        console.info('[AuthManager] Login prompt should appear automatically');
        break;
        
      case 1008500009:
        console.error('[AuthManager] Account error - use China registered account');
        this.showAccountErrorPrompt();
        break;
        
      case 1008509999:
        console.error('[AuthManager] Internal error');
        this.showInternalErrorPrompt();
        break;
        
      default:
        console.error(`[AuthManager] Unknown error: ${error.code}`);
        this.showUnknownErrorPrompt();
    }
  }
  
  // 错误提示函数（实际应用中应显示UI提示）
  private showParameterErrorPrompt(): void {
    console.warn('[AuthManager] Prompt: Invalid parameters');
  }
  
  private showDeviceNotSupportedPrompt(): void {
    console.warn('[AuthManager] Prompt: Device not supported');
  }
  
  private showNetworkErrorPrompt(): void {
    console.warn('[AuthManager] Prompt: Network unavailable');
  }
  
  private showServiceNotAppliedPrompt(): void {
    console.warn('[AuthManager] Prompt: Apply for Wear Engine service first');
  }
  
  private showPrivacyNotAgreedPrompt(): void {
    console.warn('[AuthManager] Prompt: Open Health app for privacy authorization');
  }
  
  private showCapabilityNotSupportedPrompt(): void {
    console.warn('[AuthManager] Prompt: Device capability not supported');
  }
  
  private showAccountErrorPrompt(): void {
    console.warn('[AuthManager] Prompt: Use China registered account');
  }
  
  private showInternalErrorPrompt(): void {
    console.warn('[AuthManager] Prompt: Internal error, check clientId and signature');
  }
  
  private showUnknownErrorPrompt(): void {
    console.warn('[AuthManager] Prompt: Unknown error occurred');
  }
  
  /**
   * 获取当前授权状态的详细信息
   */
  async getAuthorizationDetails(): Promise<AuthorizationDetails> {
    console.info('[AuthManager] Getting authorization details');
    
    const allPermissions: wearEngine.Permission[] = [
      wearEngine.Permission.USER_STATUS,
      wearEngine.Permission.MOTION_SENSOR,
      wearEngine.Permission.HEALTH_SENSOR,
      wearEngine.Permission.DEVICE_IDENTIFIER
    ];
    
    try {
      const response = await this.authClient.getAuthorization();
      const authorizedPermissions = response.permissions;
      
      // 构建详细的权限状态映射
      const permissionStatus: Map<wearEngine.Permission, PermissionStatus> = new Map();
      
      for (const permission of allPermissions) {
        const isGranted = authorizedPermissions.includes(permission);
        permissionStatus.set(permission, {
          permission: permission,
          name: this.getPermissionDisplayName(permission),
          isGranted: isGranted,
          description: this.getPermissionDescription(permission)
        });
      }
      
      const details: AuthorizationDetails = {
        authorizedPermissions: authorizedPermissions,
        permissionStatus: permissionStatus,
        totalPermissions: allPermissions.length,
        grantedCount: authorizedPermissions.length,
        lastQueryTime: new Date().toISOString()
      };
      
      console.info(`[AuthManager] Authorization details: ${JSON.stringify(details)}`);
      return details;
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[AuthManager] Failed to get details: ${err.code}`);
      throw err;
    }
  }
  
  /**
   * 获取权限显示名称
   */
  private getPermissionDisplayName(permission: wearEngine.Permission): string {
    const names = {
      [wearEngine.Permission.USER_STATUS]: '用户状态权限',
      [wearEngine.Permission.MOTION_SENSOR]: '运动传感器权限',
      [wearEngine.Permission.HEALTH_SENSOR]: '健康传感器权限',
      [wearEngine.Permission.DEVICE_IDENTIFIER]: '设备标识符权限'
    };
    return names[permission] || '未知权限';
  }
  
  /**
   * 获取权限描述
   */
  private getPermissionDescription(permission: wearEngine.Permission): string {
    const descriptions = {
      [wearEngine.Permission.USER_STATUS]: '用于查询穿戴设备的佩戴状态',
      [wearEngine.Permission.MOTION_SENSOR]: '用于获取运动传感器数据，如加速度传感器',
      [wearEngine.Permission.HEALTH_SENSOR]: '用于获取健康传感器数据，如心率传感器',
      [wearEngine.Permission.DEVICE_IDENTIFIER]: '用于获取已连接穿戴设备的序列号'
    };
    return descriptions[permission] || '未知权限';
  }
  
  /**
   * 检查特定功能是否可用
   */
  async isFeatureAvailable(featureName: string): Promise<boolean> {
    console.info(`[AuthManager] Checking feature availability: ${featureName}`);
    
    const featurePermissionMapping: Record<string, wearEngine.Permission> = {
      'wear_status_query': wearEngine.Permission.USER_STATUS,
      'motion_data_access': wearEngine.Permission.MOTION_SENSOR,
      'health_data_access': wearEngine.Permission.HEALTH_SENSOR,
      'device_info_access': wearEngine.Permission.DEVICE_IDENTIFIER
    };
    
    const requiredPermission = featurePermissionMapping[featureName];
    if (!requiredPermission) {
      console.warn(`[AuthManager] Unknown feature: ${featureName}`);
      return false;
    }
    
    try {
      const response = await this.authClient.getAuthorization();
      const hasPermission = response.permissions.includes(requiredPermission);
      
      console.info(`[AuthManager] Feature ${featureName} availability: ${hasPermission}`);
      return hasPermission;
      
    } catch (error) {
      console.error(`[AuthManager] Failed to check feature: ${featureName}`);
      return false;
    }
  }
}

/**
 * 授权状态详情结构
 */
interface AuthorizationDetails {
  authorizedPermissions: wearEngine.Permission[];
  permissionStatus: Map<wearEngine.Permission, PermissionStatus>;
  totalPermissions: number;
  grantedCount: number;
  lastQueryTime: string;
}

/**
 * 权限状态结构
 */
interface PermissionStatus {
  permission: wearEngine.Permission;
  name: string;
  isGranted: boolean;
  description: string;
}

/**
 * 使用示例：完整的授权流程
 */
async function exampleCompleteAuthorizationFlow(context: common.Context): Promise<void> {
  console.info('=== Starting complete authorization flow example ===');
  
  const authManager = new WearEngineAuthorizationManager(context);
  
  // 定义需要的权限
  const requiredPermissions: wearEngine.Permission[] = [
    wearEngine.Permission.USER_STATUS,
    wearEngine.Permission.HEALTH_SENSOR
  ];
  
  // 执行完整授权流程
  const success = await authManager.ensurePermissionsGranted(requiredPermissions);
  
  if (success) {
    console.info('=== Authorization successful, proceeding with Wear Engine features ===');
    
    // 获取详细授权信息
    const details = await authManager.getAuthorizationDetails();
    console.info(`Authorized: ${details.grantedCount}/${details.totalPermissions} permissions`);
    
    // 检查特定功能是否可用
    const wearStatusAvailable = await authManager.isFeatureAvailable('wear_status_query');
    console.info(`Wear status query available: ${wearStatusAvailable}`);
    
    // 继续使用Wear Engine功能
    // ...
    
  } else {
    console.warn('=== Authorization failed or partial, showing limited features ===');
    
    // 显示功能受限的界面
    // ...
  }
  
  console.info('=== Authorization flow example completed ===');
}

/**
 * 在UIAbility中的完整使用示例
 */
export class MainAbility extends common.UIAbility {
  private authManager: WearEngineAuthorizationManager | null = null;
  
  onCreate(want: common.Want, launchParam: common.AbilityConstant.LaunchParam): void {
    console.info('[MainAbility] onCreate');
    
    // 初始化授权管理器
    this.authManager = new WearEngineAuthorizationManager(this.context);
    
    // 执行授权流程
    this.performAuthorization();
  }
  
  private async performAuthorization(): Promise<void> {
    if (!this.authManager) {
      console.error('[MainAbility] AuthManager not initialized');
      return;
    }
    
    const requiredPermissions: wearEngine.Permission[] = [
      wearEngine.Permission.USER_STATUS,
      wearEngine.Permission.HEALTH_SENSOR,
      wearEngine.Permission.DEVICE_IDENTIFIER
    ];
    
    try {
      const authorized = await this.authManager.ensurePermissionsGranted(requiredPermissions);
      
      if (authorized) {
        console.info('[MainAbility] Authorization successful');
        this.startWearEngineFeatures();
      } else {
        console.warn('[MainAbility] Authorization incomplete');
        this.startLimitedFeatures();
      }
      
    } catch (error) {
      console.error('[MainAbility] Authorization error');
      this.startFallbackMode();
    }
  }
  
  private startWearEngineFeatures(): void {
    console.info('[MainAbility] Starting full Wear Engine features');
    // 在这里启动完整的Wear Engine功能
  }
  
  private startLimitedFeatures(): void {
    console.warn('[MainAbility] Starting limited features');
    // 在这里启动功能受限模式
  }
  
  private startFallbackMode(): void {
    console.error('[MainAbility] Starting fallback mode');
    // 在这里启动降级模式或离线模式
  }
}