// ArkTS完整示例 - 取消单个请求
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 取消单个网络请求的完整示例
export function cancelSingleRequestExample(): void {
  // 步骤1：创建会话
  const session = rcp.createSession();
  
  // 步骤2：创建Request对象
  let request1 = new rcp.Request("https://www.example.com/api/data1");
  let request2 = new rcp.Request("https://www.example.com/api/data2");
  
  // 步骤3：发起请求
  session.fetch(request1).then((response: rcp.Response) => {
    console.info(`Request1 succeeded, status code: ${response.statusCode}`);
    // 请求成功后的处理逻辑
    if (response.body) {
      console.info(`Response body length: ${response.body.byteLength}`);
    }
  }).catch((err: BusinessError) => {
    // 错误处理，区分取消错误和其他错误
    if (err.message && err.message.includes('cancel')) {
      console.warn('Request1 was canceled by user');
    } else {
      console.error(`Request1 failed: code=${err.code}, message=${err.message}`);
    }
  });
  
  session.fetch(request2).then((response: rcp.Response) => {
    console.info(`Request2 succeeded, status code: ${response.statusCode}`);
  }).catch((err: BusinessError) => {
    if (err.message && err.message.includes('cancel')) {
      console.warn('Request2 was canceled by user');
    } else {
      console.error(`Request2 failed: code=${err.code}, message=${err.message}`);
    }
  });
  
  // 步骤4：取消指定请求（例如取消request1）
  setTimeout(() => {
    try {
      // 校验session是否有效
      if (session && session.id) {
        session.cancel(request1);
        console.info(`Request ${request1.id} has been canceled`);
      } else {
        console.warn('Session is invalid or closed');
      }
    } catch (error) {
      console.error('Cancel request failed:', error);
    }
  }, 500);
  
  // 步骤5：在合适的时机关闭session（释放资源）
  setTimeout(() => {
    if (session && session.id) {
      session.close();
      console.info('Session has been closed');
    }
  }, 3000);
}

// 完整的请求管理示例（包含取消功能）
export class RequestManager {
  private session: rcp.Session;
  private activeRequests: Map<string, rcp.Request> = new Map();
  
  constructor() {
    this.session = rcp.createSession();
    console.info('RequestManager initialized, session id:', this.session.id);
  }
  
  // 发起请求并记录
  async fetchData(url: string): Promise<rcp.Response> {
    const request = new rcp.Request(url);
    this.activeRequests.set(request.id, request);
    
    try {
      const response = await this.session.fetch(request);
      console.info(`Request ${request.id} succeeded, status: ${response.statusCode}`);
      this.activeRequests.delete(request.id);
      return response;
    } catch (error) {
      const err = error as BusinessError;
      this.activeRequests.delete(request.id);
      
      if (err.message && err.message.includes('cancel')) {
        console.warn(`Request ${request.id} was canceled`);
      } else {
        console.error(`Request ${request.id} failed: ${err.code} - ${err.message}`);
      }
      throw err;
    }
  }
  
  // 取消指定请求
  cancelRequest(requestId: string): boolean {
    const request = this.activeRequests.get(requestId);
    if (request) {
      this.session.cancel(request);
      this.activeRequests.delete(requestId);
      console.info(`Request ${requestId} has been canceled`);
      return true;
    } else {
      console.warn(`Request ${requestId} not found or already completed`);
      return false;
    }
  }
  
  // 取消所有请求
  cancelAllRequests(): void {
    if (this.activeRequests.size > 0) {
      this.session.cancel();
      this.activeRequests.clear();
      console.info('All active requests have been canceled');
    } else {
      console.info('No active requests to cancel');
    }
  }
  
  // 关闭管理器
  close(): void {
    this.cancelAllRequests();
    this.session.close();
    console.info('RequestManager closed');
  }
}

// 使用示例
export function requestManagerExample(): void {
  const manager = new RequestManager();
  
  // 发起多个请求
  manager.fetchData("https://www.example.com/api/data1").catch(err => console.error(err));
  manager.fetchData("https://www.example.com/api/data2").catch(err => console.error(err));
  manager.fetchData("https://www.example.com/api/data3").catch(err => console.error(err));
  
  // 延迟取消第一个请求
  setTimeout(() => {
    const requestId = Array.from(manager.activeRequests.keys())[0];
    if (requestId) {
      manager.cancelRequest(requestId);
    }
  }, 1000);
  
  // 最终关闭管理器
  setTimeout(() => {
    manager.close();
  }, 5000);
}