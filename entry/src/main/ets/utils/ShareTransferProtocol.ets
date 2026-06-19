/**
 * 互传联盟 TCP 传输协议
 *
 * 实现 OPPO/VIVO/小米等厂商使用的互传联盟二进制文件传输协议。
 * TCP 连接建立后，所有通信均通过本协议定义的二进制包完成。
 *
 * ┌──────────────────────────────────────────────────────┐
 * │  包结构 (Packet Header 16字节 + 变长 Payload)        │
 * ├──────────────────────────────────────────────────────┤
 * │  Magic (4B)  "TSHR" = 0x54534852 协议标识           │
 * │  Version (2B)  协议版本号          v1.0 = 0x0100    │
 * │  Command (2B)  命令字                                │
 * │  PayloadLen (4B, BE)  负载长度                       │
 * │  Sequence (4B, BE)  序列号                           │
 * ├──────────────────────────────────────────────────────┤
 * │  Payload (变长)                                      │
 * └──────────────────────────────────────────────────────┘
 */

import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ShareTransferProtocol';

// ==================== 协议常量 ====================

/** 协议 Magic 标识 "TSHR" */
export const PROTOCOL_MAGIC: number = 0x54534852;
/** 协议版本 v1.0 */
export const PROTOCOL_VERSION: number = 0x0100;
/** 包头固定长度 */
export const PACKET_HEADER_LENGTH: number = 16;

// ==================== 命令字 ====================

export enum PacketCommand {
  HANDSHAKE_REQ = 0x0001,
  HANDSHAKE_RESP = 0x0002,
  FILE_INFO = 0x0003,
  FILE_INFO_ACK = 0x0004,
  DATA_CHUNK = 0x0005,
  DATA_ACK = 0x0006,
  TRANSFER_DONE = 0x0007,
  TRANSFER_DONE_ACK = 0x0008,
  CANCEL = 0x0009,
  HEARTBEAT = 0x000A,
  HEARTBEAT_ACK = 0x000B,
  FILE_LIST_INFO = 0x000C,
  FILE_LIST_ACK = 0x000D,
}

// ==================== 传输状态 ====================

export enum TransferPhase {
  IDLE = 0,
  HANDSHAKE = 1,
  METADATA = 2,
  DATA = 3,
  COMPLETE = 4,
  ERROR = 5,
}

// ==================== 协议包结构 ====================

export interface PacketHeader {
  magic: number;
  version: number;
  command: number;
  payloadLength: number;
  sequence: number;
}

export interface Packet {
  header: PacketHeader;
  payload: ArrayBuffer;
}

export interface HandshakePayload {
  deviceName: string;
  protocolVersion: number;
  role: number;
  supportedFeatures: string;
}

export interface FileInfoPayload {
  fileCount: number;
  fileIndex: number;
  fileName: string;
  fileSize: number;
  mimeType: string;
  fileHash: string;
}

export interface DataAckPayload {
  fileIndex: number;
  receivedBytes: number;
  retransmitOffset: number;
}

export interface TransferDonePayload {
  fileIndex: number;
  totalBytes: number;
  checksum: string;
  status: number;
}

// ==================== 序列号管理 ====================

export class SequenceManager {
  private seq: number = 1;

  next(): number {
    const current = this.seq;
    this.seq = ((this.seq + 1) & 0xFFFFFFFF) || 1;
    return current;
  }

  reset(): void {
    this.seq = 1;
  }
}

// ==================== 包编码/解码 ====================

function writeUint32BE(value: number, view: DataView, offset: number): void {
  view.setUint8(offset, (value >> 24) & 0xFF);
  view.setUint8(offset + 1, (value >> 16) & 0xFF);
  view.setUint8(offset + 2, (value >> 8) & 0xFF);
  view.setUint8(offset + 3, value & 0xFF);
}

function writeUint16BE(value: number, view: DataView, offset: number): void {
  view.setUint8(offset, (value >> 8) & 0xFF);
  view.setUint8(offset + 1, value & 0xFF);
}

function readUint32BE(view: DataView, offset: number): number {
  return ((view.getUint8(offset) << 24) >>> 0) |
         (view.getUint8(offset + 1) << 16) |
         (view.getUint8(offset + 2) << 8) |
         view.getUint8(offset + 3);
}

function readUint16BE(view: DataView, offset: number): number {
  return (view.getUint8(offset) << 8) | view.getUint8(offset + 1);
}

/**
 * 预置头部缓冲区, 减少重复分配
 */
const HEADER_BUFFER = new ArrayBuffer(PACKET_HEADER_LENGTH);
const HEADER_VIEW = new DataView(HEADER_BUFFER);

/**
 * 编码一个协议包
 */
