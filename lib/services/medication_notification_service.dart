import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/medication.dart';
import '../models/medication_intake.dart';
import 'app_timezone_service.dart';

class MedicationNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static Future<void>? _initializationFuture;

  static const String _channelId = 'medication_reminders_channel';
  static const String _channelName = 'Medication Reminders';
  static const String _channelDescription =
      'Reminds users to take medications and buy refills when stock is low.';

  static Future<void> init() async {
    _initializationFuture ??= _initialize();
    await _initializationFuture;
  }

  static Future<void> _initialize() async {
    const androidSettings = AndroidInitializationSettings('notification_icon');
    const initializationSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initializationSettings);
    await AppTimezoneService.configureLocalTimezone();

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    try {
      await androidPlugin?.requestNotificationsPermission();
    } catch (_) {}

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
      ),
    );
  }

  static Future<void> syncMedicationNotifications({
    required Medication medication,
    required List<MedicationIntake> intakes,
    required bool isLowStock,
    required bool isOutOfStock,
  }) async {
    await init();
    await cancelMedicationReminders(medication.id, intakes);

    if (!medication.isActive) {
      return;
    }

    for (final intake in intakes) {
      if (intake.status != 'pending') continue;
      if (!intake.scheduledAt.isAfter(DateTime.now())) continue;
      await _scheduleDoseReminder(medication, intake);
    }

    if (isOutOfStock || isLowStock) {
      await _showStockNotification(
        medication: medication,
        isOutOfStock: isOutOfStock,
      );
    } else {
      await _clearStockNotificationFlag(medication.id);
      await _notifications.cancel(_stockNotificationId(medication.id));
    }
  }

  static Future<void> cancelMedicationReminders(
    String medicationId,
    List<MedicationIntake> intakes,
  ) async {
    await init();
    for (final intake in intakes) {
      await _notifications.cancel(_doseNotificationId(intake.id));
    }
  }

  static Future<void> cancelMedicationNotifications(
    String medicationId,
    List<MedicationIntake> intakes,
  ) async {
    await cancelMedicationReminders(medicationId, intakes);
    await _notifications.cancel(_stockNotificationId(medicationId));
    await _clearStockNotificationFlag(medicationId);
  }

  static Future<void> _scheduleDoseReminder(
    Medication medication,
    MedicationIntake intake,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: 'notification_icon',
    );

    await _notifications.zonedSchedule(
      _doseNotificationId(intake.id),
      'تذكير دواء',
      'حان الآن موعد جرعة ${medication.name}',
      tz.TZDateTime.from(intake.scheduledAt, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> _showStockNotification({
    required Medication medication,
    required bool isOutOfStock,
  }) async {
    final todayKey = _stockNotificationFlagKey(medication.id, DateTime.now());
    final settingsBox = Hive.box('app_settings');
    final alreadyNotified = settingsBox.get(todayKey, defaultValue: false) == true;
    if (alreadyNotified) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: 'notification_icon',
    );

    await _notifications.show(
      _stockNotificationId(medication.id),
      isOutOfStock ? 'الدواء خلص' : 'المخزون منخفض',
      isOutOfStock
          ? 'دواء ${medication.name} خلص. اشترِ عبوة جديدة.'
          : 'دواء ${medication.name} المتبقي منه قليل. يفضل شراء عبوة جديدة.',
      const NotificationDetails(android: androidDetails),
    );

    await settingsBox.put(todayKey, true);
  }

  static Future<void> _clearStockNotificationFlag(String medicationId) async {
    final settingsBox = Hive.box('app_settings');
    final prefix = 'medication_stock_notified_${medicationId}_';
    final keysToDelete = settingsBox.keys
        .where((key) => key is String && key.startsWith(prefix))
        .cast<String>()
        .toList();

    for (final key in keysToDelete) {
      await settingsBox.delete(key);
    }
  }

  static String _stockNotificationFlagKey(String medicationId, DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'medication_stock_notified_${medicationId}_$year$month$day';
  }

  static int _doseNotificationId(String intakeId) {
    return _stableId('dose_$intakeId');
  }

  static int _stockNotificationId(String medicationId) {
    return _stableId('stock_$medicationId');
  }

  static int _stableId(String input) {
    var hash = 0;
    for (final codeUnit in input.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}
