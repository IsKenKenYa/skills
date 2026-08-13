/**
 * 查询用户授权结果示例代码
 * 演示如何使用AuthClient.getAuthorization查询已授权的权限
 */
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

/**
 * 示例1：查询当前已授权的权限
 */
async function getCurrentAuthorization(context: common.Context): Promise<wearEngine.Permission[]> {
  console.info('[WearEngine] Querying current authorization status');
  
  // 获取AuthClient
  const authClient: wearEngine.AuthClient = wearEngine.getAuthClient(context);
  
  try {
    // 调用getAuthorization
    const response: wearEngine.AuthorizationResponse = await authClient.getAuthorization();
    
    console.info(`[WearEngine] Current authorized permissions: ${JSON.stringify(response.permissions)}`);
    return response.permissions;
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`[WearEngine] Failed to get authorization. Code: ${err.code}, Message: ${err.message}`);
    throw err;
  }
}

/**
 * 示例2：检查是否拥有特定权限
 */
async function hasPermission(
  context: common.Context,
  targetPermission: wearEngine.Permission
): Promise<boolean> {
  console.info(`[WearEngine] Checking permission: ${targetPermission}`);
  
  const authClient: wearEngine.AuthClient = wearEngine.getAuthClient(context);
  
  try {
    const response = await authClient.getAuthorization();
    const hasPermission = response.permissions.includes(targetPermission);
    
    console.info(`[WearEngine] Permission ${targetPermission} status: ${hasPermission ? 'granted' : 'not granted'}`);
    return hasPermission;
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`[WearEngine] Failed to check permission: ${err.code}`);
    throw err;
  }
}

/**
 * 示例3：查询授权状态并根据结果决定是否申请新权限
 */
async function checkAndRequestIfNeeded(context: common.Context): Promise<void> {
  console.info('[WearEngine] Checking and requesting permissions');
  
  const authClient: wearEngine.AuthClient = wearEngine.getAuthClient(context);
  
  // 定义需要的权限
  const requiredPermissions: wearEngine.Permission[] = [
    wearEngine.Permission.USER_STATUS,
    wearEngine.Permission.MOTION_SENSOR
  ];
  
  try {
    // 先查询已授权的权限
    const currentAuth = await authClient.getAuthorization();
    console.info(`[WearEngine] Currently authorized: ${JSON.stringify(currentAuth.permissions)}`);
    
    // 过滤出未授权的权限
    const missingPermissions = requiredPermissions.filter(
      perm => !currentAuth.permissions.includes(perm)
    );
    
    if (missingPermissions.length === 0) {
      console.info('[WearEngine] All required permissions are already granted');
      // 可以直接使用Wear Engine功能
      proceedWithWearEngineAPIs();
    } else {
      console.info(`[WearEngine] Missing permissions: ${JSON.stringify(missingPermissions)}`);
      console.info('[WearEngine] Requesting missing permissions...');
      
      // 申请缺失的权限
      const request: wearEngine.AuthorizationRequest = {
        permissions: missingPermissions
      };
      
      const newAuth = await authClient.requestAuthorization(request);
      console.info(`[WearEngine] New authorization result: ${JSON.stringify(newAuth.permissions)}`);
      
      // 再次检查是否全部授权
      const stillMissing = missingPermissions.filter(
        perm => !newAuth.permissions.includes(perm)
      );
      
      if (stillMissing.length > 0) {
        console.warn(`[WearEngine] User denied some permissions: ${JSON.stringify(stillMissing)}`);
        // 处理用户拒绝授权的情况
        handleDeniedPermissions(stillMissing);
      } else {
        console.info('[WearEngine] All missing permissions granted');
        proceedWithWearEngineAPIs();
      }
    }
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`[WearEngine] Error: ${err.code}`);
    handleGetAuthorizationError(err);
  }
}

function proceedWithWearEngineAPIs(): void {
  console.info('[WearEngine] Proceeding with Wear Engine APIs');
  // 在这里调用Wear Engine的其他API
}

