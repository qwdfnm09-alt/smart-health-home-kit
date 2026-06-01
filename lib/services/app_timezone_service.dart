import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../utils/logger.dart';

class AppTimezoneService {
  static const MethodChannel _channel = MethodChannel('smart_health/timezone');
  static Future<void>? _configurationFuture;

  static Future<void> configureLocalTimezone() async {
    _configurationFuture ??= _configure();
    await _configurationFuture;
  }

  static Future<void> _configure() async {
    try {
      tz.initializeTimeZones();

      final timezoneName =
          await _channel.invokeMethod<String>('getLocalTimezone');
      if (timezoneName == null || timezoneName.trim().isEmpty) {
        AppLogger.logInfo('⚠️ Local timezone name unavailable, keeping default');
        return;
      }

      final location = tz.getLocation(timezoneName);
      tz.setLocalLocation(location);
      AppLogger.logInfo('🕒 Local timezone configured: $timezoneName');
    } catch (e, st) {
      AppLogger.logError('❌ Failed to configure local timezone', e, st);
    }
  }
}
