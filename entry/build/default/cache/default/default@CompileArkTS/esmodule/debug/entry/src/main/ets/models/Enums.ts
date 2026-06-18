export enum DeviceType {
    MOBILE = "mobile",
    TABLET = "tablet",
    DESKTOP = "desktop"
}
export enum DeviceStatus {
    ONLINE = "online",
    AWAY = "away",
    OFFLINE = "offline"
}
export enum TransportProtocol {
    WIFI_DIRECT = "wifiDirect",
    BLUETOOTH = "bluetooth",
    NFC = "nfc"
}
export enum TransferStatus {
    IDLE = "idle",
    PREPARING = "preparing",
    CONNECTING = "connecting",
    TRANSFERRING = "transferring",
    PAUSED = "paused",
    COMPLETED = "completed",
    FAILED = "failed",
    CANCELLED = "cancelled"
}
export enum DeviceDiscoveryStatus {
    IDLE = "idle",
    SCANNING = "scanning",
    BROADCASTING = "broadcasting",
    ERROR = "error"
}
export enum ThemeModeType {
    SYSTEM = "system",
    LIGHT = "light",
    DARK = "dark"
}
export enum HistoryRetentionDays {
    DAYS_7 = 7,
    DAYS_30 = 30,
    DAYS_90 = 90,
    PERMANENT = -1
}
