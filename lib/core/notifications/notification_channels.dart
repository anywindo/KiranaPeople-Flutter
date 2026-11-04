import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationChannels {
  NotificationChannels._();

  // Notification IDs
  static const int idShiftStart30Min = 101;
  static const int idShiftStart15Min = 102;
  static const int idBreakEnd = 103;
  static const int idShiftEnd = 104;

  // Channel details
  static const String reminderChannelId = 'attendance_reminders';
  static const String reminderChannelName = 'Pengingat Presensi';
  static const String reminderChannelDesc =
      'Notifikasi pengingat jadwal masuk kerja, istirahat, dan pulang.';

  static const String submissionChannelId = 'attendance_submissions_success_v1';
  static const String submissionChannelName = 'Konfirmasi Presensi';
  static const String submissionChannelDesc =
      'Notifikasi konfirmasi saat presensi berhasil dicatat.';

  static const String failureChannelId = 'attendance_submissions_failure_v1';
  static const String failureChannelName = 'Presensi Belum Tercatat';
  static const String failureChannelDesc =
      'Notifikasi peringatan saat presensi gagal dikirim atau tidak tercatat.';

  static const AndroidNotificationChannel reminderChannel =
      AndroidNotificationChannel(
    reminderChannelId,
    reminderChannelName,
    description: reminderChannelDesc,
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel submissionChannel =
      AndroidNotificationChannel(
    submissionChannelId,
    submissionChannelName,
    description: submissionChannelDesc,
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('successful'),
    enableVibration: true,
  );

  static const AndroidNotificationChannel failureChannel =
      AndroidNotificationChannel(
    failureChannelId,
    failureChannelName,
    description: failureChannelDesc,
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('unsuccessful'),
    enableVibration: true,
  );
}

