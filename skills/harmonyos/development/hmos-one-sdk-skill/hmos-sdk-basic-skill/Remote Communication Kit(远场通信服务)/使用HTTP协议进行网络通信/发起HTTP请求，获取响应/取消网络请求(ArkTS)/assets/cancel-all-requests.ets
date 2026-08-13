// ArkTS完整示例 - 取消所有请求
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 取消所有网络请求的完整示例
export function cancelAllRequestsExample(): void {
  // 步骤1：创建会话
  const session = rcp.createSession();
  
  // 步骤2：创建多个Request对象并发起请求
  const urls = [
    "https://www.example.com/api/data1",
    "https://www.example.com/api/data2",
    "https://www.example.com/api/data3",
    "https://www.example.com/api/data4"
  ];
  
  urls.forEach((url, index) => {
    const request = new rcp.Request(url);
    session.fetch(request).then((response: rcp.Response) => {
      console.info(`Request${index + 1} succeeded: ${response.statusCode}`);
    }).catch((err: BusinessError) => {
      if (err.message && err.message.includes('cancel')) {
        console.warn(`Request${index + 1} was canceled`);
      } else {
        console.error(`Request${index + 1} failed: ${err.code}`);
      }
    });
  });
  
  // 步骤3：取消所有请求（不传参数）
  setTimeout(() => {
    try {
      if (session && session.id) {
        // 取消当前session的所有请求
        session.cancel();
        console.info('All requests in session have been canceled');
      } else {
        console.warn('Session is invalid or closed');
      }
    } catch (error) {
      console.error('Cancel all requests failed:', error);
    }
  }, 500);
  
  // 步骤4：关闭session释放资源
  setTimeout(() => {
    if (session && session.id) {
      session.close();
      console.info('Session has been closed');
    }
  }, 3000);
}

// 会话管理器（提供取消所有请求的能力）
export class SessionManager {
  private session: rcp.Session;
  private requestCount: number = 0;
  private completedCount: number = 0;
  private canceledCount: number = 0;
  
  constructor() {
    this.session = rcp.createSession();
    console.info('SessionManager created, session id:', this.session.id);
  }
  
  // 发起请求（带统计）
  async fetch(url: string): Promise<rcp.Response | null> {
    this.requestCount++;
    const request = new rcp.Request(url);
    
    try {
      const response = await this.session.fetch(request);
      this.completedCount++;
      console.info(`Request completed (${this.completedCount}/${this.requestCount})`);
      return response;
    } catch (error) {
      const err = error as BusinessError;
      
      if (err.message && err.message.includes('cancel')) {
        this.canceledCount++;
        console.warn(`Request canceled (${this.canceledCount}/${this.requestCount})`);
      } else {
        console.error(`Request failed: ${err.code}`);
      }
      return null;
    }
  }
  
  // 批量发起请求
  async fetchAll(urls: string[]): Promise<rcp.Response[]> {
    const promises = urls.map(url => this.fetch(url));
    const results = await Promise.allSettled(promises);
    
    const responses: rcp.Response[] = [];
    results.forEach(result => {
      if (result.status === 'fulfilled' && result.value) {
        responses.push(result.value);
      }
    });
    
    return responses;
  }
  
  // 取消所有请求
  cancelAll(): void {
    const pendingCount = this.requestCount - this.completedCount - this.canceledCount;
    
    if (pendingCount > 0) {
      this.session.cancel();
      console.info(`All pending requests (${pendingCount}) have been canceled`);
    } else {
      console.info('No pending requests to cancel');
    }
  }
  
  // 获取统计信息
  getStatistics(): { total: number; completed: number; canceled: number; pending: number } {
    const pending = this.requestCount - this.completedCount - this.canceledCount;
    return {
      total: this.requestCount,
      completed: this.completedCount,
      canceled: this.canceledCount,
      pending: pending
    };
  }
  
  // 打印统计信息
  printStatistics(): void {
    const stats = this.getStatistics();
    console.info(`Statistics: Total=${stats.total}, Completed=${stats.completed}, Canceled=${stats.canceled}, Pending=${stats.pending}`);
  }
  
  // 关闭管理器
  close(): void {
    this.cancelAll();
    this.printStatistics();
    this.session.close();
    console.info('SessionManager closed');
  }
}

// 使用示例
export function sessionManagerExample(): void {
  const manager = new SessionManager();
  
  // 批量发起请求
  const urls = [
    "https://www.example.com/api/data1",
    "https://www.example.com/api/data2",
    "https://www.example.com/api/data3",
    "https://www.example.com/api/data4",
    "https://www.example.com/api/data5"
  ];
  
  manager.fetchAll(urls).then(responses => {
    console.info(`${responses.length} requests completed successfully`);
  }).catch(err => {
    console.error('Batch fetch failed:', err);
  });
  
  // 延迟取消所有请求
  setTimeout(() => {
    manager.cancelAll();
    manager.printStatistics();
  }, 1000);
  
  // 关闭管理器
  setTimeout(() => {
    manager.close();
  }, 5000);
}

// 用户交互场景示例（用户主动取消）
export function userCancelScenario(): void {
  const manager = new SessionManager();
  
  // 模拟用户发起请求
  console.info('User initiated requests...');
  manager.fetchAll([
    "https://www.example.com/api/load1",
    "https://www.example.com/api/load2",
    "https://www.example.com/api/load3"
  ]);
  
  // 模拟用户主动取消（例如点击取消按钮）
  setTimeout(() => {
    console.info('User clicked cancel button...');
    manager.cancelAll();
    
    // 显示统计信息
    manager.printStatistics();
  }, 2000);
  
  // 清理资源
  setTimeout(() => {
    manager.close();
  }, 5000);
}