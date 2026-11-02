import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/shift_model.dart';
import '../../data/models/attendance_event_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  static const String _prefKeyEnabled = 'attendance_notifications_enabled';

  // Notification IDs
  static const int idShiftStart30Min = 101;
  static const int idShiftStart15Min = 102;
  static const int idBreakEnd = 103;
  static const int idShiftEnd = 104;

  // Channel details
  static const String channelId = 'attendance_reminders';
  static const String channelName = 'Pengingat Presensi';
  static const String channelDesc =
      'Notifikasi pengingat jadwal masuk kerja, istirahat, dan pulang.';

  static const String submissionChannelId = 'attendance_submissions_success_v1';
  static const String submissionChannelName = 'Konfirmasi Presensi';
  static const String submissionChannelDesc =
      'Notifikasi konfirmasi saat presensi berhasil dicatat.';

  static const String failureChannelId = 'attendance_submissions_failure_v1';
  static const String failureChannelName = 'Presensi Belum Tercatat';
  static const String failureChannelDesc =
      'Notifikasi peringatan saat presensi gagal dikirim atau tidak tercatat.';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize timezone database
      tz.initializeTimeZones();
      final String timeZoneName = DateTime.now().timeZoneName;
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (_) {
        // Fallback default to Asia/Jakarta (WIB)
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
        } catch (_) {
          tz.setLocalLocation(tz.local);
        }
      }

      // 2. Platform initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // 3. Configure Android notification channels with custom sounds
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        try {
          await androidPlugin.deleteNotificationChannel(
            channelId: 'attendance_submissions',
          );
        } catch (_) {}

        const submissionChannel = AndroidNotificationChannel(
          submissionChannelId,
          submissionChannelName,
          description: submissionChannelDesc,
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('successful'),
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(submissionChannel);

        const failureChannel = AndroidNotificationChannel(
          failureChannelId,
          failureChannelName,
          description: failureChannelDesc,
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('unsuccessful'),
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(failureChannel);
      }

      _isInitialized = true;
      debugPrint('[NotificationService] Initialized successfully.');
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
    }
  }

  /// Request permissions for Android 13+ (API 33+) & iOS
  Future<bool> requestPermissions() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final androidGranted =
          await androidPlugin?.requestNotificationsPermission();

      final iosPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final iosGranted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return (androidGranted ?? iosGranted) ?? true;
    } catch (e) {
      debugPrint('[NotificationService] Request permission error: $e');
      return false;
    }
  }

  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_prefKeyEnabled) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyEnabled, enabled);
      if (!enabled) {
        await cancelAllReminders();
      }
    } catch (_) {}
  }

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFE11D48),
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  /// Schedule reminders based on shift schedules and existing events
  Future<void> scheduleAttendanceReminders({
    required Shift? shift,
    List<AttendanceEvent> events = const [],
  }) async {
    if (shift == null) return;
    if (!await isEnabled()) return;
    if (!_isInitialized) await initialize();

    final hasStartedShift = events.any(
      (e) => e.eventType == AttendanceEventType.startShift,
    );
    final hasEndedBreak = events.any(
      (e) => e.eventType == AttendanceEventType.endBreak,
    );
    final hasEndedShift = events.any(
      (e) => e.eventType == AttendanceEventType.endShift,
    );

    final now = tz.TZDateTime.now(tz.local);

    // 1. Schedule Shift Start Reminders (15 & 30 min before shift start)
    if (!hasStartedShift) {
      final shiftStartTime = _parseTimeToToday(shift.startTime, now);
      if (shiftStartTime != null) {
        // 30 min before
        final time30Min = shiftStartTime.subtract(const Duration(minutes: 30));
        if (time30Min.isAfter(now)) {
          await _scheduleZonedNotification(
            id: idShiftStart30Min,
            title: '⏰ Pengingat Presensi Masuk (30 Menit)',
            body:
                '30 menit lagi shift ${shift.name} dimulai pukul ${shift.startTime}. Siapkan diri untuk presensi!',
            scheduledDate: time30Min,
          );
        }

        // 15 min before (acceptance criteria: "15 menit lagi shift Anda dimulai, jangan lupa lakukan presensi tepat waktu!")
        final time15Min = shiftStartTime.subtract(const Duration(minutes: 15));
        if (time15Min.isAfter(now)) {
          await _scheduleZonedNotification(
            id: idShiftStart15Min,
            title: '⏰ Pengingat Presensi Masuk (15 Menit)',
            body:
                '15 menit lagi shift Anda dimulai, jangan lupa lakukan presensi tepat waktu!',
            scheduledDate: time15Min,
          );
        }
      }
    } else {
      // User has checked in, cancel start reminders
      await cancelReminder(idShiftStart30Min);
      await cancelReminder(idShiftStart15Min);
    }

    // 2. Schedule Break End Reminder
    final breakEndTimeStr = shift.effectiveBreakEnd;
    if (!hasEndedBreak && breakEndTimeStr.isNotEmpty) {
      final breakEndTime = _parseTimeToToday(breakEndTimeStr, now);
      if (breakEndTime != null) {
        // 5 minutes before break ends or exactly when break ends
        final reminderTime = breakEndTime.subtract(const Duration(minutes: 5));
        final targetTime = reminderTime.isAfter(now)
            ? reminderTime
            : (breakEndTime.isAfter(now) ? breakEndTime : null);

        if (targetTime != null) {
          await _scheduleZonedNotification(
            id: idBreakEnd,
            title: '☕ Waktu Istirahat Akan Berakhir',
            body:
                'Jam istirahat akan segera berakhir pukul $breakEndTimeStr. Silakan kembali bekerja!',
            scheduledDate: targetTime,
          );
        }
      }
    } else {
      await cancelReminder(idBreakEnd);
    }

    // 3. Schedule Shift End (Jam Pulang) Reminder
    if (!hasEndedShift && shift.endTime.isNotEmpty) {
      final shiftEndTime = _parseTimeToToday(shift.endTime, now);
      if (shiftEndTime != null && shiftEndTime.isAfter(now)) {
        await _scheduleZonedNotification(
          id: idShiftEnd,
          title: '🏠 Waktu Pulang Kerja',
          body:
              'Shift Anda telah berakhir pukul ${shift.endTime}. Jangan lupa lakukan presensi pulang!',
          scheduledDate: shiftEndTime,
        );
      }
    } else {
      await cancelReminder(idShiftEnd);
    }
  }

  tz.TZDateTime? _parseTimeToToday(String timeStr, tz.TZDateTime now) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length < 2) return null;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _scheduleZonedNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint(
        '[NotificationService] Scheduled notification #$id at $scheduledDate',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] Error scheduling notification #$id: $e',
      );
    }
  }

  Future<void> cancelReminder(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {}
  }

  Future<void> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }

  NotificationDetails _submissionNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      submissionChannelId,
      submissionChannelName,
      channelDescription: submissionChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF10B981), // Emerald green for success
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('successful'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'Successful.mp3',
    );

    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  NotificationDetails _failureNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      failureChannelId,
      failureChannelName,
      channelDescription: failureChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFEF4444), // Crimson red for failure
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('unsuccessful'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'Unsuccessful.mp3',
    );

    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  /// Show instant test notification
  Future<void> showTestNotification({
    String title = '⏰ Tes Pengingat Presensi',
    String body = 'Notifikasi pengingat presensi Kirana People aktif!',
  }) async {
    if (!_isInitialized) await initialize();
    await _notificationsPlugin.show(
      id: 999,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
    );
  }

  /// Show instant notification confirming an attendance event was submitted successfully
  Future<void> showAttendanceSubmittedNotification({
    required AttendanceEventType eventType,
    DateTime? timestamp,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      if (!await isEnabled()) return;

      final rawTime = timestamp ?? DateTime.now();
      // Ensure time is formatted strictly in Western Indonesian Time (WIB / UTC+7)
      final time = rawTime.toUtc().add(const Duration(hours: 7));
      final hourStr = time.hour.toString().padLeft(2, '0');
      final minuteStr = time.minute.toString().padLeft(2, '0');
      final timeStr = '$hourStr:$minuteStr';

      final eventLabel = eventType.label;
      final title = '✅ Presensi $eventLabel Berhasil';
      final body =
          'Presensi $eventLabel Anda telah berhasil dicatat pada pukul $timeStr WIB. Data telah tersinkronisasi.';

      final notifId = DateTime.now().millisecondsSinceEpoch % 100000 + 200;

      await _notificationsPlugin.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: _submissionNotificationDetails(),
      );
      debugPrint(
        '[NotificationService] Submitted attendance notification sent: $title',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] Error showing submitted notification: $e',
      );
    }
  }

  /// Show instant notification when an attendance event submission failed or is unrecorded
  Future<void> showAttendanceFailedNotification({
    required AttendanceEventType eventType,
    String? reason,
    DateTime? timestamp,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      if (!await isEnabled()) return;

      final rawTime = timestamp ?? DateTime.now();
      // Ensure time is formatted strictly in Western Indonesian Time (WIB / UTC+7)
      final time = rawTime.toUtc().add(const Duration(hours: 7));
      final hourStr = time.hour.toString().padLeft(2, '0');
      final minuteStr = time.minute.toString().padLeft(2, '0');
      final timeStr = '$hourStr:$minuteStr';

      final eventLabel = eventType.label;
      final title = '❌ Presensi $eventLabel Gagal';
      final cleanReason = reason != null && reason.trim().isNotEmpty
          ? ': ${reason.trim()}'
          : '';
      final body =
          'Presensi $eventLabel Anda pada pukul $timeStr WIB tidak berhasil tercatat$cleanReason. Silakan buka aplikasi dan coba kembali.';

      final notifId = DateTime.now().millisecondsSinceEpoch % 100000 + 400;

      await _notificationsPlugin.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: _failureNotificationDetails(),
      );
      debugPrint(
        '[NotificationService] Failed attendance notification sent: $title',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] Error showing failed notification: $e',
      );
    }
  }
}
