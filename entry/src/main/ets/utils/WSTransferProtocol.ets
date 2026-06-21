/**
 * 文本传输协议 — 替代 ShareTransferProtocol 的二进制协议
 *
 * 借鉴 CatShare 设计思路：
 *   - 控制消息: 纯文本行（替代二进制 Packet 编解码）
 *   - 文件数据: HTTP GET（复用 HttpFileServer）
 *
 * 消息格式: type:id:name?{json_payload}
 *   示例: action:0:versionNegotiation?{"version":1}
 *         ack:0:versionNegotiation
 *         action:1:task?{"taskId":"xxx","files":[...]}
 *         ack:1:task
 */

import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'WSTransferProtocol';

// ==================== 消息类型 ====================

export enum WsMessageType {
  ACTION = 'action',
  ACK = 'ack',
  ERROR = 'error',
}

export enum WsActionName {
  VERSION_NEGOTIATION = 'versionNegotiation',
  TASK = 'task',
  STATUS = 'status',
  DONE = 'done',
  CANCEL = 'cancel',
}

// ==================== 消息模型 ====================

export interface WsMessage {
  type: string;
  id: number;
  name: string;
  payload?: Record<string, Object>;
}

export interface TaskFileItem {
  id: number;
  name: string;
  size: number;
  mimeType: string;
  hash?: string;
}

export interface TaskPayload {
  taskId: string;
  senderName: string;
  fileCount: number;
  totalSize: number;
  files: TaskFileItem[];
  catShareText?: string;
  httpPort?: number;
  encrypted?: boolean;
  iv?: string;
}

export interface StatusPayload {
  taskId: string;
  type: number;  // 0=progress, 1=ready, 2=error, 3=complete
  reason: string;
  progress?: number;
  downloadedBytes?: number;
  currentFileId?: number;
}

export interface VersionNegotiationPayload {
  version: number;
  versions: number[];
  features?: object;
}

// ArkTS 兼容的对象类型，用于函数返回和参数传递

// ==================== 消息编解码 ====================

const MSG_PATTERN = /^(\w+):(\d+):(\w+)(?:\?(.*))?$/;

export function parseWsMessage(text: string): WsMessage | null {
  const match = text.match(MSG_PATTERN);
  if (match === null) { return null; }
  let payload: Record<string, Object> | undefined;
  if (match[4] !== undefined && match[4].length > 0) {
    try {
      const parsed = JSON.parse(match[4]) as Record<string, Object>;
      payload = parsed;
    } catch (_e) {
      return null;
    }
  }
  const result: WsMessage = { type: match[1], id: parseInt(match[2], 10), name: match[3], payload: payload };
  return result;
}

export function buildWsMessage(type: string, id: number, name: string, payload?: string): string {
  let msg = type + ':' + id + ':' + name;
  if (payload !== undefined) {
    msg += '?' + payload;
  }
  return msg;
}

export function buildAck(id: number, name: string): string {
  return buildWsMessage('ack', id, name);
}

// ==================== 专用构建 ====================

export function buildVersionNegotiation(id: number): string {
  return 'action:' + id + ':versionNegotiation?{"version":1,"versions":[1]}';
}

export function buildTaskPayload(taskId: string, senderName: string, files: TaskFileItem[],
                                  catShareText?: string, httpPort?: number,
                                  encrypted?: boolean, iv?: string): string {
  let totalSize = 0;
  for (let i = 0; i < files.length; i++) { totalSize += files[i].size; }
  let json = '{"taskId":"' + taskId + '","senderName":"' + senderName + '","fileCount":' + files.length + ',"totalSize":' + totalSize;
  json += ',"files":[';
  for (let j = 0; j < files.length; j++) {
    if (j > 0) { json += ','; }
    const f = files[j];
    let fjson = '{"id":' + f.id + ',"name":"' + f.name + '","size":' + f.size + ',"mimeType":"' + f.mimeType + '"';
    if (f.hash !== undefined) { fjson += ',"hash":"' + f.hash + '"'; }
    fjson += '}';
    json += fjson;
  }
  json += ']';
  if (catShareText !== undefined) { json += ',"catShareText":"' + catShareText + '"'; }
  if (httpPort !== undefined) { json += ',"httpPort":' + httpPort; }
  if (encrypted === true) { json += ',"encrypted":true'; }
  if (iv !== undefined) { json += ',"iv":"' + iv + '"'; }
  json += '}';
  return json;
}

export function buildStatusPayload(taskId: string, type: number, reason: string,
                                    progress?: number, downloadedBytes?: number,
                                    currentFileId?: number): string {
  let json = '{"taskId":"' + taskId + '","type":' + type + ',"reason":"' + reason + '"';
  if (progress !== undefined) { json += ',"progress":' + progress; }
  if (downloadedBytes !== undefined) { json += ',"downloadedBytes":' + downloadedBytes; }
  if (currentFileId !== undefined) { json += ',"currentFileId":' + currentFileId; }
  json += '}';
  return json;
}

// ==================== 常量 ====================

export const PROTOCOL_VERSION = 1;
export const DEFAULT_HTTP_PORT = 24681;
export const TEXT_MSG_TERMINATOR = '\n';
