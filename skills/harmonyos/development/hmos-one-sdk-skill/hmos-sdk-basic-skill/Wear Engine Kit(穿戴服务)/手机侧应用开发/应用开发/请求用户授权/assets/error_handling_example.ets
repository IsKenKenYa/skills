/**
 * 错误处理示例代码
 * 演示如何处理Wear Engine授权相关的各种错误场景
 */
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

/**
 * 错误处理器类
 * 提供统一的错误处理和降级方案
 */
export class AuthorizationErrorHandler {
  private context: common.Context;
  
  constructor(context: common.Context) {
    this.context = context;
  }
  
  /**
   * 处理getAuthClient错误
   */
  handleGetAuthClientError(error: BusinessError): ErrorHandlingResult {
    console.error(`[ErrorHandler] getAuthClient error: ${error.code}`);
    
    const result: ErrorHandlingResult = {
      errorCode: error.code,
      errorMessage: error.message,
      userMessage: '',
      shouldRetry: false,
      fallbackAction: null
    };
    
    switch (error.code) {
      case 401:
        result.userMessage = '参数错误，请检查Context参数是否正确';
        result.shouldRetry = false;
        result.fallbackAction = () => this.fixContextParameter();
        break;
        
      case 801:
        result.userMessage = '当前设备不支持Wear Engine，请使用手机或平板';
        result.shouldRetry = false;
        result.fallbackAction = () => this.showDeviceNotSupportedUI();
        break;
        
      case 1008509999:
        result.userMessage = '内部错误，请检查应用配置';
        result.shouldRetry = true;
        result.retryDelay = 2000;
        result.fallbackAction = () => this.checkInternalConfiguration();
        break;
        
      default:
        result.userMessage = `未知错误: ${error.code}`;
        result.shouldRetry = false;
        result.fallbackAction = () => this.showGenericErrorUI();
    }
    
    return result;
  }
  
  /**
   * 处理requestAuthorization错误
   */
  handleRequestAuthorizationError(error: BusinessError): ErrorHandlingResult {
    console.error(`[ErrorHandler] requestAuthorization error: ${error.code}`);
    
    const result: ErrorHandlingResult = {
      errorCode: error.code,
      errorMessage: error.message,
      userMessage: '',
      shouldRetry: false,
      fallbackAction: null
    };
    
    switch (error.code) {
      case 401:
        result.userMessage = '参数错误，请检查权限请求参数';
        result.shouldRetry = false;
        result.fallbackAction = () => this.fixRequestParameter();
        break;
        
      case 1008500001:
        result.userMessage = '网络不可用，请检查网络连接后重试';
        result.shouldRetry = true;
        result.retryDelay = 3000;
        result.maxRetries = 3;
        result.fallbackAction = () => this.showOfflineMode();
        break;
        
      case 1008500004:
        result.userMessage = '应用未申请Wear Engine服务，请先申请服务';
        result.shouldRetry = false;
        result.fallbackAction = () => this.showServiceApplyGuide();
        break;
        
      case 1008500006:
        result.userMessage = '用户未同意隐私授权，请打开运动健康App';
        result.shouldRetry = true;
        result.retryDelay = 5000;
        result.fallbackAction = () => this.showPrivacyAgreementGuide();
        break;
        
      case 1008500007:
        result.userMessage = '穿戴设备不支持此能力';
        result.shouldRetry = false;
        result.fallbackAction = () => this.showCapabilityNotSupportedUI();
        break;
        
      case 1008500008:
        result.userMessage = '请登录华为账号后继续';
        result.shouldRetry = true;
        result.retryDelay = 1000;
        result.fallbackAction = () => this.promptUserLogin();
        break;
        
      case 1008500009:
        result.userMessage = '请使用中国境内注册的华为账号';
        result.shouldRetry = false;
        result.fallbackAction = () => this.showAccountRegionError();
        break;
        
      case 1008509999:
        result.userMessage = '内部错误，请检查应用配置';
        result.shouldRetry = true;
        result.retryDelay = 2000;
        result.fallbackAction = () => this.checkInternalConfiguration();
        break;
        
      default:
        result.userMessage = `授权失败: ${error.message}`;
        result.shouldRetry = false;
        result.fallbackAction = () => this.showGenericErrorUI();
    }
    
    return result;
  }
  
