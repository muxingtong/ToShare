/**
 * 互传联盟协议常量定义
 * 支持 OPPO / VIVO / 小米 等安卓互传联盟设备的 BLE 广播识别
 */
// 互传联盟设备常见的 BLE Service UUID（完整128位格式）
export const SHARE_SERVICE_UUIDS: string[] = [
    '0000FE95-0000-1000-8000-00805F9B34FB',
    '0000FDDF-0000-1000-8000-00805F9B34FB',
    '00009955-0000-1000-8000-00805F9B34FB',
    '0000FEE7-0000-1000-8000-00805F9B34FB',
    '0000FE4C-0000-1000-8000-00805F9B34FB',
    '0000FEFE-0000-1000-8000-00805F9B34FB',
    '00003331-0000-1000-8000-008123456789',
    '0000F005-0000-1000-8000-00805F9B34FB', // 华为 Share
];
// 厂商 Manufacturer ID 对照表
export enum ShareVendor {
    XIAOMI = "\u5C0F\u7C73",
    OPPO = "OPPO",
    VIVO = "VIVO",
    SAMSUNG = "\u4E09\u661F",
    HUAWEI = "\u534E\u4E3A",
    UNKNOWN = "\u672A\u77E5"
}
// 各厂商在 BLE 广播中使用的 Manufacturer ID
export const VENDOR_MANUFACTURER_IDS: Record<number, ShareVendor> = {
    0x038F: ShareVendor.XIAOMI,
    0x0583: ShareVendor.OPPO,
    0x0499: ShareVendor.VIVO,
    0x0075: ShareVendor.SAMSUNG,
    0x05A7: ShareVendor.HUAWEI,
};
// BLE 广播数据解析常量
const BLE_ADV_TYPE_FLAG = 0x01;
const BLE_ADV_TYPE_16BIT_SERVICE_UUIDS_INCOMPLETE = 0x02;
const BLE_ADV_TYPE_16BIT_SERVICE_UUIDS_COMPLETE = 0x03;
const BLE_ADV_TYPE_128BIT_SERVICE_UUIDS_INCOMPLETE = 0x06;
const BLE_ADV_TYPE_128BIT_SERVICE_UUIDS_COMPLETE = 0x07;
const BLE_ADV_TYPE_LOCAL_NAME_SHORT = 0x08;
const BLE_ADV_TYPE_LOCAL_NAME_COMPLETE = 0x09;
const BLE_ADV_TYPE_MANUFACTURER_SPECIFIC_DATA = 0xFF;
const BLE_ADV_TYPE_SERVICE_DATA_16BIT = 0x16;
const BLE_ADV_TYPE_SERVICE_DATA_128BIT = 0x21;
const UUID_128_BIT_LENGTH = 16;
const UUID_16_BIT_LENGTH = 2;
const MANUFACTURE_ID_LENGTH = 2;
// 解析后的广播数据结构
export interface ParsedAdvertisement {
    localName: string;
    serviceUuids: string[];
    manufacturerId: number | null;
    manufacturerData: Uint8Array | null;
}
// 识别到的互传设备信息
export interface ShareDeviceInfo {
    deviceId: string;
    deviceName: string;
    vendor: ShareVendor;
    rssi: number;
    serviceUuids: string[];
    isShareDevice: boolean;
    manufactureId: number | null;
    manufactureData: Uint8Array | null;
}
function uuid16To128(uuid16: number): string {
    const hex = uuid16.toString(16).padStart(4, '0').toUpperCase();
    return `0000${hex}-0000-1000-8000-00805F9B34FB`;
}
function bytesToUuid128(bytes: Uint8Array): string {
    if (bytes.length < UUID_128_BIT_LENGTH) {
        return '';
    }
    const hexParts: string[] = [];
    // BLE 广播中 128-bit UUID 为小端序，从末尾向前读取以还原为标准大端序
    for (let i = UUID_128_BIT_LENGTH - 1; i >= 0; i--) {
        const b = bytes[i];
        hexParts.push(b.toString(16).padStart(2, '0').toUpperCase());
    }
    const hex = hexParts.join('');
    return `${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}`;
}
/**
 * 解析 BLE 广播数据
 */
