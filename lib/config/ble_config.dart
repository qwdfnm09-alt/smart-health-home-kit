// lib/config/ble_config.dart
class BleConfig {
  // اسم الجهاز (لو هتفلتر بالسيرش)
  static const String targetName = 'YOUR_DEVICE_NAME';

  // UUIDs
  static const String serviceUuid     = 'YOUR_SERVICE_UUID';
  static const String notifyCharUuid  = 'YOUR_NOTIFY_CHAR_UUID';
  static const String? writeCharUuid  = null; // او حط UUID لو عندك كتابة
}
