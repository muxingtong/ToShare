/**
 * 热点模式类型定义
 */

export enum HotspotState {
  /** 热点未启用 */
  DISABLED = 0,
  /** 正在启动 */
  STARTING = 1,
  /** 热点已启用 */
  ACTIVE = 2,
  /** 正在关闭 */
  STOPPING = 3,
  /** 错误状态 */
  ERROR = 4,
}

export interface HotspotConfig {
  /** 热点 SSID */
  ssid: string;
  /** WPA2 密码 (至少8位) */
  password: string;
  /** 网关 IP */
  gatewayIp: string;
  /** HTTP 服务端口 */
  port: number;
}

export interface ConnectedClient {
  /** 设备 MAC 地址 */
  mac: string;
  /** 分配的 IP */
  ip: string;
  /** 设备名称(可能为空) */
  name: string;
  /** 连接时间戳 */
  connectedAt: number;
}

export interface HotspotFileItem {
  /** 文件名称 */
  name: string;
  /** 文件大小(bytes) */
  size: number;
  /** MIME 类型 */
  mimeType: string;
  /** 文件保存路径 */
  savePath: string;
  /** 上传/下载方向: 'upload' | 'download' */
  direction: string;
  /** 传输完成时间 */
  completedAt: number;
  /** 发送方设备名 */
  fromDevice?: string;
}

export interface HotspotEvent {
  type: string;
  message?: string;
  progress?: number;
  fileName?: string;
}
