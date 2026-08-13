// IDataSource实现示例
export class BasicListDataSource implements IDataSource {
  private dataArray: string[] = [];
  private listeners: DataChangeListener[] = [];
  
  constructor(data: string[]) {
    this.dataArray = data;
  }
  
  // 获取数据总数
  totalCount(): number {
    return this.dataArray.length;
  }
  
  // 获取指定索引的数据
  getData(index: number): string {
    // 校验索引范围
    if (index < 0 || index >= this.dataArray.length) {
      console.error('Index out of range: ' + index + ', total: ' + this.dataArray.length);
      return '';
    }
    return this.dataArray[index];
  }
  
  // 注册数据变化监听器
  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }
  
  // 注销数据变化监听器
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      this.listeners.splice(pos, 1);
    }
  }
  
  // 通知数据重新加载
  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    });
  }
  
  // 通知数据添加
  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index);
    });
  }
  
  // 通知数据删除
  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataDelete(index);
    });
  }
  
  // 通知数据变化
  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataChange(index);
    });
  }
  
  // 添加数据项
  addDataItem(index: number, item: string): void {
    if (index >= 0 && index <= this.dataArray.length) {
      this.dataArray.splice(index, 0, item);
      this.notifyDataAdd(index);
    } else {
      console.error('Invalid index for addDataItem: ' + index);
    }
  }
  
  // 删除数据项
  deleteDataItem(index: number): void {
    if (index >= 0 && index < this.dataArray.length) {
      this.dataArray.splice(index, 1);
      this.notifyDataDelete(index);
    } else {
      console.error('Invalid index for deleteDataItem: ' + index);
    }
  }
  
  // 修改数据项
  changeDataItem(index: number, newItem: string): void {
    if (index >= 0 && index < this.dataArray.length) {
      this.dataArray[index] = newItem;
      this.notifyDataChange(index);
    } else {
      console.error('Invalid index for changeDataItem: ' + index);
    }
  }
}