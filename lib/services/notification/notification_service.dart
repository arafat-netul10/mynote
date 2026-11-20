
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    final timeZone = await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(
      tz.getLocation(timeZone.identifier),
    );

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: settings,
    );

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android == null) return false;

    final granted =
    await android.requestNotificationsPermission();

    return granted ?? true;
  }

  Future<void> showTestNotification() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'mynote_reminders',
        'MyNote Reminders',
        channelDescription: 'Scheduled reminders for your notes',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _notifications.show(
      id: 100,
      title: 'MyNote',
      body: 'Notifications are working successfully!',
      notificationDetails: details,
    );
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_initialized) {
      throw StateError(
        'NotificationService is not initialized.',
      );
    }

    final scheduledTime =
    tz.TZDateTime.from(scheduledDate, tz.local);

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      throw ArgumentError(
        'Reminder time must be in the future.',
      );
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'mynote_reminders',
        'MyNote Reminders',
        channelDescription: 'Scheduled reminders for your notes',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: details,
      androidScheduleMode:
      AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id: id);
  }
}
