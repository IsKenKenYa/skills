/**
 * 蓝牙设备查找管理器
 * 完整的蓝牙设备扫描实现示例
 * 支持API version 18+的discoveryResult和API version 10的bluetoothDeviceFind两种方式
 */
import { connection } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 设备信息结构
 */
export interface DeviceInfo {
  deviceId: string;      // 设备地址
  deviceName: string;    // 设备名称
  majorClass: number;    // 设备主要类型
  rssi: number;          // 信号强度
}

/**
 * 扫描结果回调
 */
export type DiscoveryCallback = (devices: DeviceInfo[]) => void;

/**
 * 蓝牙设备查找管理器
 * 提供完整的蓝牙设备扫描功能，包括：
 * - 开启/停止扫描
 * - 订阅/取消订阅扫描结果
 * - 查询已配对设备
 * - 设置本机扫描模式
 */
export class DiscoveryDeviceManager {
  private discoveredDevices: Map<string, DeviceInfo> = new Map();
  private discoveryCallback: DiscoveryCallback | null = null;
  private isApi18Plus: boolean = true; // 默认使用API 18+方式
  
  /**
   * 构造函数
   * 自动检测API版本，选择合适的扫描方式
   */
  constructor() {
    // 检查API版本，API version 18+支持discoveryResult
    // 实际项目中应根据设备API版本动态设置
    console.info('DiscoveryDeviceManager initialized');
  }
  
  /**
   * 订阅扫描结果上报事件（API 18+推荐方式）
   * 可获取设备地址、名称、类型、信号强度等完整信息
   */
  private onDiscoveryResult = (data: Array<connection.DiscoveryResult>) => {
    console.info('发现蓝牙设备（discoveryResult）: ' + JSON.stringify(data));
    
    for (const device of data) {
      const deviceInfo: DeviceInfo = {
        deviceId: device.deviceId,
        deviceName: device.deviceName || '未知设备',
        majorClass: device.majorClass,
        rssi: device.rssi
      };
      
      // 使用设备地址作为唯一标识，避免重复
      if (!this.discoveredDevices.has(device.deviceId)) {
        this.discoveredDevices.set(device.deviceId, deviceInfo);
        console.info(`新设备: 地址=${deviceInfo.deviceId}, 名称=${deviceInfo.deviceName}, 类型=${deviceInfo.majorClass}, 信号=${deviceInfo.rssi}`);
      }
    }
    
    // 触发回调，返回设备列表
    if (this.discoveryCallback) {
      this.discoveryCallback(Array.from(this.discoveredDevices.values()));
    }
  };
  
  /**
   * 订阅扫描结果上报事件（API 10兼容方式）
   * 仅获取设备地址信息
   */
  private onBluetoothDeviceFind = (data: Array<string>) => {
    console.info('发现蓝牙设备地址（bluetoothDeviceFind）: ' + JSON.stringify(data));
    
    for (const deviceId of data) {
      if (!this.discoveredDevices.has(deviceId)) {
        const deviceInfo: DeviceInfo = {
          deviceId: deviceId,
          deviceName: '未知设备', // API 10方式无法获取设备名称
          majorClass: -1,         // API 10方式无法获取设备类型
          rssi: -100              // API 10方式无法获取信号强度
        };
        
        this.discoveredDevices.set(deviceId, deviceInfo);
        console.info(`新设备地址: ${deviceId}`);
      }
    }
    
    // 触发回调，返回设备列表
    if (this.discoveryCallback) {
      this.discoveryCallback(Array.from(this.discoveredDevices.values()));
    }
  };
  
  /**
   * 开始蓝牙设备扫描
   * @param callback 扫描结果回调函数
   * @param useApi18 是否使用API 18+方式（默认true）
   * @returns true表示成功启动扫描，false表示失败
   */
  public startDiscovery(callback: DiscoveryCallback, useApi18: boolean = true): boolean {
    console.info('开始蓝牙设备扫描');
    
    // 设置回调函数
    this.discoveryCallback = callback;
    this.isApi18Plus = useApi18;
    
    // 清空之前发现的设备列表
    this.discoveredDevices.clear();
    
    try {
      // 步骤1：订阅扫描结果上报事件
      if (this.isApi18Plus) {
        console.info('使用API 18+方式订阅（discoveryResult）');
        connection.on('discoveryResult', this.onDiscoveryResult);
      } else {
        console.info('使用API 10方式订阅（bluetoothDeviceFind）');
        connection.on('bluetoothDeviceFind', this.onBluetoothDeviceFind);
      }
      
      // 步骤2：判断是否正在扫描
      const isDiscovering = connection.isBluetoothDiscovering();
      console.info('当前扫描状态: ' + isDiscovering);
      
      if (isDiscovering) {
        console.warn('当前正在进行扫描，无法启动新的扫描');
        return false;
      }
      
      // 步骤3：发起设备扫描
      connection.startBluetoothDiscovery();
      console.info('已开始蓝牙设备扫描，扫描将持续约12秒');
      
      return true;
      
    } catch (err) {
      const error = err as BusinessError;
      console.error('扫描启动失败: errCode=' + error.code + ', errMessage=' + error.message);
      
      // 错误处理
      this.handleDiscoveryError(error);
      return false;
    }
  }
  