function handleDeniedPermissions(deniedPermissions: wearEngine.Permission[]): void {
  console.warn(`[WearEngine] Handling denied permissions: ${JSON.stringify(deniedPermissions)}`);
  // 提示用户权限的重要性，或提供降级功能
}

function handleGetAuthorizationError(error: BusinessError): void {
  switch (error.code) {
    case 1008500001:
      console.error('[WearEngine] Network unavailable');
      break;
    case 1008500004:
      console.error('[WearEngine] App has not applied for Wear Engine service');
      break;
    case 1008500006:
      console.error('[WearEngine] User privacy not agreed');
      break;
    case 1008500008:
      console.error('[WearEngine] User not logged in');
      break;
    case 1008500009:
      console.error('[WearEngine] Account error');
      break;
    default:
      console.error(`[WearEngine] Unknown error: ${error.code}`);
  }
}

/**
 * 示例4：权限检查工具类
 */
export class PermissionChecker {
  private authClient: wearEngine.AuthClient;
  
  constructor(context: common.Context) {
    this.authClient = wearEngine.getAuthClient(context);
  }
  
  /**
   * 检查单个权限是否已授权
   */
  async isPermissionGranted(permission: wearEngine.Permission): Promise<boolean> {
    try {
      const response = await this.authClient.getAuthorization();
      return response.permissions.includes(permission);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[PermissionChecker] Check failed: ${err.code}`);
      return false;
    }
  }
  
  /**
   * 检查多个权限是否已授权
   */
  async arePermissionsGranted(permissions: wearEngine.Permission[]): Promise<Map<wearEngine.Permission, boolean>> {
    const resultMap = new Map<wearEngine.Permission, boolean>();
    
    try {
      const response = await this.authClient.getAuthorization();
      
      for (const permission of permissions) {
        resultMap.set(permission, response.permissions.includes(permission));
      }
      
      return resultMap;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[PermissionChecker] Check failed: ${err.code}`);
      
      // 返回所有权限为false
      for (const permission of permissions) {
        resultMap.set(permission, false);
      }
      
      return resultMap;
    }
  }
  
  /**
   * 获取所有未授权的权限
   */
  async getMissingPermissions(requiredPermissions: wearEngine.Permission[]): Promise<wearEngine.Permission[]> {
    try {
      const response = await this.authClient.getAuthorization();
      return requiredPermissions.filter(p => !response.permissions.includes(p));
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`[PermissionChecker] Get missing permissions failed: ${err.code}`);
      return requiredPermissions; // 如果查询失败，假设所有权限都未授权
    }
  }
  
  /**
   * 打印权限状态报告
   */
  async printPermissionReport(): Promise<void> {
    const allPermissions: wearEngine.Permission[] = [
      wearEngine.Permission.USER_STATUS,
      wearEngine.Permission.MOTION_SENSOR,
      wearEngine.Permission.HEALTH_SENSOR,
      wearEngine.Permission.DEVICE_IDENTIFIER
    ];
    
    try {
      const response = await this.authClient.getAuthorization();
      
      console.info('[PermissionChecker] === Permission Status Report ===');
      for (const permission of allPermissions) {
        const isGranted = response.permissions.includes(permission);
        console.info(`[PermissionChecker] ${permission}: ${isGranted ? 'GRANTED' : 'NOT GRANTED'}`);
      }
      console.info('[PermissionChecker] === End of Report ===');
      
    } catch (error) {
      console.error('[PermissionChecker] Failed to generate report');
    }
  }
}

/**
 * 示例5：在页面中使用查询授权结果
 */
import { UIAbility } from '@kit.AbilityKit';

@Entry
@Component
struct AuthorizationStatusPage {
  @State authorizedPermissions: string[] = [];
  @State isLoading: boolean = true;
  
  private permissionChecker: PermissionChecker | null = null;
  
  aboutToAppear(): void {
    // 初始化权限检查器
    const context = getContext(this) as common.UIAbilityContext;
    this.permissionChecker = new PermissionChecker(context);
    
    // 查询授权状态
    this.queryAuthorizationStatus();
  }
  
