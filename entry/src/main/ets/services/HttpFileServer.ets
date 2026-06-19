/**
 * HTTP 文件服务器——基于 TCPSocketServer 的轻量 HTTP 服务器
 */

import { socket } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import util from '@ohos.util';
import { HotspotFileItem } from '../models/HotspotTypes';

const TAG = 'HttpFileServer';
const UPLOAD_DIR: string = '/data/storage/el2/base/haps/entry/files/hotspot_uploads';

function mimeFromExt(ext: string): string {
  const extLc: string = ext.toLowerCase();
  if (extLc === 'jpg' || extLc === 'jpeg') {
    return 'image/jpeg';
  }
  if (extLc === 'png') {
    return 'image/png';
  }
  if (extLc === 'gif') {
    return 'image/gif';
  }
  if (extLc === 'mp4') {
    return 'video/mp4';
  }
  if (extLc === 'pdf') {
    return 'application/pdf';
  }
  if (extLc === 'zip' || extLc === 'rar' || extLc === '7z') {
    return 'application/zip';
  }
  if (extLc === 'txt') {
    return 'text/plain';
  }
  if (extLc === 'apk') {
    return 'application/vnd.android.package-archive';
  }
  if (extLc === 'html' || extLc === 'htm') {
    return 'text/html';
  }
  if (extLc === 'css') {
    return 'text/css';
  }
  if (extLc === 'js') {
    return 'application/javascript';
  }
  return 'application/octet-stream';
}

export interface HttpServerResponseEvent {
  type: string;
  message?: string;
  fileName?: string;
  progress?: number;
}

export type HttpServerCallback = (event: HttpServerResponseEvent) => void;

interface MultipartPart {
  filename: string;
  data: Uint8Array;
}

export class HttpFileServer {
  private static instance: HttpFileServer;
  private tcpServer: socket.TCPSocketServer | null = null;
  private _running: boolean = false;
  private _port: number = 0;
  private files: HotspotFileItem[] = [];
  private eventListeners: HttpServerCallback[] = [];
  private acceptHandler: ((conn: socket.TCPSocketConnection) => void) | null = null;
  private encoder: util.TextEncoder = new util.TextEncoder();

  static getInstance(): HttpFileServer {
    if (!HttpFileServer.instance) {
      HttpFileServer.instance = new HttpFileServer();
    }
    return HttpFileServer.instance;
  }

  get running(): boolean {
    return this._running;
  }

  get port(): number {
    return this._port;
  }

  get fileList(): HotspotFileItem[] {
    const out: HotspotFileItem[] = [];
    for (let i = 0; i < this.files.length; i++) {
      out.push(this.files[i]);
    }
    return out;
  }

  addListener(cb: HttpServerCallback): void {
    if (!this.eventListeners.includes(cb)) {
      this.eventListeners.push(cb);
    }
  }

  removeListener(cb: HttpServerCallback): void {
    const idx: number = this.eventListeners.indexOf(cb);
    if (idx >= 0) {
      this.eventListeners.splice(idx, 1);
    }
  }

  private emit(type: string, message?: string, fileName?: string, progress?: number): void {
    const evt: HttpServerResponseEvent = { type, message, fileName, progress };
    for (let i = 0; i < this.eventListeners.length; i++) {
      try {
        this.eventListeners[i](evt);
      } catch (e) {
        hilog.error(0x0001, TAG, 'event cb err: %{public}s', JSON.stringify(e));
      }
    }
  }

  async start(port: number): Promise<boolean> {
    if (this._running) {
      return true;
    }

    try {
      this.ensureUploadDir();

      this.tcpServer = socket.constructTCPSocketServerInstance();

      this.acceptHandler = (conn: socket.TCPSocketConnection): void => {
        this.handleConnection(conn);
      };
      this.tcpServer.on('connect', this.acceptHandler);

      const addr: socket.NetAddress = { address: '0.0.0.0', port, family: 1 };
      await this.tcpServer.listen(addr);

      this._port = port;
      this._running = true;
      hilog.info(0x0001, TAG, 'HTTP server on %{public}d', port);
      this.emit('started', '服务已启动 :' + port);
      return true;
    } catch (err) {
      hilog.error(0x0001, TAG, 'start fail: %{public}s', JSON.stringify(err));
      this.emit('error', '启动失败: ' + (err as Error).message);
      this.cleanupServer();
      return false;
    }
  }