  /**
   * 处理getAuthorization错误
   */
  handleGetAuthorizationError(error: BusinessError): ErrorHandlingResult {
    console.error(`[ErrorHandler] getAuthorization error: ${error.code}`);
    
    const result: ErrorHandlingResult = {
      errorCode: error.code,
      errorMessage: error.message,
      userMessage: '',
      shouldRetry: false,
      fallbackAction: null
    };
    
    switch (error.code) {
      case 1008500001:
        result.userMessage = '网络不可用，无法查询授权状态';
        result.shouldRetry = true;
        result.retryDelay = 2000;
        result.fallbackAction = () => this.showOfflineMode();
        break;
        
      case 1008500004:
        result.userMessage = '应用未申请Wear Engine服务';
        result.shouldRetry = false;
        result.fallbackAction = () => this.showServiceApplyGuide();
        break;
        
      case 1008500006:
        result.userMessage = '用户未同意隐私授权';
        result.shouldRetry = true;
        result.retryDelay = 5000;
        result.fallbackAction = () => this.showPrivacyAgreementGuide();
        break;
        
      case 1008500007:
        result.userMessage = '设备不支持此能力';
        result.shouldRetry = false;
        result.fallbackAction = () => this.showCapabilityNotSupportedUI();
        break;
        
      case 1008500008:
        result.userMessage = '请先登录华为账号';
        result.shouldRetry = true;
        result.retryDelay = 1000;
        result.fallbackAction = () => this.promptUserLogin();
        break;
        
      case 1008500009:
        result.userMessage = '账号异常，请使用中国境内账号';
        result.shouldRetry = false;
        result.fallbackAction = () => this.showAccountRegionError();
        break;
        
      case 1008509999:
        result.userMessage = '内部错误';
        result.shouldRetry = true;
        result.retryDelay = 2000;
        result.fallbackAction = () => this.checkInternalConfiguration();
        break;
        
      default:
        result.userMessage = `查询授权状态失败: ${error.message}`;
        result.shouldRetry = false;
        result.fallbackAction = () => this.showGenericErrorUI();
    }
    
    return result;
  }
  
  /**
   * 自动重试机制
   */
  async retryWithBackoff<T>(
    operation: () => Promise<T>,
    errorHandler: (error: BusinessError) => ErrorHandlingResult,
    maxRetries: number = 3,
    initialDelay: number = 1000
  ): Promise<T> {
    let retryCount = 0;
    let delay = initialDelay;
    
    while (retryCount <= maxRetries) {
      try {
        console.info(`[ErrorHandler] Attempt ${retryCount + 1}/${maxRetries + 1}`);
        const result = await operation();
        console.info('[ErrorHandler] Operation succeeded');
        return result;
        
      } catch (error) {
        const err: BusinessError = error as BusinessError;
        const handlingResult = errorHandler(err);
        
        console.error(`[ErrorHandler] Error on attempt ${retryCount + 1}: ${err.code}`);
        
        if (!handlingResult.shouldRetry || retryCount >= maxRetries) {
          console.error('[ErrorHandler] Max retries reached or should not retry');
          
          // 执行降级方案
          if (handlingResult.fallbackAction) {
            handlingResult.fallbackAction();
          }
          
          throw err;
        }
        
        // 延迟后重试
        console.info(`[ErrorHandler] Retrying after ${delay}ms`);
        await this.sleep(delay);
        
        retryCount++;
        delay *= 2; // 指数退避
      }
    }
    
    throw new Error('Max retries exceeded');
  }
  
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
  
  // 降级方案实现
  private fixContextParameter(): void {
    console.info('[ErrorHandler] Fix: Check Context type and validity');
    // 实际应用中应检查Context参数
  }
  