  private async queryAuthorizationStatus(): Promise<void> {
    this.isLoading = true;
    
    try {
      const authClient: wearEngine.AuthClient = wearEngine.getAuthClient(getContext(this) as common.UIAbilityContext);
      const response = await authClient.getAuthorization();
      
      this.authorizedPermissions = response.permissions.map(p => this.getPermissionName(p));
      this.isLoading = false;
      
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`Failed to query: ${err.code}`);
      this.isLoading = false;
    }
  }
  
  private getPermissionName(permission: wearEngine.Permission): string {
    switch (permission) {
      case wearEngine.Permission.USER_STATUS:
        return '用户状态';
      case wearEngine.Permission.MOTION_SENSOR:
        return '运动传感器';
      case wearEngine.Permission.HEALTH_SENSOR:
        return '健康传感器';
      case wearEngine.Permission.DEVICE_IDENTIFIER:
        return '设备标识符';
      default:
        return '未知权限';
    }
  }
  
  build() {
    Column() {
      Text('授权状态')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
      
      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
      } else {
        if (this.authorizedPermissions.length > 0) {
          Text('已授权的权限:')
            .fontSize(18)
            .margin({ bottom: 10 })
          
          ForEach(this.authorizedPermissions, (permission: string) => {
            Text(permission)
              .fontSize(16)
              .margin({ bottom: 5 })
          })
        } else {
          Text('暂无已授权的权限')
            .fontSize(18)
            .fontColor(Color.Gray)
        }
        
        Button('刷新授权状态')
          .margin({ top: 20 })
          .onClick(() => {
            this.queryAuthorizationStatus();
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}

/**
 * 示例6：定时检查授权状态（用于监测权限变化）
 */
class AuthorizationMonitor {
  private authClient: wearEngine.AuthClient;
  private monitorInterval: number = 30000; // 30秒检查一次
  private intervalId: number | null = null;
  private lastPermissions: wearEngine.Permission[] = [];
  
  constructor(context: common.Context) {
    this.authClient = wearEngine.getAuthClient(context);
  }
  
  startMonitoring(): void {
    console.info('[AuthorizationMonitor] Starting authorization monitoring');
    
    this.intervalId = setInterval(async () => {
      try {
        const response = await this.authClient.getAuthorization();
        const currentPermissions = response.permissions;
        
        // 检查权限是否发生变化
        if (this.hasPermissionsChanged(currentPermissions)) {
          console.info('[AuthorizationMonitor] Permissions changed detected');
          console.info(`[AuthorizationMonitor] Old: ${JSON.stringify(this.lastPermissions)}`);
          console.info(`[AuthorizationMonitor] New: ${JSON.stringify(currentPermissions)}`);
          
          // 触发权限变化事件
          this.onPermissionsChanged(currentPermissions);
          
          // 更新上次权限记录
          this.lastPermissions = currentPermissions;
        }
      } catch (error) {
        console.error('[AuthorizationMonitor] Monitoring error');
      }
    }, this.monitorInterval);
  }
  
  stopMonitoring(): void {
    if (this.intervalId !== null) {
      clearInterval(this.intervalId);
      this.intervalId = null;
      console.info('[AuthorizationMonitor] Monitoring stopped');
    }
  }
  
  private hasPermissionsChanged(newPermissions: wearEngine.Permission[]): boolean {
    if (this.lastPermissions.length !== newPermissions.length) {
      return true;
    }
    
    // 检查权限列表是否一致（顺序可能不同）
    for (const perm of newPermissions) {
      if (!this.lastPermissions.includes(perm)) {
        return true;
      }
    }
    
    return false;
  }
  
  private onPermissionsChanged(newPermissions: wearEngine.Permission[]): void {
    console.info('[AuthorizationMonitor] Permissions changed event triggered');
    // 在这里处理权限变化逻辑，例如：
    // - 更新UI显示
    // - 重新初始化相关功能
    // - 通知其他组件
  }
}