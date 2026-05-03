import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'storage_service.dart';
import '../main.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();
  static Future<void>? _initializationFuture;

  static const String _channelId = 'daily_reminder_channel';
  static const String _channelName = 'Daily Reminder';
  static const String _channelDescription =
      'Reminds you to measure your health readings daily.';

  static Future<void> init() async {
    _initializationFuture ??= _initialize();
    await _initializationFuture;
  }

  static Future<void> _initialize() async {
    const androidSettings = AndroidInitializationSettings('notification_icon'); // ✅ أيقونة مخصصة
    const initializationSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) async {
        navigatorKey.currentState?.pushNamedAndRemoveUntil('/welcome', (r) => false);
      },
    );

    tz.initializeTimeZones();

    // تأكد من صلاحيات الإشعارات
    final androidPlugin =
    _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

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

    // طلب إذن الإشعارات في iOS
    final iosPlugin =
    _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> showReminderNotification() async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: 'notification_icon', // ✅
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'تذكير صحي 🩺',
      'لم تسجل أي قراءات اليوم، يُفضل قياس ضغطك وسكرك الآن.',
      details,
    );
  }

  static Future<bool> _didMeasureToday() async {
    final allData = StorageService().getAllHealthData();
    final today = DateTime.now();
    return allData.any((data) =>
    data.timestamp.year == today.year &&
        data.timestamp.month == today.month &&
        data.timestamp.day == today.day);
  }

  static Future<void> scheduleDailyReminder() async {
    await init();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
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

    await _notifications.zonedSchedule(
      1,
      'تذكير صحي 🩺',
      'لم تسجل أي قراءات اليوم، يُفضل قياس ضغطك وسكرك الآن.',
      scheduled,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelReminderNotifications() async {
    await init();
    await _notifications.cancel(0);
    await _notifications.cancel(1);
  }

  static Future<void> syncNotifications({required bool enabled}) async {
    if (!enabled) {
      await cancelReminderNotifications();
      return;
    }

    await scheduleDailyReminder();
  }

  static Future<void> checkAndNotifyNow() async {
    await init();

    final didMeasure = await _didMeasureToday();
    if (!didMeasure) {
      await showReminderNotification();
    }
  }
}
