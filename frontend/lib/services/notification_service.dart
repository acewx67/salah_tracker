import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Service for scheduling daily prayer reminder notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'prayer_reminders';
  static const _channelName = 'Prayer Reminders';
  static const _channelDescription = 'Daily reminders to log your prayers';

  // Notification IDs
  static const _eveningReminderId = 1;
  static const _morningReminderId = 2;

  /// Initialize the notification plugin and timezone data.
  Future<void> init() async {
    // Initialize timezone database
    tz.initializeTimeZones();
    final tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Create notification channel (Android 8+)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Request notification permission (required on Android 13+).
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Schedule both daily reminders (9 PM evening + 5 AM morning).
  Future<void> scheduleAll() async {
    await cancelAll();

    // 9 PM — "Log your prayers" reminder
    await _scheduleDailyNotification(
      id: _eveningReminderId,
      hour: 21,
      minute: 0,
      title: '🕌 Log Your Prayers',
      body: "Don't forget to log today's prayers before the day ends!",
    );

    // 5 AM — "Did you miss any prayers?" alert
    await _scheduleDailyNotification(
      id: _morningReminderId,
      hour: 5,
      minute: 0,
      title: '🌅 Prayer Check',
      body: 'Did you log all your prayers yesterday? Open the app to check.',
    );
  }

  /// Cancel all scheduled notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Schedule a single daily repeating notification at the given [hour]:[minute].
  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final scheduledTime = _nextInstanceOfTime(hour, minute);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Returns the next occurrence of [hour]:[minute] in local timezone.
  /// If that time has already passed today, returns tomorrow's instance.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
