import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/bill.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
      },
    );

    // Create default channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'bill_channel',
        'Tagihan',
        description: 'Pemberitahuan untuk tagihan mendatang',
        importance: Importance.max,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      // Request POST_NOTIFICATIONS (Android 13+)
      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      
      // Also request exact alarm permission if needed (Android 12+)
      // Note: requestExactAlarmsPermission() is available in newer versions of the plugin
      bool exactGranted = true;
      try {
        exactGranted = await androidImplementation?.requestExactAlarmsPermission() ?? true;
      } catch (e) {
        // Fallback for older plugin versions
      }

      return (granted ?? false) && exactGranted;
    }
    return false;
  }

  Future<void> scheduleBillReminders(Bill bill) async {
    if (bill.id == null) return;

    final dueDate = bill.dueDate;
    final now = DateTime.now();

    // 1. Reminder on the Day Of (09:00 AM)
    final scheduledDateDayOf = tz.TZDateTime.from(
      DateTime(dueDate.year, dueDate.month, dueDate.day, 9, 0),
      tz.local,
    );

    if (scheduledDateDayOf.isAfter(now)) {
      await _notificationsPlugin.zonedSchedule(
        bill.id! * 2, // Unique ID for Day Of
        'fina: Jatuh Tempo Hari Ini',
        'Tagihan "${bill.title}" jatuh tempo hari ini sebesar ${NumberFormat.currency(symbol: 'Rp', decimalDigits: 0).format(bill.amount)}',
        scheduledDateDayOf,
        const NotificationDetails(
          android: AndroidNotificationDetails('bill_channel', 'Tagihan', importance: Importance.max),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // 2. Reminder H-1 (09:00 AM)
    final oneDayBefore = dueDate.subtract(const Duration(days: 1));
    final scheduledDateH1 = tz.TZDateTime.from(
      DateTime(oneDayBefore.year, oneDayBefore.month, oneDayBefore.day, 9, 0),
      tz.local,
    );

    if (scheduledDateH1.isAfter(now)) {
      await _notificationsPlugin.zonedSchedule(
        bill.id! * 2 + 1, // Unique ID for H-1
        'fina: Tagihan Besok',
        'Besok tagihan "${bill.title}" akan jatuh tempo. Siapkan dana Anda!',
        scheduledDateH1,
        const NotificationDetails(
          android: AndroidNotificationDetails('bill_channel', 'Tagihan', importance: Importance.max),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelBillReminders(int billId) async {
    await _notificationsPlugin.cancel(billId * 2);
    await _notificationsPlugin.cancel(billId * 2 + 1);
  }

  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Used for testing notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      0,
      'fina',
      'Notifikasi berhasil diaktifkan!',
      notificationDetails,
    );
  }

  Future<bool> isNotificationsEnabled() async {
    if (Platform.isIOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: false,
            badge: false,
            sound: false,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? granted = await androidImplementation?.areNotificationsEnabled();
      return granted ?? false;
    }
    return false;
  }
}
