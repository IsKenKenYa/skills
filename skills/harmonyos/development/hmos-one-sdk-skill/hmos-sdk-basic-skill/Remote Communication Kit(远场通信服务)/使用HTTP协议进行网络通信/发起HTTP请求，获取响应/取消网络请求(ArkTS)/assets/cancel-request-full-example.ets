// ArkTS完整示例 - 完整流程
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 完整的取消网络请求流程示例
export function completeCancelRequestFlow(): void {
  console.info('=== Complete Cancel Request Flow Example ===');
  
  // 阶段1：准备阶段
  console.info('Phase 1: Preparation');
  
  // 创建会话
  const session = rcp.createSession();
  console.info(`Session created: ${session.id}`);
  
  // 创建Request对象
  let request1 = new rcp.Request("https://www.example.com/api/users");
  let request2 = new rcp.Request("https://www.example.com/api/products");
  let request3 = new rcp.Request("https://www.example.com/api/orders");
  
  console.info('Requests created:');
  console.info(`  - Request1: ${request1.id}`);
  console.info(`  - Request2: ${request2.id}`);
  console.info(`  - Request3: ${request3.id}`);
  
  // 阶段2：发起请求
  console.info('Phase 2: Send Requests');
  
  // 发起request1
  session.fetch(request1).then((response: rcp.Response) => {
    console.info(`Request1 succeeded: ${response.statusCode}`);
    if (response.body) {
      console.info(`Response1 body size: ${response.body.byteLength} bytes`);
    }
  }).catch((err: BusinessError) => {
    handleRequestError('Request1', err);
  });
  
  // 发起request2
  session.fetch(request2).then((response: rcp.Response) => {
    console.info(`Request2 succeeded: ${response.statusCode}`);
  }).catch((err: BusinessError) => {
    handleRequestError('Request2', err);
  });
  
  // 发起request3
  session.fetch(request3).then((response: rcp.Response) => {
    console.info(`Request3 succeeded: ${response.statusCode}`);
  }).catch((err: BusinessError) => {
    handleRequestError('Request3', err);
  });
  
  // 阶段3：取消请求（多种方式）
  console.info('Phase 3: Cancel Requests');
  
  // 方式1：取消单个请求
  setTimeout(() => {
    console.info('Cancel single request (Request1)...');
    cancelRequest(session, request1);
  }, 500);
  
  // 方式2：取消多个请求
  setTimeout(() => {
    console.info('Cancel multiple requests (Request2, Request3)...');
    cancelMultipleRequests(session, [request2, request3]);
  }, 1000);
  
  // 方式3：取消所有请求（演示用途）
  setTimeout(() => {
    console.info('Cancel all requests (if any remaining)...');
    cancelAllRequests(session);
  }, 1500);
  
  // 阶段4：关闭会话
  console.info('Phase 4: Close Session');
  setTimeout(() => {
    closeSession(session);
    console.info('=== Complete Flow Finished ===');
  }, 3000);
}

// 错误处理函数
function handleRequestError(requestName: string, err: BusinessError): void {
  // 区分取消错误和其他网络错误
  if (err.message && err.message.includes('cancel')) {
    console.warn(`${requestName} was canceled by user`);
  } else {
    // 根据错误码进行不同处理
    switch (err.code) {
      case 401:
        console.error(`${requestName} failed: Parameter error`);
        break;
      case 1007900994:
        console.error(`${requestName} failed: Sessions number reached limit`);
        break;
      default:
        console.error(`${requestName} failed: code=${err.code}, message=${err.message}`);
        if (err.data) {
          console.error(`${requestName} error data: ${JSON.stringify(err.data)}`);
        }
    }
  }
}

// 取消单个请求的封装函数
function cancelRequest(session: rcp.Session, request: rcp.Request): void {
  try {
    // 前置校验
    if (!session || !session.id) {
      console.warn('Session is invalid or closed');
      return;
    }
    
    if (!request || !request.id) {
      console.warn('Request is invalid');
      return;
    }
    
    // 执行取消操作
    session.cancel(request);
    console.info(`Request ${request.id} has been canceled successfully`);
    
  } catch (error) {
    console.error('Cancel request failed with exception:', error);
  }
}

// 取消多个请求的封装函数
function cancelMultipleRequests(session: rcp.Session, requests: rcp.Request[]): void {
  try {
    // 前置校验
    if (!session || !session.id) {
      console.warn('Session is invalid or closed');
      return;
    }
    
    if (!requests || requests.length === 0) {
      console.warn('Requests array is empty');
      return;
    }
    
    // 过滤无效请求
    const validRequests = requests.filter(req => req && req.id);
    
    if (validRequests.length === 0) {
      console.warn('No valid requests to cancel');
      return;
    }
    
    // 执行取消操作
    session.cancel(validRequests);
    console.info(`${validRequests.length} requests have been canceled successfully`);
    validRequests.forEach(req => {
      console.info(`  - Canceled: ${req.id}`);
    });
    
  } catch (error) {
    console.error('Cancel multiple requests failed with exception:', error);
  }
}

// 取消所有请求的封装函数
function cancelAllRequests(session: rcp.Session): void {
  try {
    // 前置校验
    if (!session || !session.id) {
      console.warn('Session is invalid or closed');
      return;
    }
    
    // 执行取消所有请求操作（不传参数）
    session.cancel();
    console.info('All requests in session have been canceled successfully');
    
  } catch (error) {
    console.error('Cancel all requests failed with exception:', error);
  }
}

