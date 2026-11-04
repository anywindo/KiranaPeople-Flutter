import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/shift_model.dart';
import '../../data/models/attendance_event_model.dart';
import 'notification_channels.dart';
import 'notification_payload_builder.dart';

export 'notification_channels.dart';
export 'notification_payload_builder.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  static const String _prefKeyEnabled = 'attendance_notifications_enabled';

  // Backward-compatible Notification IDs
  static const int idShiftStart30Min = NotificationChannels.idShiftStart30Min;
  static const int idShiftStart15Min = NotificationChannels.idShiftStart15Min;
  static const int idBreakEnd = NotificationChannels.idBreakEnd;
  static const int idShiftEnd = NotificationChannels.idShiftEnd;

  // Backward-compatible Channel details
  static const String channelId = NotificationChannels.reminderChannelId;
  static const String channelName = NotificationChannels.reminderChannelName;
  static const String channelDesc = NotificationChannels.reminderChannelDesc;

  static const String submissionChannelId =
      NotificationChannels.submissionChannelId;
  static const String submissionChannelName =
      NotificationChannels.submissionChannelName;
  static const String submissionChannelDesc =
      NotificationChannels.submissionChannelDesc;

  static const String failureChannelId = NotificationChannels.failureChannelId;
  static const String failureChannelName =
      NotificationChannels.failureChannelName;
  static const String failureChannelDesc =
      NotificationChannels.failureChannelDesc;

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
        await androidPlugin.createNotificationChannel(
          NotificationChannels.reminderChannel,
        );

        try {
          await androidPlugin.deleteNotificationChannel(
            channelId: 'attendance_submissions',
          );
        } catch (_) {}

        await androidPlugin.createNotificationChannel(
          NotificationChannels.submissionChannel,
        );

        await androidPlugin.createNotificationChannel(
          NotificationChannels.failureChannel,
        );
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

    // 1. Schedule Shift Start Reminders (30 min & 15 min before shift start)
    final startReminders = calculateNextShiftStartReminders(
      timeStr: shift.startTime,
      now: now,
      alreadyCheckedIn: hasStartedShift,
    );

    if (startReminders != null) {
      final (time30Min, time15Min) = startReminders;

      await _scheduleZonedNotification(
        id: idShiftStart30Min,
        title: '⏰ Pengingat Presensi Masuk (30 Menit)',
        body:
            '30 menit lagi shift ${shift.name} dimulai pukul ${shift.startTime}. Siapkan diri untuk presensi!',
        scheduledDate: time30Min,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      await _scheduleZonedNotification(
        id: idShiftStart15Min,
        title: '⏰ Pengingat Presensi Masuk (15 Menit)',
        body:
            '15 menit lagi shift Anda dimulai, jangan lupa lakukan presensi tepat waktu!',
        scheduledDate: time15Min,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    // 2. Schedule Break End Reminder (5 minutes before break ends)
    final breakEndTimeStr = shift.effectiveBreakEnd;
    if (breakEndTimeStr.isNotEmpty) {
      final targetBreakEnd = calculateNextTime(
        timeStr: breakEndTimeStr,
        now: now,
        subtractMinutes: 5,
        alreadyDoneToday: hasEndedBreak,
      );

      if (targetBreakEnd != null) {
        await _scheduleZonedNotification(
          id: idBreakEnd,
          title: '☕ Waktu Istirahat Akan Berakhir',
          body:
              'Jam istirahat akan segera berakhir pukul $breakEndTimeStr. Silakan kembali bekerja!',
          scheduledDate: targetBreakEnd,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } else {
      await cancelReminder(idBreakEnd);
    }

    // 3. Schedule Shift End (Jam Pulang) Reminder
    if (shift.endTime.isNotEmpty) {
      final targetShiftEnd = calculateNextTime(
        timeStr: shift.endTime,
        now: now,
        subtractMinutes: 0,
        alreadyDoneToday: hasEndedShift,
      );

      if (targetShiftEnd != null) {
        await _scheduleZonedNotification(
          id: idShiftEnd,
          title: '🏠 Waktu Pulang Kerja',
          body:
              'Shift Anda telah berakhir pukul ${shift.endTime}. Jangan lupa lakukan presensi pulang!',
          scheduledDate: targetShiftEnd,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } else {
      await cancelReminder(idShiftEnd);
    }
  }

  (tz.TZDateTime, tz.TZDateTime)? calculateNextShiftStartReminders({
    required String timeStr,
    required tz.TZDateTime now,
    bool alreadyCheckedIn = false,
  }) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length < 2) return null;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final shiftStartToday = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      var time30Min = shiftStartToday.subtract(const Duration(minutes: 30));
      var time15Min = shiftStartToday.subtract(const Duration(minutes: 15));

      if (alreadyCheckedIn) {
        if (time30Min.isBefore(now) || time30Min.day == now.day) {
          time30Min = time30Min.add(const Duration(days: 1));
        }
        if (time15Min.isBefore(now) || time15Min.day == now.day) {
          time15Min = time15Min.add(const Duration(days: 1));
        }
      } else {
        if (time30Min.isBefore(now)) {
          time30Min = time30Min.add(const Duration(days: 1));
        }
        if (time15Min.isBefore(now)) {
          time15Min = time15Min.add(const Duration(days: 1));
        }
      }

      return (time30Min, time15Min);
    } catch (_) {
      return null;
    }
  }

  tz.TZDateTime? calculateNextTime({
    required String timeStr,
    required tz.TZDateTime now,
    int subtractMinutes = 0,
    bool alreadyDoneToday = false,
  }) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length < 2) return null;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final baseTimeToday = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      var target = baseTimeToday.subtract(Duration(minutes: subtractMinutes));

      if (alreadyDoneToday) {
        if (target.isBefore(now) || target.day == now.day) {
          target = target.add(const Duration(days: 1));
        }
      } else {
        if (target.isBefore(now)) {
          target = target.add(const Duration(days: 1));
        }
      }

      return target;
    } catch (_) {
      return null;
    }
  }

  Future<void> _scheduleZonedNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: NotificationPayloadBuilder.reminderDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      debugPrint(
        '[NotificationService] Scheduled notification #$id at $scheduledDate (exact)',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] Exact alarm failed for #$id ($e), retrying with inexact mode...',
      );
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: NotificationPayloadBuilder.reminderDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: matchDateTimeComponents,
        );
        debugPrint(
          '[NotificationService] Scheduled notification #$id at $scheduledDate (inexact)',
        );
      } catch (innerError) {
        debugPrint(
          '[NotificationService] Failed to schedule notification #$id: $innerError',
        );
      }
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
      notificationDetails: NotificationPayloadBuilder.reminderDetails(),
    );
  }

  /// Schedule a test reminder to fire in [seconds] seconds (default 5s)
  Future<void> scheduleTestReminder({int seconds = 5}) async {
    if (!_isInitialized) await initialize();
    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = now.add(Duration(seconds: seconds));

    await _scheduleZonedNotification(
      id: 998,
      title: '⏰ Uji Jadwal Pengingat Presensi',
      body: 'Pengingat berhasil berjalan sesuai jadwal ($seconds detik)!',
      scheduledDate: scheduledDate,
    );
  }

  /// Get list of all pending/scheduled notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (_) {
      return [];
    }
  }

  /// Show instant notification confirming an attendance event was submitted successfully
  Future<void> showAttendanceSubmittedNotification({
    required AttendanceEventType eventType,
    DateTime? timestamp,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      if (!await isEnabled()) return;

      final payload = NotificationPayloadBuilder.buildSubmittedPayload(
        eventType: eventType,
        timestamp: timestamp,
      );

      final notifId = DateTime.now().millisecondsSinceEpoch % 100000 + 200;

      await _notificationsPlugin.show(
        id: notifId,
        title: payload.title,
        body: payload.body,
        notificationDetails: NotificationPayloadBuilder.submissionDetails(),
      );
      debugPrint(
        '[NotificationService] Submitted attendance notification sent: ${payload.title}',
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

      final payload = NotificationPayloadBuilder.buildFailedPayload(
        eventType: eventType,
        reason: reason,
        timestamp: timestamp,
      );

      final notifId = DateTime.now().millisecondsSinceEpoch % 100000 + 400;

      await _notificationsPlugin.show(
        id: notifId,
        title: payload.title,
        body: payload.body,
        notificationDetails: NotificationPayloadBuilder.failureDetails(),
      );
      debugPrint(
        '[NotificationService] Failed attendance notification sent: ${payload.title}',
      );
    } catch (e) {
      debugPrint(
        '[NotificationService] Error showing failed notification: $e',
      );
    }
  }
}
