import 'package:flutter/material.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../data/models/attendance_event_model.dart';

class NotificationTestSheet extends StatelessWidget {
  const NotificationTestSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const NotificationTestSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Uji Coba Suara & Notifikasi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.alarm_on_rounded, color: Color(0xFF3B82F6)),
                ),
                title: const Text('Uji Pengingat Jadwal (5 Detik)'),
                subtitle: const Text(
                  'Menguji sistem AlarmManager & layar kunci',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await NotificationService.instance.scheduleTestReminder(
                    seconds: 5,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '⏰ Pengingat dijadwalkan dalam 5 detik! Kunci layar atau minimalkan aplikasi untuk menguji.',
                        ),
                        backgroundColor: Color(0xFF1E293B),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF1F2),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFFE11D48),
                  ),
                ),
                title: const Text('Uji Pengingat Presensi (Langsung)'),
                subtitle: const Text('Kanal: attendance_reminders'),
                onTap: () async {
                  Navigator.pop(context);
                  await NotificationService.instance.showTestNotification();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFD1FAE5),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                  ),
                ),
                title: const Text('Presensi Berhasil'),
                subtitle: const Text(
                  'Notifikasi sukses + Suara Successful.mp3',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await NotificationService.instance
                      .showAttendanceSubmittedNotification(
                        eventType: AttendanceEventType.startShift,
                      );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEE2E2),
                  child: Icon(Icons.cancel_rounded, color: Color(0xFFEF4444)),
                ),
                title: const Text('Presensi Gagal (Fallback)'),
                subtitle: const Text(
                  'Notifikasi gagal + Suara Unsuccessful.mp3',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await NotificationService.instance
                      .showAttendanceFailedNotification(
                        eventType: AttendanceEventType.startShift,
                        reason: 'Koneksi internet terputus',
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