export function encodePacket(
  command: PacketCommand,
  payload: ArrayBuffer,
  sequence: number
): ArrayBuffer {
  const totalLen = PACKET_HEADER_LENGTH + payload.byteLength;
  const buffer = new ArrayBuffer(totalLen);
  const view = new DataView(buffer);

  writeUint32BE(PROTOCOL_MAGIC, view, 0);
  writeUint16BE(PROTOCOL_VERSION, view, 4);
  writeUint16BE(command, view, 6);
  writeUint32BE(payload.byteLength, view, 8);
  writeUint32BE(sequence, view, 12);

  if (payload.byteLength > 0) {
    new Uint8Array(buffer, PACKET_HEADER_LENGTH).set(new Uint8Array(payload));
  }

  return buffer;
}

export class ParseResult {
  packets: Packet[] = [];
  remaining: Uint8Array = new Uint8Array(0);

  constructor(packets: Packet[], remaining: Uint8Array) {
    this.packets = packets;
    this.remaining = remaining;
  }
}

/**
 * 从缓冲区解析完整协议包
 */
export function parsePackets(buffer: Uint8Array): ParseResult {
  const packets: Packet[] = [];
  let offset = 0;

  while (offset + PACKET_HEADER_LENGTH <= buffer.length) {
    const view = new DataView(buffer.buffer, buffer.byteOffset + offset);

    const magic = readUint32BE(view, 0);
    if (magic !== PROTOCOL_MAGIC) {
      offset++;
      continue;
    }

    const version = readUint16BE(view, 4);
    const command = readUint16BE(view, 6);
    const payloadLength = readUint32BE(view, 8);
    const sequence = readUint32BE(view, 12);
    const totalPacketLength = PACKET_HEADER_LENGTH + payloadLength;

    if (offset + totalPacketLength > buffer.length) {
      break;
    }

    let payload = new ArrayBuffer(0);
    if (payloadLength > 0) {
      // 只共享视图, 不复制数据
      const src = new Uint8Array(buffer.buffer, buffer.byteOffset + offset + PACKET_HEADER_LENGTH, payloadLength);
      payload = src.buffer.slice(src.byteOffset, src.byteOffset + src.byteLength);
    }

    packets.push({
      header: { magic, version, command, payloadLength, sequence },
      payload,
    });

    offset += totalPacketLength;
  }

  return new ParseResult(packets, buffer.slice(offset));
}

// ==================== 负载编码/解码 ====================

/** 模块级单例避免重复创建 */
const encoder: util.TextEncoder = new util.TextEncoder();
const decoder: util.TextDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });

export function encodeString(str: string): ArrayBuffer {
  return encoder.encodeInto(str).buffer as ArrayBuffer;
}

export function decodeString(buffer: ArrayBuffer): string {
  return decoder.decodeToString(new Uint8Array(buffer));
}

/**
 * 编码握手负载
 */
export function encodeHandshakePayload(payload: HandshakePayload): ArrayBuffer {
  return encodeString(JSON.stringify(payload));
}

/**
 * 解码握手负载
 */
export function decodeHandshakePayload(buffer: ArrayBuffer): HandshakePayload {
  return JSON.parse(decodeString(buffer)) as HandshakePayload;
}

/**
 * 编码文件信息负载
 */
export function encodeFileInfoPayload(payload: FileInfoPayload): ArrayBuffer {
  return encodeString(JSON.stringify(payload));
}

/**
 * 解码文件信息负载
 */
export function decodeFileInfoPayload(buffer: ArrayBuffer): FileInfoPayload {
  return JSON.parse(decodeString(buffer)) as FileInfoPayload;
}

/**
 * 编码数据确认负载 (纯二进制, 12B)
 */
export function encodeDataAckPayload(payload: DataAckPayload): ArrayBuffer {
  const ackBuf = new ArrayBuffer(12);
  const view = new DataView(ackBuf);
  writeUint32BE(payload.fileIndex, view, 0);
  writeUint32BE(payload.receivedBytes, view, 4);
  writeUint32BE(payload.retransmitOffset, view, 8);
  return ackBuf;
}

export class DecodedDataAck implements DataAckPayload {
  fileIndex: number = 0;
  receivedBytes: number = 0;
  retransmitOffset: number = 0;

  constructor(buffer: ArrayBuffer) {
    const view = new DataView(buffer);
    this.fileIndex = readUint32BE(view, 0);
    this.receivedBytes = readUint32BE(view, 4);
    this.retransmitOffset = readUint32BE(view, 8);
  }
}

/**
 * 解码数据确认负载
 */
export function decodeDataAckPayload(buffer: ArrayBuffer): DataAckPayload {
  return new DecodedDataAck(buffer);
}

