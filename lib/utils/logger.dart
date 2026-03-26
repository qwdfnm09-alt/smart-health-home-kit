import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

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

  static void log(String message) {
    // ✅ استخدم developer.log بدلاً من print (مسموح في release)
    developer.log('[SmartHealthKit] $message');
  }

  static void debug(String message) {
    if (kDebugMode) {
      print('[DEBUG] $message');
    }
  }
}