  private showDeviceNotSupportedUI(): void {
    console.warn('[ErrorHandler] Fallback: Show device not supported UI');
    // 显示设备不支持提示界面
  }
  
  private checkInternalConfiguration(): void {
    console.info('[ErrorHandler] Fallback: Check clientId and signature');
    // 检查metadata中的clientId配置
    // 检查签名证书是否与开发者联盟一致
  }
  
  private fixRequestParameter(): void {
    console.info('[ErrorHandler] Fix: Check AuthorizationRequest parameters');
    // 检查permissions字段是否为有效的Permission数组
  }
  
  private showOfflineMode(): void {
    console.warn('[ErrorHandler] Fallback: Switch to offline mode');
    // 切换到离线模式或缓存数据模式
  }
  
  private showServiceApplyGuide(): void {
    console.warn('[ErrorHandler] Fallback: Guide user to apply for service');
    // 显示申请Wear Engine服务的指引
  }
  
  private showPrivacyAgreementGuide(): void {
    console.warn('[ErrorHandler] Fallback: Guide user to open Health app');
    // 引导用户打开运动健康App进行隐私授权
  }
  
  private showCapabilityNotSupportedUI(): void {
    console.warn('[ErrorHandler] Fallback: Show capability not supported');
    // 显示设备能力不支持提示
  }
  
  private promptUserLogin(): void {
    console.info('[ErrorHandler] Fallback: Prompt user to login');
    // 提示用户登录华为账号（通常会自动弹出登录界面）
  }
  
  private showAccountRegionError(): void {
    console.warn('[ErrorHandler] Fallback: Show account region error');
    // 提示用户使用中国境内注册的账号
  }
  
  private showGenericErrorUI(): void {
    console.warn('[ErrorHandler] Fallback: Show generic error UI');
    // 显示通用错误提示界面
  }
}

/**
 * 错误处理结果结构
 */
interface ErrorHandlingResult {
  errorCode: number;
  errorMessage: string;
  userMessage: string;
  shouldRetry: boolean;
  retryDelay?: number;
  maxRetries?: number;
  fallbackAction: (() => void) | null;
}

/**
 * 使用示例：带错误处理的授权流程
 */
async function authorizationWithErrorHandler(context: common.Context): Promise<void> {
  console.info('=== Starting authorization with error handling ===');
  
  const errorHandler = new AuthorizationErrorHandler(context);
  const authClient: wearEngine.AuthClient = wearEngine.getAuthClient(context);
  
  try {
    // 带重试机制的权限申请
    const request: wearEngine.AuthorizationRequest = {
      permissions: [wearEngine.Permission.USER_STATUS]
    };
    
    const response = await errorHandler.retryWithBackoff(
      () => authClient.requestAuthorization(request),
      (error) => errorHandler.handleRequestAuthorizationError(error),
      3, // 最多重试3次
      1000 // 初始延迟1秒
    );
    
    console.info(`[Success] Authorized permissions: ${JSON.stringify(response.permissions)}`);
    
  } catch (error) {
    console.error('[Failed] Authorization failed after retries');
    // 错误处理器的降级方案已自动执行
  }
  
  console.info('=== Authorization with error handling completed ===');
}

/**
 * 示例：分类错误处理
 */
