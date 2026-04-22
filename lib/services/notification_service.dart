import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:flutter/foundation.dart';
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
        AndroidInitializationSettings('@mipmap/launcher_icon');

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

    // Create default channels for Android
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      // 1. Bill Reminder Channel
      const AndroidNotificationChannel billChannel = AndroidNotificationChannel(
        'bill_channel',
        'Tagihan',
        description: 'Pemberitahuan untuk tagihan mendatang',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      // 2. Test Notification Channel
      const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
        'test_channel_v2', // Changed ID to force refresh
        'Tes Notifikasi',
        description: 'Digunakan untuk mencoba fitur notifikasi',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      // 3. Smart Alerts Channel
      const AndroidNotificationChannel smartChannel = AndroidNotificationChannel(
        'smart_alerts_channel',
        'Alert Pintar',
        description: 'Pemberitahuan pengeluaran tidak wajar',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await androidPlugin?.createNotificationChannel(billChannel);
      await androidPlugin?.createNotificationChannel(testChannel);
      await androidPlugin?.createNotificationChannel(smartChannel);
      debugPrint('Notification Channels Created Successfully');
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
    try {
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
    } catch (e) {
      // Log error but don't block the UI flow
      debugPrint('Error scheduling reminders: $e');
    }
  }

  Future<void> cancelBillReminders(int billId) async {
    await _notificationsPlugin.cancel(billId * 2);
    await _notificationsPlugin.cancel(billId * 2 + 1);
  }

  Future<void> showSmartAlert({required String title, required String body}) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'smart_alerts_channel',
        'Alert Pintar',
        channelDescription: 'Pemberitahuan pengeluaran tidak wajar',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.show(
        888, // Static ID for smart alerts or use timestamp for multiple
        title,
        body,
        notificationDetails,
      );
    } catch (e) {
      debugPrint('Error showing smart alert: $e');
    }
  }

  Future<void> showTestNotification() async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_channel_v2',
        'Tes Notifikasi',
        channelDescription: 'Digunakan untuk mencoba fitur notifikasi',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        fullScreenIntent: true,
        category: AndroidNotificationCategory.status,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.show(
        999, // Static ID for test
        'fina',
        'Notifikasi berhasil diaktifkan! 🚀',
        notificationDetails,
      );
      debugPrint('Test Notification Sent Successfully');
    } catch (e) {
      debugPrint('Error showing test notification: $e');
    }
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
