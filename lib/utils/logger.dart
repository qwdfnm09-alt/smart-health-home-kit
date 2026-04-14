import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static void logInfo(String message) {
    // 1. الطباعة في الـ Console أثناء التطوير فقط
    if (kDebugMode) {
      print("ℹ️ INFO: $message");
    }

    // 2. تسجيل الرسالة في Crashlytics (فقط إذا لم نكن في وضع الاختبار)
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        FirebaseCrashlytics.instance.log("INFO: $message");
      } catch (e) {
        // نادراً ما يحدث لو Firebase مش جاهز
      }
    }
  }

  static void logError(String message, [dynamic error, StackTrace? stack]) {
    // 1. الطباعة في الـ Console أثناء التطوير فقط
    if (kDebugMode) {
      print("❌ ERROR: $message");
      if (error != null) print("Error details: $error");
      if (stack != null) print("Stacktrace: $stack");
    }

    // 2. إرسال الخطأ إلى Firebase (فقط إذا لم نكن في وضع الاختبار)
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        FirebaseCrashlytics.instance.log("ERROR_MSG: $message");
        if (error != null) {
          FirebaseCrashlytics.instance.recordError(error, stack, reason: message);
        } else {
          FirebaseCrashlytics.instance.recordError(message, null, reason: "Manual Error Log");
        }
      } catch (e) {
        // نادراً ما يحدث لو Firebase مش جاهز
      }
    }
  }

  static void logWarning(String message) {
    if (kDebugMode) {
      print("⚠️ WARNING: $message");
    }
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        FirebaseCrashlytics.instance.log("WARNING: $message");
      } catch (e) {
        // نادراً ما يحدث لو Firebase مش جاهز
      }
    }
  }
}