async function handleErrorsByCategory(context: common.Context): Promise<void> {
  console.info('[ErrorHandler] Handling errors by category');
  
  const authClient: wearEngine.AuthClient = wearEngine.getAuthClient(context);
  const errorHandler = new AuthorizationErrorHandler(context);
  
  // 尝试获取AuthClient
  try {
    const client: wearEngine.AuthClient = wearEngine.getAuthClient(context);
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    const result = errorHandler.handleGetAuthClientError(err);
    
    console.error(`[ErrorHandler] getAuthClient error handled`);
    console.error(`[ErrorHandler] User message: ${result.userMessage}`);
    console.error(`[ErrorHandler] Should retry: ${result.shouldRetry}`);
    
    if (result.fallbackAction) {
      result.fallbackAction();
    }
    
    if (result.shouldRetry) {
      console.info('[ErrorHandler] Retrying getAuthClient...');
      await errorHandler.sleep(result.retryDelay || 1000);
      // 重试逻辑...
    }
    
    return;
  }
  
  // 尝试申请授权
  try {
    const request: wearEngine.AuthorizationRequest = {
      permissions: [wearEngine.Permission.USER_STATUS]
    };
    
    const response = await authClient.requestAuthorization(request);
    console.info('[ErrorHandler] Authorization successful');
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    const result = errorHandler.handleRequestAuthorizationError(err);
    
    console.error(`[ErrorHandler] requestAuthorization error handled`);
    console.error(`[ErrorHandler] User message: ${result.userMessage}`);
    
    // 根据错误类型采取不同策略
    if (result.shouldRetry) {
      console.info('[ErrorHandler] Network/account error, will retry');
      // 网络或账号错误，可以重试
    } else if (result.errorCode === 1008500004) {
      console.error('[ErrorHandler] Service not applied, cannot proceed');
      // 服务未申请，无法继续，需要开发者处理
    } else if (result.errorCode === 1008500009) {
      console.error('[ErrorHandler] Account region error, user must change account');
      // 账号注册地问题，需要用户更换账号
    }
    
    // 执行降级方案
    if (result.fallbackAction) {
      result.fallbackAction();
    }
  }
}

/**
 * 示例：错误日志记录器
 */
class ErrorLogger {
  private errorLog: ErrorLogEntry[] = [];
  
  logError(error: BusinessError, context: string): void {
    const entry: ErrorLogEntry = {
      timestamp: new Date().toISOString(),
      errorCode: error.code,
      errorMessage: error.message,
      context: context
    };
    
    this.errorLog.push(entry);
    console.error(`[ErrorLogger] Logged error: ${JSON.stringify(entry)}`);
    
    // 持久化到本地存储或上报服务器
    this.persistErrorLog(entry);
  }
  
  getErrorStatistics(): ErrorStatistics {
    const stats: ErrorStatistics = {
      totalErrors: this.errorLog.length,
      errorsByCode: new Map<number, number>(),
      mostCommonError: null,
      recentErrors: this.errorLog.slice(-10)
    };
    
    // 统计各错误码出现次数
    for (const entry of this.errorLog) {
      const count = stats.errorsByCode.get(entry.errorCode) || 0;
      stats.errorsByCode.set(entry.errorCode, count + 1);
    }
    
    // 找出最常见的错误
    let maxCount = 0;
    stats.errorsByCode.forEach((count, code) => {
      if (count > maxCount) {
        maxCount = count;
        stats.mostCommonError = code;
      }
    });
    
    return stats;
  }
  
  private persistErrorLog(entry: ErrorLogEntry): void {
    console.info(`[ErrorLogger] Persisting error log entry`);
    // 实际应用中应持久化到本地存储
  }
}

interface ErrorLogEntry {
  timestamp: string;
  errorCode: number;
  errorMessage: string;
  context: string;
}

interface ErrorStatistics {
  totalErrors: number;
  errorsByCode: Map<number, number>;
  mostCommonError: number | null;
  recentErrors: ErrorLogEntry[];
}

/**
 * 示例：错误恢复策略
 */
class ErrorRecoveryStrategy {
  /**
   * 网络错误恢复策略
   */
  async recoverFromNetworkError(
    operation: () => Promise<any>,
    maxWaitTime: number = 30000
  ): Promise<any> {
    const startTime = Date.now();
    
    while (Date.now() - startTime < maxWaitTime) {
      try {
        console.info('[Recovery] Checking network availability');
        
        // 检查网络是否恢复（简单实现）
        const networkAvailable = await this.checkNetworkAvailability();
        
        if (networkAvailable) {
          console.info('[Recovery] Network available, retrying operation');
          return await operation();
        }
        
        // 等待2秒后再次检查
        await this.sleep(2000);
        
      } catch (error) {
        console.error('[Recovery] Recovery attempt failed');
      }
    }
    
    console.error('[Recovery] Network recovery timeout');
    throw new Error('Network recovery timeout');
  }
  