  /**
   * 停止蓝牙设备扫描
   * @returns true表示成功停止扫描，false表示失败
   */
  public stopDiscovery(): boolean {
    console.info('停止蓝牙设备扫描');
    
    try {
      // 步骤1：判断是否正在扫描
      const isDiscovering = connection.isBluetoothDiscovering();
      console.info('当前扫描状态: ' + isDiscovering);
      
      if (!isDiscovering) {
        console.warn('当前未在进行扫描，无需停止');
        return false;
      }
      
      // 步骤2：停止扫描
      connection.stopBluetoothDiscovery();
      console.info('已停止蓝牙设备扫描');
      
      // 步骤3：取消订阅扫描结果上报事件
      if (this.isApi18Plus) {
        connection.off('discoveryResult', this.onDiscoveryResult);
        console.info('已取消订阅discoveryResult事件');
      } else {
        connection.off('bluetoothDeviceFind', this.onBluetoothDeviceFind);
        console.info('已取消订阅bluetoothDeviceFind事件');
      }
      
      // 清空回调函数
      this.discoveryCallback = null;
      
      return true;
      
    } catch (err) {
      const error = err as BusinessError;
      console.error('停止扫描失败: errCode=' + error.code + ', errMessage=' + error.message);
      
      this.handleDiscoveryError(error);
      return false;
    }
  }
  
  /**
   * 查询已配对设备信息
   * @returns 已配对设备地址列表
   */
  public getPairedDevices(): string[] {
    console.info('查询已配对设备信息');
    
    try {
      const pairedDevices = connection.getPairedDevices();
      console.info('已配对设备列表: ' + JSON.stringify(pairedDevices));
      
      return pairedDevices;
      
    } catch (err) {
      const error = err as BusinessError;
      console.error('查询已配对设备失败: errCode=' + error.code + ', errMessage=' + error.message);
      
      this.handleDiscoveryError(error);
      return [];
    }
  }
  
  /**
   * 获取指定设备的配对状态
   * @param deviceId 设备地址
   * @returns 配对状态（BONDED/BONDING/INVALID）
   */
  public getPairState(deviceId: string): connection.BondState {
    console.info('查询设备配对状态: ' + deviceId);
    
    try {
      const pairState = connection.getPairState(deviceId);
      console.info('设备 ' + deviceId + ' 配对状态: ' + pairState);
      
      // 配对状态说明
      switch (pairState) {
        case connection.BondState.BOND_STATE_BONDED:
          console.info('设备已配对');
          break;
        case connection.BondState.BOND_STATE_BONDING:
          console.info('设备正在配对');
          break;
        case connection.BondState.BOND_STATE_INVALID:
          console.info('设备未配对');
          break;
      }
      
      return pairState;
      
    } catch (err) {
      const error = err as BusinessError;
      console.error('查询配对状态失败: errCode=' + error.code + ', errMessage=' + error.message);
      
      this.handleDiscoveryError(error);
      return connection.BondState.BOND_STATE_INVALID;
    }
  }
  
  /**
   * 设置本机蓝牙扫描模式
   * 控制本机设备是否可以被周边其他蓝牙设备扫描到或连接上
   * @param scanMode 扫描模式（SCAN_MODE_CONNECTABLE_GENERAL_DISCOVERABLE等）
   * @param duration 扫描持续时间（毫秒，0表示无限）
   * @returns true表示成功设置，false表示失败
   */
  public setScanMode(scanMode: connection.ScanMode, duration: number = 0): boolean {
    console.info('设置本机蓝牙扫描模式: mode=' + scanMode + ', duration=' + duration);
    
    try {
      // 获取当前扫描模式
      const currentScanMode = connection.getBluetoothScanMode();
      console.info('当前扫描模式: ' + currentScanMode);
      
      // 设置新的扫描模式
      connection.setBluetoothScanMode(scanMode, duration);
      console.info('已设置扫描模式: ' + scanMode);
      
      return true;
      
    } catch (err) {
      const error = err as BusinessError;
      console.error('设置扫描模式失败: errCode=' + error.code + ', errMessage=' + error.message);
      
      this.handleDiscoveryError(error);
      return false;
    }
  }
  
  /**
   * 获取已发现的所有设备信息
   * @returns 设备信息列表
   */
  public getDiscoveredDevices(): DeviceInfo[] {
    console.info('获取已发现设备列表，数量: ' + this.discoveredDevices.size);
    return Array.from(this.discoveredDevices.values());
  }
  
  /**
   * 清空已发现的设备列表
   */
  public clearDiscoveredDevices(): void {
    console.info('清空已发现设备列表');
    this.discoveredDevices.clear();
  }
  
  /**
   * 检查当前是否正在扫描
   * @returns true表示正在扫描，false表示未扫描
   */
  public isDiscovering(): boolean {
    try {
      const isDiscovering = connection.isBluetoothDiscovering();
      console.info('当前扫描状态: ' + isDiscovering);
      return isDiscovering;
      
    } catch (err) {
      const error = err as BusinessError;
      console.error('查询扫描状态失败: errCode=' + error.code + ', errMessage=' + error.message);
      return false;
    }
  }
  
  /**
   * 错误处理函数
   * @param error BusinessError错误对象
   */
  private handleDiscoveryError(error: BusinessError): void {
    switch (error.code) {
      case 201:
        console.error('权限不足，请申请ACCESS_BLUETOOTH权限');
        console.error('参考文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions');
        break;
        
      case 401:
        console.error('参数错误，请检查参数类型和必填参数');
        break;
        
      case 801:
        console.error('当前设备不支持蓝牙能力');
        break;
        
      case 2900001:
        console.error('蓝牙服务已停止，请重启蓝牙');
        break;
        
      case 2900003:
        console.error('蓝牙未开启，请先开启蓝牙');
        break;
        
      case 2900099:
        console.error('操作失败，请检查蓝牙状态和设备状态');
        break;
        
      default:
        console.error('未知错误: code=' + error.code + ', message=' + error.message);
    }
  }
}

// 导出默认实例
let discoveryDeviceManager = new DiscoveryDeviceManager();
export default discoveryDeviceManager as DiscoveryDeviceManager;