  async stop(): Promise<void> {
    this._running = false;
    this.cleanupServer();
    this.emit('stopped', '服务已关闭');
  }

  private cleanupServer(): void {
    if (this.tcpServer) {
      if (this.acceptHandler) {
        try {
          this.tcpServer.off('connect', this.acceptHandler);
        } catch (_e) { /* ignore */ }
        this.acceptHandler = null;
      }
      try {
        this.tcpServer.close();
      } catch (_e) { /* ignore */ }
      this.tcpServer = null;
    }
  }

  addDownloadedFile(name: string, size: number, savePath: string): void {
    const ext: string = name.split('.').pop() || '';
    const item: HotspotFileItem = {
      name, size,
      mimeType: mimeFromExt(ext),
      savePath,
      direction: 'download',
      completedAt: Date.now(),
    };
    this.files.push(item);
  }

  // ==================== 连接处理 ====================

  private async handleConnection(conn: socket.TCPSocketConnection): Promise<void> {
    let buf: Uint8Array = new Uint8Array(0);

    try {
      while (this._running) {
        const rawData: ArrayBuffer = await this.waitForData(conn);
        if (rawData.byteLength === 0) {
          break;
        }

        const arr: Uint8Array = new Uint8Array(rawData);
        const tmp: Uint8Array = new Uint8Array(buf.length + arr.length);
        tmp.set(buf);
        tmp.set(arr, buf.length);
        buf = tmp;

        const result: ParsedRequest | null = this.tryParse(buf);
        if (result === null) {
          if (buf.length > 131072) {
            break;
          }
          continue;
        }

        await this.dispatch(conn, result);
        buf = buf.slice(result.consumedBytes);
      }
    } catch (e) {
      hilog.warn(0x0001, TAG, 'conn err');
    } finally {
      try {
        conn.close();
      } catch (_e) { /* ignore */ }
    }
  }

  private waitForData(conn: socket.TCPSocketConnection): Promise<ArrayBuffer> {
    return new Promise((resolve) => {
      conn.on('message', (info: socket.SocketMessageInfo): void => {
        resolve(info.message);
      });
      setTimeout(() => {
        resolve(new ArrayBuffer(0));
      }, 300000);
    });
  }

  // ==================== HTTP 解析 ====================

  private tryParse(buf: Uint8Array): ParsedRequest | null {
    const headerEnd: number = this.findSeq(buf, [0x0d, 0x0a, 0x0d, 0x0a]);
    if (headerEnd < 0) {
      return null;
    }
    const headerStr: string = this.toAscii(buf.slice(0, headerEnd));
    const lines: string[] = headerStr.split('\r\n');
    if (lines.length < 1) {
      return null;
    }

    const rl: string[] = lines[0].split(' ');
    if (rl.length < 3) {
      return null;
    }

    const method: string = rl[0].toUpperCase();
    const fullPath: string = rl[1];
    const qIdx: number = fullPath.indexOf('?');
    const path: string = qIdx >= 0 ? fullPath.substring(0, qIdx) : fullPath;
    const queryStr: string = qIdx >= 0 ? fullPath.substring(qIdx + 1) : '';
    const query: Record<string, string> = this.parseQuery(queryStr);

    const headers: Record<string, string> = {};
    for (let i = 1; i < lines.length; i++) {
      const ci: number = lines[i].indexOf(':');
      if (ci > 0) {
        headers[lines[i].substring(0, ci).trim().toLowerCase()] = lines[i].substring(ci + 1).trim();
      }
    }

    const contentLen: number = parseInt(headers['content-length'] || '0', 10);
    const bodyStart: number = headerEnd + 4;
    if (buf.length < bodyStart + contentLen) {
      return null;
    }
    const body: Uint8Array = buf.slice(bodyStart, bodyStart + contentLen);

    return new ParsedRequest(method, path, query, headers, body, bodyStart + contentLen);
  }