  /**
   * 账号错误恢复策略
   */
  async recoverFromAccountError(
    authClient: wearEngine.AuthClient,
    request: wearEngine.AuthorizationRequest,
    maxWaitTime: number = 60000
  ): Promise<wearEngine.AuthorizationResponse> {
    const startTime = Date.now();
    
    console.info('[Recovery] Waiting for user to login');
    
    // 用户登录通常会自动弹出登录界面
    // 这里只需等待一段时间后重试
    
    while (Date.now() - startTime < maxWaitTime) {
      try {
        await this.sleep(5000);
        
        console.info('[Recovery] Retrying authorization after account fix');
        const response = await authClient.requestAuthorization(request);
        
        console.info('[Recovery] Authorization succeeded after account recovery');
        return response;
        
      } catch (error) {
        const err: BusinessError = error as BusinessError;
        
        if (err.code !== 1008500008 && err.code !== 1008500009) {
          // 不是账号错误，直接抛出
          throw err;
        }
        
        console.info('[Recovery] Account still not ready, continue waiting');
      }
    }
    
    console.error('[Recovery] Account recovery timeout');
    throw new Error('Account recovery timeout');
  }
  
  private checkNetworkAvailability(): Promise<boolean> {
    // 实际应用中应检查网络连接状态
    return Promise.resolve(true);
  }
  
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

/**
 * 示例：完整的错误处理流程
 */
async function completeErrorHandlingFlow(context: common.Context): Promise<void> {
  console.info('=== Starting complete error handling flow ===');
  
  const errorHandler = new AuthorizationErrorHandler(context);
  const errorLogger = new ErrorLogger();
  const recoveryStrategy = new ErrorRecoveryStrategy();
  
  const authClient: wearEngine.AuthClient = wearEngine.getAuthClient(context);
  const request: wearEngine.AuthorizationRequest = {
    permissions: [wearEngine.Permission.USER_STATUS]
  };
  
  try {
    // 正常流程
    const response = await authClient.requestAuthorization(request);
    console.info('[Success] Authorization completed');
    
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    
    // 记录错误
    errorLogger.logError(err, 'requestAuthorization');
    
    // 分析错误
    const handlingResult = errorHandler.handleRequestAuthorizationError(err);
    
    console.error(`[Error] Type: ${err.code}`);
    console.error(`[Error] Message: ${handlingResult.userMessage}`);
    
    // 根据错误类型选择恢复策略
    if (err.code === 1008500001) {
      // 网络错误：等待网络恢复
      console.info('[Recovery] Attempting network recovery...');
      
      try {
        const response = await recoveryStrategy.recoverFromNetworkError(
          () => authClient.requestAuthorization(request)
        );
        console.info('[Recovery] Network recovery succeeded');
        
      } catch (recoveryError) {
        console.error('[Recovery] Network recovery failed, switching to offline mode');
        errorHandler.showOfflineMode();
      }
      
    } else if (err.code === 1008500008) {
      // 账号未登录：等待用户登录
      console.info('[Recovery] Waiting for user login...');
      
      try {
        const response = await recoveryStrategy.recoverFromAccountError(
          authClient,
          request
        );
        console.info('[Recovery] Account recovery succeeded');
        
      } catch (recoveryError) {
        console.error('[Recovery] Account recovery failed');
        errorHandler.promptUserLogin();
      }
      
    } else {
      // 其他错误：执行降级方案
      if (handlingResult.fallbackAction) {
        handlingResult.fallbackAction();
      }
    }
    
    // 生成错误报告
    const stats = errorLogger.getErrorStatistics();
    console.info(`[Report] Total errors: ${stats.totalErrors}`);
    console.info(`[Report] Most common error: ${stats.mostCommonError}`);
  }
  
  console.info('=== Complete error handling flow finished ===');
}