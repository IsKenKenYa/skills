// ArkTS完整示例 - 取消多个请求
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 取消多个网络请求的完整示例
export function cancelMultipleRequestsExample(): void {
  // 步骤1：创建会话
  const session = rcp.createSession();
  
  // 步骤2：创建多个Request对象
  let request1 = new rcp.Request("https://www.example.com/api/data1");
  let request2 = new rcp.Request("https://www.example.com/api/data2");
  let request3 = new rcp.Request("https://www.example.com/api/data3");
  
  // 步骤3：发起请求
  session.fetch(request1).then((response: rcp.Response) => {
    console.info(`Request1 succeeded: ${response.statusCode}`);
  }).catch((err: BusinessError) => {
    if (err.message && err.message.includes('cancel')) {
      console.warn('Request1 was canceled');
    } else {
      console.error(`Request1 error: ${err.code}`);
    }
  });
  
  session.fetch(request2).then((response: rcp.Response) => {
    console.info(`Request2 succeeded: ${response.statusCode}`);
  }).catch((err: BusinessError) => {
    if (err.message && err.message.includes('cancel')) {
      console.warn('Request2 was canceled');
    } else {
      console.error(`Request2 error: ${err.code}`);
    }
  });
  
  session.fetch(request3).then((response: rcp.Response) => {
    console.info(`Request3 succeeded: ${response.statusCode}`);
  }).catch((err: BusinessError) => {
    if (err.message && err.message.includes('cancel')) {
      console.warn('Request3 was canceled');
    } else {
      console.error(`Request3 error: ${err.code}`);
    }
  });
  
  // 步骤4：取消多个请求（通过Request数组）
  setTimeout(() => {
    try {
      if (session && session.id) {
        // 取消request1和request2
        session.cancel([request1, request2]);
        console.info('Request1 and Request2 have been canceled');
      } else {
        console.warn('Session is invalid');
      }
    } catch (error) {
      console.error('Cancel multiple requests failed:', error);
    }
  }, 500);
  
  // 步骤5：关闭session
  setTimeout(() => {
    if (session && session.id) {
      session.close();
      console.info('Session closed');
    }
  }, 3000);
}

// 批量请求管理器（支持批量取消）
export class BatchRequestManager {
  private session: rcp.Session;
  private requestGroups: Map<string, rcp.Request[]> = new Map();
  
  constructor() {
    this.session = rcp.createSession();
  }
  
  // 发起批量请求（按分组）
  async fetchBatch(groupName: string, urls: string[]): Promise<rcp.Response[]> {
    const requests: rcp.Request[] = urls.map(url => new rcp.Request(url));
    this.requestGroups.set(groupName, requests);
    
    const promises = requests.map(request => 
      this.session.fetch(request).catch((err: BusinessError) => {
        if (err.message && err.message.includes('cancel')) {
          console.warn(`Request in group ${groupName} was canceled`);
        } else {
          console.error(`Request in group ${groupName} failed: ${err.code}`);
        }
        throw err;
      })
    );
    
    try {
      const responses = await Promise.all(promises);
      this.requestGroups.delete(groupName);
      return responses;
    } catch (error) {
      // 如果某个请求失败或被取消，Promise.all会失败
      this.requestGroups.delete(groupName);
      throw error;
    }
  }
  
  // 取消指定分组的所有请求
  cancelGroup(groupName: string): boolean {
    const requests = this.requestGroups.get(groupName);
    if (requests && requests.length > 0) {
      this.session.cancel(requests);
      this.requestGroups.delete(groupName);
      console.info(`Group ${groupName} (${requests.length} requests) has been canceled`);
      return true;
    } else {
      console.warn(`Group ${groupName} not found or already completed`);
      return false;
    }
  }
  
  // 取消多个分组
  cancelMultipleGroups(groupNames: string[]): void {
    const allRequests: rcp.Request[] = [];
    
    groupNames.forEach(name => {
      const requests = this.requestGroups.get(name);
      if (requests) {
        allRequests.push(...requests);
        this.requestGroups.delete(name);
      }
    });
    
    if (allRequests.length > 0) {
      this.session.cancel(allRequests);
      console.info(`${groupNames.length} groups (${allRequests.length} requests) have been canceled`);
    } else {
      console.warn('No requests found in specified groups');
    }
  }
  
  // 取消所有分组
  cancelAllGroups(): void {
    let totalCount = 0;
    this.requestGroups.forEach((requests, groupName) => {
      totalCount += requests.length;
    });
    
    if (totalCount > 0) {
      this.session.cancel();
      this.requestGroups.clear();
      console.info(`All groups (${totalCount} requests) have been canceled`);
    } else {
      console.info('No active requests to cancel');
    }
  }
  
  // 关闭管理器
  close(): void {
    this.cancelAllGroups();
    this.session.close();
  }
}

// 使用示例
export function batchRequestManagerExample(): void {
  const manager = new BatchRequestManager();
  
  // 发起多个分组的请求
  manager.fetchBatch('groupA', [
    "https://www.example.com/api/a1",
    "https://www.example.com/api/a2",
    "https://www.example.com/api/a3"
  ]).catch(err => console.error('GroupA failed:', err));
  
  manager.fetchBatch('groupB', [
    "https://www.example.com/api/b1",
    "https://www.example.com/api/b2"
  ]).catch(err => console.error('GroupB failed:', err));
  
  // 取消特定分组
  setTimeout(() => {
    manager.cancelGroup('groupA');
  }, 1000);
  
  // 或取消多个分组
  setTimeout(() => {
    manager.cancelMultipleGroups(['groupA', 'groupB']);
  }, 2000);
  
  // 关闭管理器
  setTimeout(() => {
    manager.close();
  }, 5000);
}