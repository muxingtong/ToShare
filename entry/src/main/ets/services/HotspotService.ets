/**
 * 热点服务——检测系统热点状态，管理 HTTP 服务器生命周期
 *
 * 系统热点需要用户在设置/控制中心手动开启。
 * 热点激活后，App 自动启动 HTTP 文件服务器，其他设备连接后
 * 浏览器访问即可上传/下载文件。
 */

import { wifiManager } from '@kit.ConnectivityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HotspotState, HotspotConfig, HotspotEvent } from '../models/HotspotTypes';

const TAG = 'HotspotService';
const DEFAULT_PORT: number = 24680;

export type HotspotEventCallback = (event: HotspotEvent) => void;

export class HotspotService {
  private static instance: HotspotService;
  private eventListeners: HotspotEventCallback[] = [];
  private _state: HotspotState = HotspotState.DISABLED;
  private _config: HotspotConfig | null = null;
  private stateChangeHandler: ((state: number) => void) | null = null;
  private pollingTimer: number = -1;

  static getInstance(): HotspotService {
    if (!HotspotService.instance) {
      HotspotService.instance = new HotspotService();
    }
    return HotspotService.instance;
  }

  get state(): HotspotState {
    return this._state;
  }

  get config(): HotspotConfig | null {
    return this._config;
  }

  get isActive(): boolean {
    return this._state === HotspotState.ACTIVE;
  }

  addListener(cb: HotspotEventCallback): void {
    if (!this.eventListeners.includes(cb)) {
      this.eventListeners.push(cb);
    }
  }

  removeListener(cb: HotspotEventCallback): void {
    const idx = this.eventListeners.indexOf(cb);
    if (idx >= 0) {
      this.eventListeners.splice(idx, 1);
    }
  }

  private emit(type: string, message?: string, progress?: number, fileName?: string): void {
    const evt: HotspotEvent = { type, message, progress, fileName };
    for (const cb of this.eventListeners) {
      try {
        cb(evt);
      } catch (e) {
        hilog.error(0x0001, TAG, 'Event cb error: %{public}s', JSON.stringify(e));
      }
    }
  }

  private changeState(state: HotspotState, msg?: string): void {
    this._state = state;
    this.emit('stateChange', msg);
  }

  /**
   * 开始监听热点状态，检测到热点激活后自动启动 HTTP 服务
   */
  async start(port: number = DEFAULT_PORT): Promise<boolean> {
    if (this._state === HotspotState.ACTIVE) {
      return true;
    }

    this.changeState(HotspotState.STARTING, '等待系统热点开启...');

    try {
      // 注册热点状态变化监听
      this.registerHotspotStateListener();

      // 检查是否已激活
      if (this.isHotspotActive()) {
        const ip = await this.resolveGatewayIp();
        if (ip) {
          this._config = { ssid: '', password: '', gatewayIp: ip, port };
          this.changeState(HotspotState.ACTIVE, `热点已就绪`);
          return true;
        }
      }

      // 启动轮询——用户可能在控制中心开启
      this.startPolling();

      setTimeout(() => {
        if (this._state !== HotspotState.ACTIVE) {
          this.emit('info', '请在系统设置或控制中心开启便携热点');
        }
      }, 2000);

      return true;
    } catch (err) {
      hilog.error(0x0001, TAG, 'start hotspot service error: %{public}s', JSON.stringify(err));
      this.changeState(HotspotState.ERROR, `启动失败: ${(err as Error).message}`);
      return false;
    }
  }

  /**
   * 关闭——注销监听但不关闭系统热点（由用户手动关闭）
   */
  stop(): void {
    this.stopPolling();
    this.unregisterHotspotStateListener();

    if (this._state === HotspotState.ACTIVE) {
      this._config = null;
    }
    this.changeState(HotspotState.DISABLED, '服务已停止');
    this.emit('info', '请在系统控制中心关闭热点');
  }

  /**
   * 手动确认热点就绪（用户在控制中心开启了）
   */
  async confirmHotspotActive(): Promise<boolean> {
    if (!this.isHotspotActive()) {
      this.changeState(HotspotState.ERROR, '未检测到热点，请在系统控制中心开启');
      return false;
    }

    const ip = await this.resolveGatewayIp();
    if (!ip) {
      this.changeState(HotspotState.ERROR, '无法获取热点网关 IP');
      return false;
    }

    this._config = { ssid: '', password: '', gatewayIp: ip, port: DEFAULT_PORT };
    this.changeState(HotspotState.ACTIVE, `热点已就绪 (${ip}:${DEFAULT_PORT})`);
    return true;
  }

  // ==================== 内部方法 ====================

  private registerHotspotStateListener(): void {
    this.unregisterHotspotStateListener();
    this.stateChangeHandler = (state: number): void => {
      hilog.info(0x0001, TAG, 'Hotspot state: %{public}d', state);
      if (state === 1) {
        // 热点已激活
        this.stopPolling();
        this.resolveGatewayIp().then((ip) => {
          if (ip) {
            this._config = { ssid: '', password: '', gatewayIp: ip, port: DEFAULT_PORT };
            this.changeState(HotspotState.ACTIVE, `热点已检测`);
          }
        });
      } else if (state === 0 && this._state === HotspotState.ACTIVE) {
        this._config = null;
        this.changeState(HotspotState.DISABLED, '热点已关闭');
      }
    };
    wifiManager.on('hotspotStateChange', this.stateChangeHandler);
  }

  private unregisterHotspotStateListener(): void {
    if (this.stateChangeHandler !== null) {
      try {
        wifiManager.off('hotspotStateChange', this.stateChangeHandler);
      } catch (_e) { /* ignore */ }
      this.stateChangeHandler = null;
    }
  }

  private startPolling(): void {
    this.stopPolling();
    this.pollingTimer = setInterval(() => {
      if (this.isHotspotActive() && this._state === HotspotState.STARTING) {
        this.resolveGatewayIp().then((ip) => {
          if (ip) {
            this.stopPolling();
            this._config = { ssid: '', password: '', gatewayIp: ip, port: DEFAULT_PORT };
            this.changeState(HotspotState.ACTIVE, `热点已就绪`);
          }
        });
      }
    }, 2000);
  }

  private stopPolling(): void {
    if (this.pollingTimer >= 0) {
      clearInterval(this.pollingTimer);
      this.pollingTimer = -1;
    }
  }

  private isHotspotActive(): boolean {
    try {
      return wifiManager.isHotspotActive();
    } catch (_e) {
      return false;
    }
  }

  /**
   * 获取网关 IP
   * 热点模式下本机 IP 通常是 192.168.43.1
   * 用户可在系统设置中查看确切 IP
   */
  private async resolveGatewayIp(): Promise<string | null> {
    // HarmonyOS 热点默认网关 IP 为 192.168.43.1
    // 用户可在设置→便携热点中查看
    return '192.168.43.1';
  }

  private delay(ms: number): Promise<void> {
    return new Promise<void>((r) => { setTimeout(r, ms); });
  }
}
