import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

class PermissionsHelper {
  static Future<int?> _androidSdkInt() async {
    if (!Platform.isAndroid) return null;

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }

  static Future<bool> isLocationRequiredForBle() async {
    final sdk = await _androidSdkInt();
    if (sdk == null) return false;
    return sdk < 31;
  }

  /// هل كل الصلاحيات الأساسية موجودة؟
  static Future<bool> hasAllPermissions() async {
    if (!Platform.isAndroid) return true;

    final sdk = await _androidSdkInt();
    if (sdk == null) return true;

    if (sdk >= 31) {
      final scan = await Permission.bluetoothScan.isGranted;
      final connect = await Permission.bluetoothConnect.isGranted;
      return scan && connect;
    } else {
      return await Permission.locationWhenInUse.isGranted;
    }
  }

  /// طلب الصلاحيات الأساسية فقط
  static Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return true;

    final sdk = await _androidSdkInt();
    if (sdk == null) return true;

    List<Permission> permissions = [];

    if (sdk >= 31) {
      permissions.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ]);
    } else {
      permissions.add(Permission.locationWhenInUse);
    }

    bool allGranted = true;

    for (final permission in permissions) {
      final result = await permission.request();
      if (!result.isGranted) {
        AppLogger.logInfo("❌ Permission denied: $permission");
        allGranted = false;
      }
    }

    return allGranted;
  }

  /// Notification permission (اختياري)
  static Future<void> requestNotificationPermission() async {
    if (!Platform.isAndroid) return;

    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
  }

  /// Battery Optimization
  static Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  static Future<void> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return;

    if (!await Permission.ignoreBatteryOptimizations.isGranted) {
      await openAppSettings();
    }
  }

  /// فتح إعدادات التطبيق
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
