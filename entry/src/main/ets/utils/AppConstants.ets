export class AppConstants {
  static readonly APP_NAME = 'ToShare';
  static readonly VERSION = '1.0.0';

  static readonly WIFI_DIRECT_PORT = 8888;
  static readonly BLE_SERVICE_UUID = '0000TOSH-0000-1000-8000-00805F9B34FB';
  static readonly UDP_BROADCAST_PORT = 8765;
  static readonly TCP_PORT = 8766;

  static readonly CHUNK_SIZE = 65536;
  static readonly MAX_BLE_FILE_SIZE = 10 * 1024 * 1024;
  static readonly MAX_NFC_PAYLOAD = 4096;

  static readonly AUTO_RESUME_TIMEOUT_MS = 30000;

  static readonly HISTORY_STORAGE_KEY = 'toshare_transfer_history';
  static readonly SETTINGS_STORAGE_KEY = 'toshare_settings';
}