/**
 * 编码传输完成负载
 */
export function encodeTransferDonePayload(payload: TransferDonePayload): ArrayBuffer {
  return encodeString(JSON.stringify({
    fileIndex: payload.fileIndex,
    totalBytes: payload.totalBytes,
    checksum: payload.checksum,
    status: payload.status,
  }));
}

/**
 * 解码传输完成负载
 */
export function decodeTransferDonePayload(buffer: ArrayBuffer): TransferDonePayload {
  return JSON.parse(decodeString(buffer)) as TransferDonePayload;
}

/**
 * 编码批量文件列表负载
 */
export function encodeFileListPayload(files: FileInfoPayload[]): ArrayBuffer {
  return encodeString(JSON.stringify(files));
}

/**
 * 解码批量文件列表负载
 */
export function decodeFileListPayload(buffer: ArrayBuffer): FileInfoPayload[] {
  return JSON.parse(decodeString(buffer)) as FileInfoPayload[];
}

// ==================== 分片传输辅助 ====================

/** 默认分片大小：64KB (对局域网吞吐量和延迟的合理折中) */
export const DEFAULT_CHUNK_SIZE: number = 65536;

/**
 * 编码数据分片 Payload
 * Payload 格式: [fileIndex:4B][offset:4B][chunkData:变长]
 */
export function encodeDataChunkPayload(
  fileIndex: number,
  offset: number,
  chunkData: ArrayBuffer
): ArrayBuffer {
  const payloadLen = 8 + chunkData.byteLength;
  const buf = new ArrayBuffer(payloadLen);
  const view = new DataView(buf);
  writeUint32BE(fileIndex, view, 0);
  writeUint32BE(offset, view, 4);
  new Uint8Array(buf, 8).set(new Uint8Array(chunkData));
  return buf;
}

export interface DataChunkInfo {
  fileIndex: number;
  offset: number;
  data: ArrayBuffer;
}

export class DecodedDataChunk implements DataChunkInfo {
  fileIndex: number = 0;
  offset: number = 0;
  data: ArrayBuffer = new ArrayBuffer(0);

  constructor(buffer: ArrayBuffer) {
    const view = new DataView(buffer);
    this.fileIndex = readUint32BE(view, 0);
    this.offset = readUint32BE(view, 4);
    this.data = buffer.slice(8);
  }
}

export function decodeDataChunkPayload(buffer: ArrayBuffer): DataChunkInfo {
  return new DecodedDataChunk(buffer);
}

// ==================== 速率计算 ====================

export interface TransferProgress {
  fileIndex: number;
  fileName: string;
  fileSize: number;
  transferredBytes: number;
  speed: number;
  eta: number;
}

export function calculateSpeed(bytesTransferred: number, elapsedMs: number): number {
  if (elapsedMs <= 0) return 0;
  return Math.round((bytesTransferred / elapsedMs) * 1000);
}

export function calculateEta(remaining: number, speed: number): number {
  if (speed <= 0) return -1;
  return Math.ceil(remaining / speed);
}

// ==================== 协议兼容性检测 ====================

export function isCompatibleVersion(version: number): boolean {
  return version >= 0x0100 && version <= 0x01FF;
}

// ==================== 握手包构造 ====================

/**
 * 构造握手请求
 */
export function buildHandshakeReq(
  deviceName: string,
  role: number,
  seqManager: SequenceManager,
): Packet {
  const seq = seqManager.next();
  const payload = encodeHandshakePayload({
    deviceName,
    protocolVersion: PROTOCOL_VERSION,
    role,
    supportedFeatures: JSON.stringify({
      maxChunkSize: DEFAULT_CHUNK_SIZE,
      encryption: false,
      compression: false,
    }),
  });

  return {
    header: {
      magic: PROTOCOL_MAGIC,
      version: PROTOCOL_VERSION,
      command: PacketCommand.HANDSHAKE_REQ,
      payloadLength: payload.byteLength,
      sequence: seq,
    },
    payload,
  };
}

/**
 * 构造握手响应
 */
export function buildHandshakeResp(
  deviceName: string,
  role: number,
  seq: number,
  accept: boolean,
): Packet {
  const payload = encodeHandshakePayload({
    deviceName,
    protocolVersion: PROTOCOL_VERSION,
    role,
    supportedFeatures: JSON.stringify({
      accepted: accept,
      maxChunkSize: DEFAULT_CHUNK_SIZE,
      encryption: false,
      compression: false,
    }),
  });

  return {
    header: {
      magic: PROTOCOL_MAGIC,
      version: PROTOCOL_VERSION,
      command: PacketCommand.HANDSHAKE_RESP,
      payloadLength: payload.byteLength,
      sequence: seq,
    },
    payload,
  };
}
