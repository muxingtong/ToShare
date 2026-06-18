import { DeviceType, DeviceStatus, TransportProtocol } from './Enums';
import { ShareVendor } from '../utils/ShareProtocol';

export class Device {
  id: string;
  name: string;
  vendor: ShareVendor;
  avatar: string;
  type: DeviceType;
  supportedProtocols: TransportProtocol[];
  lastSeen: number;
  status: DeviceStatus;
  signalStrength: number;

  constructor(
    id: string,
    name: string,
    vendor: ShareVendor,
    avatar: string,
    type: DeviceType,
    supportedProtocols: TransportProtocol[],
    lastSeen: number,
    status: DeviceStatus,
    signalStrength: number
  ) {
    this.id = id;
    this.name = name;
    this.vendor = vendor;
    this.avatar = avatar;
    this.type = type;
    this.supportedProtocols = supportedProtocols;
    this.lastSeen = lastSeen;
    this.status = status;
    this.signalStrength = signalStrength;
  }

  /**
   * 获取显示用的设备名（去除重复厂商前缀后的简洁名称）
   */
  get displayName(): string {
    return cleanDeviceName(this.name, this.vendor);
  }
}

export class DeviceInfo {
  id: string;
  name: string;
  type: DeviceType;
  supportedProtocols: TransportProtocol[];

  constructor(
    id: string,
    name: string,
    type: DeviceType,
    supportedProtocols: TransportProtocol[]
  ) {
    this.id = id;
    this.name = name;
    this.type = type;
    this.supportedProtocols = supportedProtocols;
  }
}

/**
 * 去除厂商名称中冗余前缀，返回整洁的显示名
 * 例如 "[OPPO] OPPO Find X9" → "Find X9"
 *       "OPPO Find X9" → "Find X9"
 *       "Xiaomi 14" → "14"
 */
export function cleanDeviceName(name: string, vendor: ShareVendor): string {
  const rawName = name.replace(/^\[[^\]]+\]\s*/, '').trim();
  const vendorStr = String(vendor);
  if (rawName.startsWith(vendorStr)) {
    const after = rawName.substring(vendorStr.length).trim();
    if (after.length > 2) {
      return after;
    }
  }
  return rawName || '附近设备';
}
