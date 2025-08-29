import 'package:flutter/foundation.dart';

class AppLogger {
  /// 🟢 طباعة رسالة معلومات
  static void logInfo(String message) {
    if (kDebugMode) {
      print('ℹ️ [INFO]: $message');
    }
  }

  /// 🔴 طباعة رسالة خطأ
  static void logError(String message) {
    if (kDebugMode) {
      print('❌ [ERROR]: $message');
    }
  }

  /// ⚠️ طباعة رسالة تحذير (اختياري)
  static void logWarning(String message) {
    if (kDebugMode) {
      print('⚠️ [WARNING]: $message');
    }
  }
}

