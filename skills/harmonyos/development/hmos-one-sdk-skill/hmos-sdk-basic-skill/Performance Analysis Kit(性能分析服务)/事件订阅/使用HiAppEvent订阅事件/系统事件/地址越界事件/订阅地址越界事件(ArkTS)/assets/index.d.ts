/**
 * libentry.so模块的类型定义
 * 导出test函数用于触发地址越界错误
 */

/**
 * 触发地址越界错误的测试函数
 * 该函数会故意构造数组越界写入场景,触发Address Sanitizer
 * 调用此函数会导致应用崩溃并生成ADDRESS_SANITIZER事件
 */
export const test: () => void;