export function parseAdvertisementData(data: ArrayBuffer): ParsedAdvertisement {
    const advData = new Uint8Array(data);
    const result: ParsedAdvertisement = {
        localName: '',
        serviceUuids: [],
        manufacturerId: null,
        manufacturerData: null
    };
    let pos = 0;
    while (pos < advData.byteLength) {
        const length = advData[pos];
        pos += 1;
        if (length === 0 || pos + length > advData.byteLength) {
            break;
        }
        const adType = advData[pos];
        const adDataLen = length - 1;
        pos += 1;
        switch (adType) {
            case BLE_ADV_TYPE_LOCAL_NAME_SHORT:
            case BLE_ADV_TYPE_LOCAL_NAME_COMPLETE: {
                const nameBytes = advData.slice(pos, pos + adDataLen);
                result.localName = String.fromCharCode(...nameBytes);
                break;
            }
            case BLE_ADV_TYPE_16BIT_SERVICE_UUIDS_INCOMPLETE:
            case BLE_ADV_TYPE_16BIT_SERVICE_UUIDS_COMPLETE: {
                const serviceUuids = parse16BitServiceUuids(advData, pos, adDataLen);
                result.serviceUuids.push(...serviceUuids);
                break;
            }
            case BLE_ADV_TYPE_128BIT_SERVICE_UUIDS_INCOMPLETE:
            case BLE_ADV_TYPE_128BIT_SERVICE_UUIDS_COMPLETE: {
                const serviceUuids = parse128BitServiceUuids(advData, pos, adDataLen);
                result.serviceUuids.push(...serviceUuids);
                break;
            }
            case BLE_ADV_TYPE_MANUFACTURER_SPECIFIC_DATA: {
                if (adDataLen >= MANUFACTURE_ID_LENGTH) {
                    // BLE 广播中 Manufacturer ID 为小端序：低字节在前
                    result.manufacturerId = (advData[pos + 1] << 8) | advData[pos];
                    result.manufacturerData = advData.slice(pos + MANUFACTURE_ID_LENGTH, pos + adDataLen);
                }
                break;
            }
            case BLE_ADV_TYPE_SERVICE_DATA_16BIT: {
                if (adDataLen >= UUID_16_BIT_LENGTH) {
                    // BLE 广播中 16-bit UUID 为小端序：低字节在前
                    const uuid16 = ((advData[pos + 1] << 8) | advData[pos]) & 0xFFFF;
                    result.serviceUuids.push(uuid16To128(uuid16));
                }
                break;
            }
            case BLE_ADV_TYPE_SERVICE_DATA_128BIT: {
                if (adDataLen >= UUID_128_BIT_LENGTH) {
                    result.serviceUuids.push(bytesToUuid128(advData.slice(pos, pos + UUID_128_BIT_LENGTH)));
                }
                break;
            }
            default:
                break;
        }
        pos += adDataLen;
    }
    return result;
}
function parse16BitServiceUuids(data: Uint8Array, offset: number, length: number): string[] {
    const uuids: string[] = [];
    for (let i = 0; i + UUID_16_BIT_LENGTH <= length; i += UUID_16_BIT_LENGTH) {
        // BLE 广播中 16-bit UUID 为小端序：低字节在前
        const uuid16 = ((data[offset + i + 1] << 8) | data[offset + i]) & 0xFFFF;
        uuids.push(uuid16To128(uuid16));
    }
    return uuids;
}
function parse128BitServiceUuids(data: Uint8Array, offset: number, length: number): string[] {
    const uuids: string[] = [];
    for (let i = 0; i + UUID_128_BIT_LENGTH <= length; i += UUID_128_BIT_LENGTH) {
        uuids.push(bytesToUuid128(data.slice(offset + i, offset + i + UUID_128_BIT_LENGTH)));
    }
    return uuids;
}
/**
 * 判断设备广播的 UUID 是否为互传联盟设备
 */
