/**
 * 沉浸光效色彩系统
 * 基于 HarmonyOS Design 规范，提供毛玻璃材质、渐变光效、新拟态阴影等沉浸视觉配色
 */
export class AppColors {
    // 主色调 — 品牌色
    static readonly PRIMARY = '#6C5CE7';
    static readonly PRIMARY_LIGHT = '#A29BFE';
    static readonly PRIMARY_DARK = '#4834D4';
    static readonly SECONDARY = '#00C9A7';
    static readonly SECONDARY_LIGHT = '#55EFC4';
    static readonly SECONDARY_DARK = '#00A383';
    static readonly TERTIARY = '#FF9F43';
    static readonly TERTIARY_LIGHT = '#FFBE76';
    static readonly TERTIARY_DARK = '#EE5A24';
    // 渐变预设值
    static readonly GRADIENT_PRIMARY_START = '#6C5CE7';
    static readonly GRADIENT_PRIMARY_END = '#A29BFE';
    static readonly GRADIENT_ACCENT_START = '#00C9A7';
    static readonly GRADIENT_ACCENT_END = '#55EFC4';
    static readonly GRADIENT_WARM_START = '#FF9F43';
    static readonly GRADIENT_WARM_END = '#FFBE76';
    static readonly GRADIENT_HEADER_START = '#4834D4';
    static readonly GRADIENT_HEADER_MID = '#6C5CE7';
    static readonly GRADIENT_HEADER_END = '#A29BFE';
    // 毛玻璃材质色调
    static readonly FROST_LIGHT = '#BFFFFFFF';
    static readonly FROST_MEDIUM = '#D9FFFFFF';
    static readonly FROST_DARK = '#2B2930EE';
    static readonly FROST_CARD_LIGHT = '#CCFFFFFF';
    static readonly FROST_CARD_DARK = '#302E38CC';
    // 背景色
    static readonly SURFACE_LIGHT = '#FFFFFF';
    static readonly SURFACE_DARK = '#1C1B1F';
    static readonly BACKGROUND_LIGHT = '#F0EFF5';
    static readonly BACKGROUND_DARK = '#0F0F12';
    // 文字色
    static readonly TEXT_PRIMARY_LIGHT = '#1C1B1F';
    static readonly TEXT_PRIMARY_DARK = '#E6E1E5';
    static readonly TEXT_SECONDARY_LIGHT = '#625B71';
    static readonly TEXT_SECONDARY_DARK = '#CAC4D0';
    static readonly TEXT_TERTIARY_LIGHT = '#9E97AA';
    static readonly TEXT_TERTIARY_DARK = '#938F99';
    // 功能色
    static readonly SUCCESS = '#00C9A7';
    static readonly WARNING = '#FF9F43';
    static readonly ERROR = '#FF6B6B';
    static readonly INFO = '#6C5CE7';
    // 分割线
    static readonly DIVIDER_LIGHT = '#E8DEF8';
    static readonly DIVIDER_DARK = '#383838';
    // 设备状态色
    static readonly STATUS_ONLINE = '#00C9A7';
    static readonly STATUS_AWAY = '#FF9F43';
    static readonly STATUS_OFFLINE = '#9E9E9E';
    // 协议色
    static readonly WIFI_COLOR = '#6C5CE7';
    static readonly BLE_COLOR = '#00C9A7';
    static readonly NFC_COLOR = '#FF6B6B';
    // 卡片色
    static readonly CARD_BG_LIGHT = '#FFFFFF';
    static readonly CARD_BG_DARK = '#25232A';
}
