// 断点续传示例代码
import { rcp } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';

// 全局变量
let session: rcp.Session | null = null;
const kHttpServerAddress = 'http://www.example.com/fetch';
let request: rcp.Request | null = null;
let totalSize = 0;
let lastTransferPosition = 0;
const CHUNK_SIZE = 100; // 每次下载的字节数

// 获取文件总大小
async function getTotalSize(): Promise<number> {
  if (!session || !request) {
    console.error('Session 或 Request 未初始化');
    return 0;
  }
  
  // 设置传输范围为前2个字节
  request.transferRange = { from: 0, to: 1 };
  
  try {
    const rep = await session.fetch(request);
    if (rep) {
      // 从响应头的 content-range 字段提取文件大小
      const contentRange = rep.headers['content-range'];
      if (contentRange) {
        const sizeStr = contentRange.substring(contentRange.indexOf('/') + 1, contentRange.length);
        totalSize = Number(sizeStr);
        console.info(`文件总大小: ${totalSize} 字节`);
      } else {
        console.warn('响应头未包含 content-range，服务器可能不支持 Range 请求');
        totalSize = 0;
      }
    }
  } catch (err) {
    const error = err as BusinessError;
    console.error(`获取文件大小失败: code=${error.code}, message=${error.message}`);
  }
  
  return totalSize;
}

// 分片下载函数
function downloadTransfer(from: number, to: number): void {
  if (!session || !request) {
    console.error('Session 或 Request 未初始化');
    return;
  }
  
  // 设置传输范围
  request.transferRange = { from: from, to: to };
  
  console.info(`开始下载: ${from} - ${to} 字节`);
  
  session.fetch(request).then((rep) => {
    if (rep.body) {
      // 处理响应数据（此处可保存到本地文件）
      console.info(`分片下载成功: 状态码 ${rep.statusCode}`);
      
      // 更新传输位置
      lastTransferPosition += rep.body.byteLength;
      console.info(`已下载: ${lastTransferPosition} / ${totalSize} 字节 (${Math.round(lastTransferPosition * 100 / totalSize)}%)`);
      
      // 检查是否完成下载
      if (lastTransferPosition < totalSize) {
        // 计算下一次传输范围的结束位置
        const nextTo = Math.min(lastTransferPosition + CHUNK_SIZE, totalSize);
        
        // 递归调用继续下载下一段数据
        downloadTransfer(lastTransferPosition, nextTo);
      } else {
        console.info('下载完成！');
        onDownloadComplete();
      }
    }
  }).catch((err: BusinessError) => {
    console.error(`分片下载失败: code=${err.code}, message=${err.message}`);
    onDownloadError(err);
  });
}

// 开始下载
async function startDownload(): Promise<void> {
  console.info('开始下载流程');
  
  // 初始化 Session
  if (!session) {
    session = rcp.createSession();
  }
  
  // 初始化 Request
  if (!request) {
    request = new rcp.Request(kHttpServerAddress, 'GET');
  }
  
  // 传输位置归零
  lastTransferPosition = 0;
  
  // 获取文件总大小
  totalSize = await getTotalSize();
  
  if (totalSize === 0) {
    console.error('无法获取文件大小，请检查服务器是否支持 Range 请求');
    return;
  }
  
  // 计算传输范围的结束位置
  const nextTo = Math.min(lastTransferPosition + CHUNK_SIZE, totalSize);
  
  // 开始下载
  downloadTransfer(lastTransferPosition, nextTo);
}

// 暂停下载
function pauseDownload(): void {
  if (!session || !request) {
    console.warn('Session 或 Request 未初始化');
    return;
  }
  
  // 取消下载请求
  session.cancel(request);
  console.info(`下载已暂停，当前位置: ${lastTransferPosition} 字节 (${Math.round(lastTransferPosition * 100 / totalSize)}%)`);
}

// 继续下载
function resumeDownload(): void {
  if (lastTransferPosition === 0) {
    console.warn('下载未开始，请先调用 startDownload');
    return;
  }
  
  if (lastTransferPosition >= totalSize) {
    console.info('下载已完成，无需继续');
    return;
  }
  
  // 计算传输范围的结束位置
  const nextTo = Math.min(lastTransferPosition + CHUNK_SIZE, totalSize);
  
  // 继续下载
  downloadTransfer(lastTransferPosition, nextTo);
  console.info(`继续下载，从 ${lastTransferPosition} 到 ${nextTo} 字节`);
}

// 停止下载
function stopDownload(): void {
  if (!session) {
    console.warn('Session 未初始化');
    return;
  }
  
  // 取消下载请求
  if (request) {
    session.cancel(request);
  }
  
  // 关闭 session
  session.close();
  session = null;
  request = null;
  
  console.info('下载已停止，Session 已关闭');
  lastTransferPosition = 0;
  totalSize = 0;
}

// 下载完成回调
function onDownloadComplete(): void {
  console.info('=== 下载完成 ===');
  console.info(`总大小: ${totalSize} 字节`);
  console.info(`已下载: ${lastTransferPosition} 字节`);
  console.info('可以关闭 Session 或开始新的下载');
}

// 下载错误回调
function onDownloadError(error: BusinessError): void {
  console.error('=== 下载错误 ===');
  console.error(`错误码: ${error.code}`);
  console.error(`错误信息: ${error.message}`);
  console.info(`当前位置已保存: ${lastTransferPosition} 字节`);
  console.info('可以调用 resumeDownload 继续下载');
}

// 主页面
@Entry
@Component
struct ResumableDownloadExample {
  build() {
    Column({ space: 20 }) {
      Text('断点续传示例')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
      
      Text(`文件大小: ${totalSize} 字节`)
        .fontSize(16)
      
      Text(`已下载: ${lastTransferPosition} 字节 (${Math.round(lastTransferPosition * 100 / totalSize)}%)`)
        .fontSize(16)
      
      Row({ space: 10 }) {
        Button('开始下载')
          .onClick(() => {
            startDownload();
          })
          .width('30%')
          .height(40)
        
        Button('暂停下载')
          .onClick(() => {
            pauseDownload();
          })
          .width('30%')
          .height(40)
        
        Button('继续下载')
          .onClick(() => {
            resumeDownload();
          })
          .width('30%')
          .height(40)
      }
      
      Button('停止下载')
        .onClick(() => {
          stopDownload();
        })
        .width('80%')
        .height(40)
        .backgroundColor('#FF5555')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(20)
  }
}