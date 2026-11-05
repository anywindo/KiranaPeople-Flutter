import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/models/attendance_event_model.dart';
import 'notification_channels.dart';

class NotificationPayloadBuilder {
  NotificationPayloadBuilder._();

  static NotificationDetails reminderDetails() {
    const androidDetails = AndroidNotificationDetails(
      NotificationChannels.reminderChannelId,
      NotificationChannels.reminderChannelName,
      channelDescription: NotificationChannels.reminderChannelDesc,
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

  static NotificationDetails submissionDetails() {
    const androidDetails = AndroidNotificationDetails(
      NotificationChannels.submissionChannelId,
      NotificationChannels.submissionChannelName,
      channelDescription: NotificationChannels.submissionChannelDesc,
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

  static NotificationDetails failureDetails() {
    const androidDetails = AndroidNotificationDetails(
      NotificationChannels.failureChannelId,
      NotificationChannels.failureChannelName,
      channelDescription: NotificationChannels.failureChannelDesc,
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

  /// Formats time strictly into Western Indonesian Time (WIB / UTC+7) 'HH:mm'
  static String formatWibTime(DateTime? timestamp) {
    final rawTime = timestamp ?? DateTime.now();
    final time = rawTime.toUtc().add(const Duration(hours: 7));
    final hourStr = time.hour.toString().padLeft(2, '0');
    final minuteStr = time.minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  static ({String title, String body}) buildSubmittedPayload({
    required AttendanceEventType eventType,
    DateTime? timestamp,
  }) {
    final timeStr = formatWibTime(timestamp);
    final eventLabel = eventType.label;
    final title = '✅ Presensi $eventLabel Berhasil';
    final body =
        'Presensi $eventLabel Anda telah berhasil dicatat pada pukul $timeStr WIB. Data telah tersinkronisasi.';
    return (title: title, body: body);
  }

  static ({String title, String body}) buildFailedPayload({
    required AttendanceEventType eventType,
    String? reason,
    DateTime? timestamp,
  }) {
    final timeStr = formatWibTime(timestamp);
    final eventLabel = eventType.label;
    final title = '❌ Presensi $eventLabel Gagal';
    final cleanReason = reason != null && reason.trim().isNotEmpty
        ? ': ${reason.trim()}'
        : '';
    final body =
        'Presensi $eventLabel Anda pada pukul $timeStr WIB tidak berhasil tercatat$cleanReason. Silakan buka aplikasi dan coba kembali.';
    return (title: title, body: body);
  }
}
