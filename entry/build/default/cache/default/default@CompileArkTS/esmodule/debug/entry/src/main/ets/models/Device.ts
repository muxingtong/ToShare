import type { DeviceType, DeviceStatus, TransportProtocol } from './Enums';
export class Device {
    id: string;
    name: string;
    avatar: string;
    type: DeviceType;
    supportedProtocols: TransportProtocol[];
    lastSeen: number;
    status: DeviceStatus;
    signalStrength: number;
    constructor(id: string, name: string, avatar: string, type: DeviceType, supportedProtocols: TransportProtocol[], lastSeen: number, status: DeviceStatus, signalStrength: number) {
        this.id = id;
        this.name = name;
        this.avatar = avatar;
        this.type = type;
        this.supportedProtocols = supportedProtocols;
        this.lastSeen = lastSeen;
        this.status = status;
        this.signalStrength = signalStrength;
    }
}
export class DeviceInfo {
    id: string;
    name: string;
    type: DeviceType;
    supportedProtocols: TransportProtocol[];
    constructor(id: string, name: string, type: DeviceType, supportedProtocols: TransportProtocol[]) {
        this.id = id;
        this.name = name;
        this.type = type;
        this.supportedProtocols = supportedProtocols;
    }
}