export function isShareServiceUuid(uuids: string[]): boolean {
    const upperUuids = uuids.map(u => u.toUpperCase());
    return SHARE_SERVICE_UUIDS.some(sid => upperUuids.includes(sid));
}
/**
 * 根据 Manufacturer ID 识别厂商
 */
export function getVendorByManufacturerId(id: number | null): ShareVendor {
    if (id !== null && VENDOR_MANUFACTURER_IDS[id]) {
        return VENDOR_MANUFACTURER_IDS[id];
    }
    return ShareVendor.UNKNOWN;
}
/**
 * 根据设备名称辅助识别厂商
 */
export function detectVendorByName(name: string): ShareVendor {
    const upper = name.toUpperCase();
    if (upper.includes('REDMI') || upper.includes('XIAOMI') || upper.includes('MI ') || upper.includes('POCO')) {
        return ShareVendor.XIAOMI;
    }
    if (upper.includes('OPPO') || upper.includes('REALME') || upper.includes('ONEPLUS')) {
        return ShareVendor.OPPO;
    }
    if (upper.includes('VIVO') || upper.includes('IQOO')) {
        return ShareVendor.VIVO;
    }
    if (upper.includes('SAMSUNG') || upper.includes('GALAXY')) {
        return ShareVendor.SAMSUNG;
    }
    if (upper.includes('HUAWEI') || upper.includes('HONOR')) {
        return ShareVendor.HUAWEI;
    }
    return ShareVendor.UNKNOWN;
}
/**
 * 从服务UUID中检测厂商
 * OPPO等厂商可能在128-bit UUID后缀中嵌入自己的Bluetooth Company ID
 * 例如 OPPO UUID: 00003331-0000-1000-8000-008123456789, 其中 0x8123 即 OPPO Company ID
 */
export function detectVendorFromUuids(uuids: string[]): ShareVendor {
    for (const uuid of uuids) {
        const upper = uuid.toUpperCase();
        // 在UUID hex字符串中搜索已知厂商的Company ID
        if (upper.includes('8123')) {
            return ShareVendor.OPPO;
        }
        if (upper.includes('038F')) {
            return ShareVendor.XIAOMI;
        }
        if (upper.includes('0499')) {
            return ShareVendor.VIVO;
        }
        if (upper.includes('0075')) {
            return ShareVendor.SAMSUNG;
        }
        if (upper.includes('05A7')) {
            return ShareVendor.HUAWEI;
        }
    }
    return ShareVendor.UNKNOWN;
}
/**
 * 从原始广播数据的ASCII可打印字符中提取可能包含厂商关键词的设备名称
 * OPPO Find X9等设备将名称嵌入在Service Data中而非标准Local Name AD Type
 * 返回从厂商关键词位置开始的子串，去除前缀编码数据
 */