  private findSeq(buf: Uint8Array, seq: number[]): number {
    for (let i = 0; i <= buf.length - seq.length; i++) {
      let match: boolean = true;
      for (let j = 0; j < seq.length; j++) {
        if (buf[i + j] !== seq[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        return i;
      }
    }
    return -1;
  }

  private findSeqUint8(buf: Uint8Array, seq: Uint8Array): number {
    for (let i = 0; i <= buf.length - seq.length; i++) {
      let match: boolean = true;
      for (let j = 0; j < seq.length; j++) {
        if (buf[i + j] !== seq[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        return i;
      }
    }
    return -1;
  }

  private toAscii(buf: Uint8Array): string {
    let s: string = '';
    for (let i = 0; i < buf.length; i++) {
      s += String.fromCharCode(buf[i]);
    }
    return s;
  }

  private parseQuery(qs: string): Record<string, string> {
    const r: Record<string, string> = {};
    if (qs.length === 0) {
      return r;
    }
    const parts: string[] = qs.split('&');
    for (let i = 0; i < parts.length; i++) {
      const p: string = parts[i];
      const ei: number = p.indexOf('=');
      if (ei > 0) {
        r[decodeURIComponent(p.substring(0, ei))] = decodeURIComponent(p.substring(ei + 1));
      } else if (p.length > 0) {
        r[decodeURIComponent(p)] = '';
      }
    }
    return r;
  }

  private buildResp(status: number, statusText: string, ctype: string, body: string): Uint8Array {
    const bodyBytes: Uint8Array = this.encoder.encode(body);
    const headerStr: string =
      'HTTP/1.1 ' + status + ' ' + statusText + '\r\n' +
      'Content-Type: ' + ctype + '\r\n' +
      'Content-Length: ' + bodyBytes.byteLength + '\r\n' +
      'Connection: close\r\n' +
      'Access-Control-Allow-Origin: *\r\n' +
      '\r\n';
    const headerBytes: Uint8Array = this.encoder.encode(headerStr);
    const result: Uint8Array = new Uint8Array(headerBytes.byteLength + bodyBytes.byteLength);
    result.set(headerBytes);
    result.set(bodyBytes, headerBytes.byteLength);
    return result;
  }

  private buildRawResp(extraHeaders: string[], body: Uint8Array): Uint8Array {
    let headerStr: string = 'HTTP/1.1 200 OK\r\nContent-Length: ' + body.byteLength + '\r\nConnection: close\r\nAccess-Control-Allow-Origin: *\r\n';
    for (let i = 0; i < extraHeaders.length; i++) {
      headerStr += extraHeaders[i] + '\r\n';
    }
    headerStr += '\r\n';
    const headerBytes: Uint8Array = this.encoder.encode(headerStr);
    const result: Uint8Array = new Uint8Array(headerBytes.byteLength + body.byteLength);
    result.set(headerBytes);
    result.set(body, headerBytes.byteLength);
    return result;
  }

  // ==================== 请求分发 ====================

  private async dispatch(conn: socket.TCPSocketConnection, req: ParsedRequest): Promise<void> {
    try {
      let resp: Uint8Array;

      if (req.path === '/') {
        resp = this.buildResp(200, 'OK', 'text/html; charset=utf-8', this.webUiHtml());
      } else if (req.path === '/files') {
        resp = this.buildResp(200, 'OK', 'application/json; charset=utf-8', this.filesJson());
      } else if (req.path === '/status') {
        resp = this.buildResp(200, 'OK', 'application/json; charset=utf-8', this.statusJson());
      } else if (req.method === 'POST' && req.path === '/upload') {
        await this.doUpload(conn, req);
        return;
      } else if (req.path === '/download') {
        await this.doDownload(conn, req);
        return;
      } else if (req.path === '/delete') {
        await this.doDelete(conn, req);
        return;
      } else {
        resp = this.buildResp(404, 'Not Found', 'text/plain', 'Not Found');
      }

      await this.sendAll(conn, resp);
    } catch (e) {
      hilog.error(0x0001, TAG, 'dispatch err');
      try {
        await this.sendAll(conn, this.buildResp(500, 'Error', 'text/plain', 'Error'));
      } catch (_e) { /* ignore */ }
    }
  }

  private sendAll(conn: socket.TCPSocketConnection, data: Uint8Array): Promise<void> {
    return new Promise((resolve, reject) => {
      conn.send({ data: data.buffer as ArrayBuffer }, (err?: BusinessError): void => {
        if (err) {
          reject(err);
        } else {
          resolve();
        }
      });
    });
  }

  // ==================== 文件上传 ====================

  private async doUpload(conn: socket.TCPSocketConnection, req: ParsedRequest): Promise<void> {
    const ct: string = req.headers['content-type'] || '';
    if (!ct.includes('multipart/form-data')) {
      await this.sendAll(conn, this.buildResp(400, 'Bad Request', 'text/plain', 'Expected multipart'));
      return;
    }

    const bm: RegExpMatchArray | null = ct.match(/boundary=(.+?)(?:;|$)/);
    if (bm === null) {
      await this.sendAll(conn, this.buildResp(400, 'Bad Request', 'text/plain', 'No boundary'));
      return;
    }
    const boundary: string = bm[1];

    const parts: MultipartPart[] = this.parseMultipart(req.body, boundary);
    let saved: number = 0;

    for (let i = 0; i < parts.length; i++) {
      const part: MultipartPart = parts[i];
      if (part.filename.length > 0) {
        try {
          const savePath: string = UPLOAD_DIR + '/' + Date.now() + '_' + part.filename;
          this.writeFile(savePath, part.data);
          const ext: string = part.filename.split('.').pop() || '';
          const item: HotspotFileItem = {
            name: part.filename,
            size: part.data.byteLength,
            mimeType: mimeFromExt(ext),
            savePath,
            direction: 'upload',
            completedAt: Date.now(),
          };
          this.files.push(item);
          saved++;
          this.emit('fileReceived', part.filename, part.filename);
        } catch (e) {
          hilog.error(0x0001, TAG, 'save upload err: %{public}s', JSON.stringify(e));
        }
      }
    }

    const html: string = '<html><body><h2>' + saved + ' 个文件已接收</h2><p><a href="/">返回</a></p></body></html>';
    await this.sendAll(conn, this.buildResp(200, 'OK', 'text/html; charset=utf-8', html));
  }

  private parseMultipart(body: Uint8Array, boundary: string): MultipartPart[] {
    const parts: MultipartPart[] = [];
    const bEncoded: Uint8Array = this.encoder.encode('--' + boundary);
    const eEncoded: Uint8Array = this.encoder.encode('--' + boundary + '--');

    let pos: number = 0;
    let start: number = this.findSeqUint8(body, bEncoded);
    if (start < 0) {
      return parts;
    }
    pos = start + bEncoded.length;

    while (pos < body.length) {
      if (body[pos] === 0x0d && pos + 1 < body.length && body[pos + 1] === 0x0a) {
        pos += 2;
      }
      if (this.findSeqUint8(body.slice(pos), eEncoded) === 0) {
        break;
      }

      const he: number = this.findSeq(body.slice(pos), [0x0d, 0x0a, 0x0d, 0x0a]);
      if (he < 0) {
        break;
      }

      const hStr: string = this.toAscii(body.slice(pos, pos + he));
      let fn: string = '';
      const headerLines: string[] = hStr.split('\r\n');
      for (let li = 0; li < headerLines.length; li++) {
        const line: string = headerLines[li];
        if (line.startsWith('Content-Disposition:')) {
          const fm: RegExpMatchArray | null = line.match(/filename="([^"]+)"/);
          if (fm !== null) {
            fn = fm[1];
          }
        }
      }

pos += he + 4;
      const nb: number = this.findSeqUint8(body.slice(pos), bEncoded);
      const dLen: number = nb >= 0 ? nb : body.length - pos;
      const d: Uint8Array = body.slice(pos, pos + dLen);
      parts.push({ filename: fn, data: d });

      if (nb < 0) {
        break;
      }
      pos += nb;
    }

    return parts;
  }

  // ==================== 文件下载 ====================

  private async doDownload(conn: socket.TCPSocketConnection, req: ParsedRequest): Promise<void> {
    const name: string = req.query['n'] || '';
    if (name.length === 0) {
      await this.sendAll(conn, this.buildResp(400, 'Bad Request', 'text/plain', 'Missing name'));
      return;
    }
    const decodedName: string = decodeURIComponent(name);
    let found: HotspotFileItem | null = null;
    for (let i = 0; i < this.files.length; i++) {
      if (this.files[i].name === decodedName) {
        found = this.files[i];
        break;
      }
    }
    if (found === null) {
      await this.sendAll(conn, this.buildResp(404, 'Not Found', 'text/plain', 'Not found'));
      return;
    }

    try {
      const fd: fileIo.File = fileIo.openSync(found.savePath, fileIo.OpenMode.READ_ONLY);
      try {
        const stat = fileIo.statSync(found.savePath);
        const buf: ArrayBuffer = new ArrayBuffer(stat.size);
        fileIo.readSync(fd.fd, buf);
        const ext: string = found.name.split('.').pop() || '';
        const body: Uint8Array = new Uint8Array(buf);
        const extraHeaders: string[] = [];
        extraHeaders.push('Content-Type: ' + mimeFromExt(ext));
        extraHeaders.push('Content-Disposition: attachment; filename="' + encodeURIComponent(found.name) + '"');
        await this.sendAll(conn, this.buildRawResp(extraHeaders, body));
      } finally {
        fileIo.closeSync(fd);
      }
    } catch (e) {
      await this.sendAll(conn, this.buildResp(500, 'Error', 'text/plain', 'Read failed'));
    }
  }

  // ==================== 文件删除 ====================

  private async doDelete(conn: socket.TCPSocketConnection, req: ParsedRequest): Promise<void> {
    const name: string = req.query['n'] || '';
    if (name.length === 0) {
      await this.sendAll(conn, this.buildResp(400, 'Bad Request', 'text/plain', 'Missing name'));
      return;
    }
    const decodedName: string = decodeURIComponent(name);
    let idx: number = -1;
    for (let i = 0; i < this.files.length; i++) {
      if (this.files[i].name === decodedName) {
        idx = i;
        break;
      }
    }
    if (idx < 0) {
      await this.sendAll(conn, this.buildResp(404, 'Not Found', 'text/plain', 'Not found'));
      return;
    }
    try {
      fileIo.unlinkSync(this.files[idx].savePath);
    } catch (_e) { /* ignore */ }
    this.files.splice(idx, 1);
    await this.sendAll(conn, this.buildResp(200, 'OK', 'application/json', JSON.stringify({ success: true })));
  }

  // ==================== JSON ====================

  private filesJson(): string {
    const arr: string[] = [];
    for (let i = 0; i < this.files.length; i++) {
      const f = this.files[i];
      arr.push('{"name":"' + this.escapeJson(f.name) + '","size":' + f.size + ',"mimeType":"' + this.escapeJson(f.mimeType) + '","direction":"' + f.direction + '","completedAt":' + f.completedAt + '}');
    }
    return '[' + arr.join(',') + ']';
  }

  private statusJson(): string {
    let totalSize: number = 0;
    for (let i = 0; i < this.files.length; i++) {
      totalSize += this.files[i].size;
    }
    return '{"running":' + this._running + ',"port":' + this._port + ',"fileCount":' + this.files.length + ',"totalSize":' + totalSize + '}';
  }

  private escapeJson(s: string): string {
    let out: string = '';
    for (let i = 0; i < s.length; i++) {
      const c: string = s[i];
      if (c === '"') {
        out += '\\"';
      } else if (c === '\\') {
        out += '\\\\';
      } else if (c === '\n') {
        out += '\\n';
      } else if (c === '\r') {
        out += '\\r';
      } else if (c === '\t') {
        out += '\\t';
      } else {
        out += c;
      }
    }
    return out;
  }

  // ==================== 文件 I/O ====================

  private ensureUploadDir(): void {
    try {
      fileIo.mkdirSync(UPLOAD_DIR, true);
    } catch (_e) { /* ignore */ }
  }

  private writeFile(path: string, data: Uint8Array): void {
    const fd: fileIo.File = fileIo.openSync(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
    try {
      fileIo.writeSync(fd.fd, data);
    } finally {
      fileIo.closeSync(fd);
    }
  }

  // ==================== Web UI ====================

  private webUiHtml(): string {
    return '<!DOCTYPE html><html lang="zh-CN"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"><title>ToShare</title><style>*{margin:0;padding:0;box-sizing:border-box}body{font-family:-apple-system,BlinkMacSystemFont,sans-serif;background:linear-gradient(135deg,#2D1B69,#4834D4,#6C5CE7,#A29BFE);min-height:100vh;padding:16px;color:#333}.c{max-width:600px;margin:0 auto}.hdr{text-align:center;padding:24px 0 16px;color:#fff}.hdr h1{font-size:28px;font-weight:700;letter-spacing:1px}.hdr p{font-size:13px;opacity:.8;margin-top:6px}.card{background:rgba(255,255,255,.95);border-radius:24px;padding:20px;margin-bottom:16px;box-shadow:0 8px 32px rgba(0,0,0,.12)}.ct{font-size:15px;font-weight:600;color:#6C5CE7;margin-bottom:12px}.ua{border:2px dashed #A29BFE;border-radius:16px;padding:32px 16px;text-align:center;cursor:pointer}.ua p{font-size:15px;color:#6C5CE7;font-weight:500;margin-top:8px}.ua span{font-size:12px;color:#999;display:block;margin-top:6px}.btn{display:inline-block;padding:10px 24px;border-radius:20px;border:none;font-size:14px;font-weight:600;cursor:pointer;text-decoration:none;color:#fff;margin:2px}.btn-pri{background:linear-gradient(135deg,#6C5CE7,#A29BFE)}.btn-del{background:#FF6B6B}.btn-sm{padding:6px 14px;font-size:12px;border-radius:14px}.fl{list-style:none}.fi{display:flex;align-items:center;padding:12px 0;border-bottom:1px solid #f0f0f0}.fiv{width:40px;height:40px;border-radius:12px;background:linear-gradient(135deg,#6C5CE7,#A29BFE);display:flex;align-items:center;justify-content:center;color:#fff;font-size:18px;margin-right:12px;flex-shrink:0}.fii{flex:1;min-width:0}.fn{font-size:14px;font-weight:500;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.fm{font-size:11px;color:#999;margin-top:2px}.fa{display:flex;gap:6px;flex-shrink:0}.bdg{display:inline-block;padding:2px 8px;border-radius:10px;font-size:10px;font-weight:600}.bdg-u{background:#55EFC4;color:#006644}.bdg-d{background:#6C5CE7;color:#fff}.pb{height:4px;background:#E8E0FF;border-radius:2px;overflow:hidden}.pf{height:100%;background:linear-gradient(90deg,#6C5CE7,#A29BFE);border-radius:2px;transition:width .3s}.emp{text-align:center;padding:24px;color:#999}</style></head><body><div class="c"><div class="hdr"><h1>ToShare</h1><p>文件互传 · WiFi 热点直连</p></div><div class="card"><div class="ct">上传文件</div><div class="ua" onclick="document.getElementById(\'fi\').click()"><p>点击选择文件</p><span>支持任何格式</span><input type="file" id="fi" multiple onchange="up(this.files)" style="display:none"></div><div id="upg" style="display:none;margin-top:12px"><div class="pb"><div class="pf" id="upf" style="width:0%"></div></div><p id="upt" style="font-size:12px;color:#999;margin-top:6px"></p></div></div><div class="card"><div class="ct"><span>文件列表</span><span id="fc" style="font-size:12px;color:#999;font-weight:400;margin-left:8px">0 个</span></div><ul class="fl" id="fl"><li class="emp"><p>暂无文件</p></li></ul></div><div class="card"><div class="ct">使用说明</div><ol style="padding-left:18px;font-size:13px;color:#666;line-height:1.8"><li>连上 ToShare 热点</li><li>浏览器打开此地址</li><li>上传文件</li><li>可随时下载</li></ol></div></div><script>function sz(b){if(b<1024)return b+\'B\';if(b<1048576)return(b/1024).toFixed(1)+\'KB\';return(b/1048576).toFixed(1)+\'MB\'}function ic(n){var e=n.split(\'.\').pop();if([\'jpg\',\'jpeg\',\'png\',\'gif\'].indexOf(e)>=0)return\'🖼\';if([\'mp4\',\'mov\'].indexOf(e)>=0)return\'🎬\';if([\'pdf\'].indexOf(e)>=0)return\'📄\';if([\'zip\',\'rar\'].indexOf(e)>=0)return\'🗜\';return\'📁\'}async function ld(){try{var r=await fetch(\'/files\'),fs=await r.json();document.getElementById(\'fc\').textContent=fs.length+\' 个\';var l=document.getElementById(\'fl\');if(!fs.length){l.innerHTML=\'<li class="emp"><p>暂无文件</p></li>\';return}l.innerHTML=\'\';for(var i=0;i<fs.length;i++){var f=fs[i];l.innerHTML+=\'<li class="fi"><div class="fiv">\'+ic(f.name)+\'</div><div class="fii"><div class="fn">\'+f.name+\'</div><div class="fm">\'+sz(f.size)+\' \'+(f.direction===\'upload\'?\'<span class="bdg bdg-u">上传</span>\':\'<span class="bdg bdg-d">下载</span>\')+\'</div></div><div class="fa"><a href="/download?n=\'+encodeURIComponent(f.name)+\'" class="btn btn-pri btn-sm">下载</a><button class="btn btn-del btn-sm" onclick="df(\\\'\'+encodeURIComponent(f.name)+\'\\\')">删除</button></div></li>\'}}}catch(e){console.error(e)}}function up(fs){if(!fs.length)return;var f=new FormData();for(var i=0;i<fs.length;i++)f.append(\'file\',fs[i]);var p=document.getElementById(\'upg\'),pf=document.getElementById(\'upf\'),pt=document.getElementById(\'upt\');p.style.display=\'block\';pf.style.width=\'50%\';pt.textContent=\'上传中...\';var x=new XMLHttpRequest();x.upload.onprogress=function(e){if(e.lengthComputable){pf.style.width=Math.round(e.loaded/e.total*100)+\'%\';pt.textContent=sz(e.loaded)+\' / \'+sz(e.total)}};x.onload=function(){pf.style.width=\'100%\';pt.textContent=\'完成\';setTimeout(function(){p.style.display=\'none\'},2000);ld()};x.open(\'POST\',\'/upload\',true);x.send(f)}function df(n){if(!confirm(\'删除?\'))return;fetch(\'/delete?n=\'+n).then(function(){ld()})}ld();setInterval(ld,3000)</script></body></html>';
  }
}

class ParsedRequest {
  method: string;
  path: string;
  query: Record<string, string>;
  headers: Record<string, string>;
  body: Uint8Array;
  consumedBytes: number;

  constructor(method: string, path: string, query: Record<string, string>, headers: Record<string, string>, body: Uint8Array, consumedBytes: number) {
    this.method = method;
    this.path = path;
    this.query = query;
    this.headers = headers;
    this.body = body;
    this.consumedBytes = consumedBytes;
  }
}