// 关闭会话的封装函数
function closeSession(session: rcp.Session): void {
  try {
    // 前置校验
    if (!session || !session.id) {
      console.warn('Session is already closed or invalid');
      return;
    }
    
    // 先取消所有可能的pending请求
    session.cancel();
    
    // 关闭会话
    session.close();
    console.info('Session has been closed successfully');
    
  } catch (error) {
    console.error('Close session failed with exception:', error);
  }
}

// 完整的请求生命周期管理示例
export class RequestLifecycleManager {
  private session: rcp.Session;
  private requests: Map<string, { request: rcp.Request; status: 'pending' | 'completed' | 'canceled' | 'failed' }> = new Map();
  
  constructor() {
    this.session = rcp.createSession();
    console.info('RequestLifecycleManager initialized');
  }
  
  // 发起请求并跟踪状态
  async sendRequest(url: string): Promise<rcp.Response | null> {
    const request = new rcp.Request(url);
    const requestId = request.id;
    
    // 记录请求状态
    this.requests.set(requestId, { request, status: 'pending' });
    console.info(`Request ${requestId} sent to ${url}`);
    
    try {
      const response = await this.session.fetch(request);
      
      // 更新状态为已完成
      this.requests.set(requestId, { request, status: 'completed' });
      console.info(`Request ${requestId} completed with status ${response.statusCode}`);
      
      return response;
      
    } catch (error) {
      const err = error as BusinessError;
      
      // 根据错误类型更新状态
      if (err.message && err.message.includes('cancel')) {
        this.requests.set(requestId, { request, status: 'canceled' });
        console.warn(`Request ${requestId} was canceled`);
      } else {
        this.requests.set(requestId, { request, status: 'failed' });
        console.error(`Request ${requestId} failed: ${err.code}`);
      }
      
      return null;
    }
  }
  
  // 取消单个请求
  cancelRequestById(requestId: string): boolean {
    const requestInfo = this.requests.get(requestId);
    
    if (!requestInfo) {
      console.warn(`Request ${requestId} not found`);
      return false;
    }
    
    if (requestInfo.status !== 'pending') {
      console.warn(`Request ${requestId} is not pending (status: ${requestInfo.status})`);
      return false;
    }
    
    this.session.cancel(requestInfo.request);
    this.requests.set(requestId, { ...requestInfo, status: 'canceled' });
    console.info(`Request ${requestId} canceled successfully`);
    
    return true;
  }
  
  // 取消所有pending请求
  cancelAllPendingRequests(): number {
    const pendingRequests: rcp.Request[] = [];
    
    this.requests.forEach((info, id) => {
      if (info.status === 'pending') {
        pendingRequests.push(info.request);
      }
    });
    
    if (pendingRequests.length > 0) {
      this.session.cancel(pendingRequests);
      
      // 更新状态
      pendingRequests.forEach(req => {
        const info = this.requests.get(req.id);
        if (info) {
          this.requests.set(req.id, { ...info, status: 'canceled' });
        }
      });
      
      console.info(`${pendingRequests.length} pending requests canceled`);
      return pendingRequests.length;
    } else {
      console.info('No pending requests to cancel');
      return 0;
    }
  }
  
  // 获取请求统计
  getRequestStatistics(): { total: number; pending: number; completed: number; canceled: number; failed: number } {
    let pending = 0;
    let completed = 0;
    let canceled = 0;
    let failed = 0;
    
    this.requests.forEach(info => {
      switch (info.status) {
        case 'pending': pending++; break;
        case 'completed': completed++; break;
        case 'canceled': canceled++; break;
        case 'failed': failed++; break;
      }
    });
    
    return {
      total: this.requests.size,
      pending,
      completed,
      canceled,
      failed
    };
  }
  
  // 打印统计信息
  printStatistics(): void {
    const stats = this.getRequestStatistics();
    console.info('Request Statistics:');
    console.info(`  Total: ${stats.total}`);
    console.info(`  Pending: ${stats.pending}`);
    console.info(`  Completed: ${stats.completed}`);
    console.info(`  Canceled: ${stats.canceled}`);
    console.info(`  Failed: ${stats.failed}`);
  }
  
  // 关闭管理器
  close(): void {
    this.cancelAllPendingRequests();
    this.printStatistics();
    this.session.close();
    console.info('RequestLifecycleManager closed');
  }
}

// 使用生命周期管理器的完整示例
export function lifecycleManagerExample(): void {
  const manager = new RequestLifecycleManager();
  
  // 发起多个请求
  manager.sendRequest("https://www.example.com/api/data1");
  manager.sendRequest("https://www.example.com/api/data2");
  manager.sendRequest("https://www.example.com/api/data3");
  manager.sendRequest("https://www.example.com/api/data4");
  
  // 打印当前状态
  setTimeout(() => {
    manager.printStatistics();
  }, 500);
  
  // 取消部分请求
  setTimeout(() => {
    const stats = manager.getRequestStatistics();
    const pendingIds = Array.from(manager.requests.entries())
      .filter(([_, info]) => info.status === 'pending')
      .map(([id, _]) => id);
    
    // 取消前两个pending请求
    if (pendingIds.length >= 2) {
      manager.cancelRequestById(pendingIds[0]);
      manager.cancelRequestById(pendingIds[1]);
    }
    
    manager.printStatistics();
  }, 1000);
  
  // 取消所有剩余pending请求
  setTimeout(() => {
    manager.cancelAllPendingRequests();
    manager.printStatistics();
  }, 2000);
  
  // 关闭管理器
  setTimeout(() => {
    manager.close();
  }, 5000);
}

// 运行完整流程示例
completeCancelRequestFlow();