export function extractNameFromRawData(data: Uint8Array): string {
    let asciiStr = '';
    let vendorKeywordIndex = -1;
    for (let i = 0; i < data.byteLength; i++) {
        const b = data[i];
        // 可打印ASCII字符 (空格0x20 ~ 0x7E)
        if (b >= 0x20 && b <= 0x7E) {
            const startIdx = asciiStr.length;
            asciiStr += String.fromCharCode(b);
            // 记录厂商关键词在字符串中的位置
            if (vendorKeywordIndex < 0 && startIdx >= 0) {
                const subStr = asciiStr.substring(startIdx);
                if (containsVendorKeyword(subStr)) {
                    // 找到关键词后，记录其起始位置
                    vendorKeywordIndex = findVendorKeywordIndex(subStr);
                    if (vendorKeywordIndex >= 0) {
                        vendorKeywordIndex = startIdx + vendorKeywordIndex;
                    }
                }
            }
        }
        else {
            if (vendorKeywordIndex >= 0) {
                // 从厂商关键词位置开始截取，去除前缀编码数据
                return asciiStr.substring(vendorKeywordIndex).trim();
            }
            if (asciiStr.length >= 3 && containsVendorKeyword(asciiStr)) {
                return asciiStr.trim();
            }
            asciiStr = '';
        }
    }
    if (vendorKeywordIndex >= 0) {
        return asciiStr.substring(vendorKeywordIndex).trim();
    }
    if (asciiStr.length >= 3 && containsVendorKeyword(asciiStr)) {
        return asciiStr.trim();
    }
    return '';
}
function findVendorKeywordIndex(str: string): number {
    const upper = str.toUpperCase();
    const keywords = ['OPPO', 'XIAOMI', 'REDMI', 'VIVO', 'IQOO', 'REALME',
        'ONEPLUS', 'SAMSUNG', 'GALAXY', 'HUAWEI', 'HONOR', 'POCO',
        'FIND', 'RENO', 'MI '];
    for (const kw of keywords) {
        const idx = upper.indexOf(kw);
        if (idx >= 0) {
            return idx;
        }
    }
    return -1;
}
function containsVendorKeyword(str: string): boolean {
    const upper = str.toUpperCase();
    return upper.includes('OPPO') || upper.includes('XIAOMI') || upper.includes('REDMI') ||
        upper.includes('VIVO') || upper.includes('IQOO') || upper.includes('REALME') ||
        upper.includes('ONEPLUS') || upper.includes('SAMSUNG') || upper.includes('GALAXY') ||
        upper.includes('HUAWEI') || upper.includes('HONOR') || upper.includes('POCO') ||
        upper.includes('MI ') || upper.includes('FIND') || upper.includes('RENO');
}
/**
 * 扫描结果的输入参数类型
 */
export interface ScanResultInput {
    deviceId: string;
    deviceName: string;
    rssi: number;
    data: ArrayBuffer;
}
/**
 * 从 ScanResult 中识别是否为互传联盟设备
 */
export function identifyShareDevice(result: ScanResultInput): ShareDeviceInfo {
    const parsed = parseAdvertisementData(result.data);
    const hasShareUuid = isShareServiceUuid(parsed.serviceUuids);
    // 逐级检测厂商：
    // 1. Manufacturer Data 中的厂商ID (最可靠)
    // 2. 设备名称关键词匹配
    // 3. UUID后缀中的厂商Company ID (OPPO Find X9等设备将厂商ID嵌入128-bit UUID)
    let vendor = getVendorByManufacturerId(parsed.manufacturerId);
    if (vendor === ShareVendor.UNKNOWN) {
        vendor = detectVendorByName(result.deviceName || parsed.localName);
    }
    if (vendor === ShareVendor.UNKNOWN) {
        vendor = detectVendorFromUuids(parsed.serviceUuids);
    }
    // 输出解析后的厂商ID和UUID，便于调试
    if (parsed.manufacturerId !== null || parsed.serviceUuids.length > 0 ||
        parsed.localName !== '' || result.deviceName !== '') {
        console.info('ToShare', `Parsed: manuId=0x${(parsed.manufacturerId ?? 0).toString(16).toUpperCase()}, uuids=${parsed.serviceUuids.join(', ')}, localName=${parsed.localName}, apiName=${result.deviceName}`);
    }
    // isShareDevice: 有互传UUID 或 检测到已知厂商
    const isShare = hasShareUuid || vendor !== ShareVendor.UNKNOWN;
    // 逐级获取设备名称：
    // 1. API返回的deviceName
    // 2. BLE广播Local Name
    // 3. 从原始广播数据中提取含厂商关键词的ASCII字符串 (Service Data内嵌名称)
    // 4. 根据厂商生成默认名称
    const rawNameFromData = extractNameFromRawData(new Uint8Array(result.data));
    const deviceName = result.deviceName || parsed.localName || rawNameFromData ||
        (vendor !== ShareVendor.UNKNOWN ? `${vendor}设备` : '未知设备');
    return {
        deviceId: result.deviceId,
        deviceName: deviceName,
        vendor: vendor,
        rssi: result.rssi,
        serviceUuids: parsed.serviceUuids,
        isShareDevice: isShare,
        manufactureId: parsed.manufacturerId,
        manufactureData: parsed.manufacturerData
    };
}
