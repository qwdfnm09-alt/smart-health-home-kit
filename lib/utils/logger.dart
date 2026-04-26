import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static void logInfo(String message) {
    if (kDebugMode) {
      print("ℹ️ INFO: $message");
    }
  }

  static void logError(String message, [dynamic error, StackTrace? stack]) {
    if (kDebugMode) {
      print("❌ ERROR: $message");
      if (error != null) print("Error details: $error");
      if (stack != null) print("Stacktrace: $stack");
    }

    try {
      FirebaseCrashlytics.instance.log("ERROR_MSG: $message");
      if (error != null) {
        FirebaseCrashlytics.instance.recordError(error, stack, reason: message);
      } else {
        FirebaseCrashlytics.instance.recordError(message, null, reason: "Manual Error Log");
      }
    } catch (_) {
      // Ignore logging failures when Firebase is unavailable.
    }
  }

  static void logWarning(String message) {
    if (kDebugMode) {
      print("⚠️ WARNING: $message");
    }
  }
}
