import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Offset besar supaya ID reminder tagihan (berbasis bill.id yang terus bertambah/AUTOINCREMENT)
  // tidak pernah bertabrakan dengan ID statis showSmartAlert (888) / showTestNotification (999).
  static const int _billReminderIdOffset = 100000;
  int _dayOfReminderId(int billId) => _billReminderIdOffset + billId * 2;
  int _h1ReminderId(int billId) => _billReminderIdOffset + billId * 2 + 1;

  Future<void> init() async {
    if (kIsWeb) return; // Notifikasi lokal belum didukung di web melalui plugin ini

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
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
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
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      // Request POST_NOTIFICATIONS (Android 13+)
      final bool? granted = await androidImplementation?.requestNotificationsPermission();
      
      // Also request exact alarm permission if needed (Android 12+)
      bool exactGranted = true;
      try {
        exactGranted = await androidImplementation?.requestExactAlarmsPermission() ?? true;
      } catch (e) {
        // Fallback
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
        await _zonedScheduleWithFallback(
          _dayOfReminderId(bill.id!),
          'fina: Jatuh Tempo Hari Ini',
          'Tagihan "${bill.title}" jatuh tempo hari ini sebesar ${NumberFormat.currency(symbol: 'Rp', decimalDigits: 0).format(bill.amount)}',
          scheduledDateDayOf,
        );
      }

      // 2. Reminder H-1 (09:00 AM)
      final oneDayBefore = dueDate.subtract(const Duration(days: 1));
      final scheduledDateH1 = tz.TZDateTime.from(
        DateTime(oneDayBefore.year, oneDayBefore.month, oneDayBefore.day, 9, 0),
        tz.local,
      );

      if (scheduledDateH1.isAfter(now)) {
        await _zonedScheduleWithFallback(
          _h1ReminderId(bill.id!),
          'fina: Tagihan Besok',
          'Besok tagihan "${bill.title}" akan jatuh tempo. Siapkan dana Anda!',
          scheduledDateH1,
        );
      }
    } catch (e) {
      // Log error but don't block the UI flow
      debugPrint('Error scheduling reminders: $e');
    }
  }

  /// Coba jadwalkan dengan mode exact (tepat waktu). Jika ditolak OS (izin exact-alarm
  /// dicabut/tak diberikan di Android 12+), fallback ke mode inexact daripada diam-diam
  /// gagal total tanpa reminder sama sekali.
  Future<void> _zonedScheduleWithFallback(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledDate,
  ) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails('bill_channel', 'Tagihan', importance: Importance.max),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Exact alarm scheduling failed ($e), falling back to inexact schedule.');
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e2) {
        debugPrint('Inexact fallback scheduling also failed: $e2');
      }
    }
  }

  Future<void> cancelBillReminders(int billId) async {
    await _notificationsPlugin.cancel(_dayOfReminderId(billId));
    await _notificationsPlugin.cancel(_h1ReminderId(billId));
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
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final bool? result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: false,
            badge: false,
            sound: false,
          );
      return result ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? granted = await androidImplementation?.areNotificationsEnabled();
      return granted ?? false;
    }
    return false;
  }
}
