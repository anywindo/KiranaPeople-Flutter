import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/attendance_event_model.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/package_info_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../onboarding/privacy_policy_sheet.dart';
import 'profile_card_group.dart';

class ProfilePreferencesSection extends ConsumerWidget {
  final void Function(String message, {bool isError}) onShowToast;

  const ProfilePreferencesSection({
    super.key,
    required this.onShowToast,
  });

  void _showThemeModeSheet(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Tema Tampilan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sesuaikan tampilan aplikasi dengan kenyamanan mata Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 20),
              _buildThemeOptionTile(
                context,
                title: 'Otomatis (Ikuti Sistem)',
                subtitle: 'Menyesuaikan otomatis dengan tema perangkat',
                icon: Icons.brightness_auto_rounded,
                iconBg: context.isDarkMode
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF3B82F6),
                isSelected: currentMode == ThemeMode.system,
                onTap: () {
                  ref
                      .read(themeProvider.notifier)
                      .setThemeMode(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
              _buildThemeOptionTile(
                context,
                title: 'Mode Terang (Light)',
                subtitle: 'Tampilan bersih dan kontras cerah',
                icon: Icons.light_mode_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                isSelected: currentMode == ThemeMode.light,
                onTap: () {
                  ref
                      .read(themeProvider.notifier)
                      .setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
              _buildThemeOptionTile(
                context,
                title: 'Mode Gelap (Dark)',
                subtitle: 'Nuansa gelap elegan yang nyaman di mata',
                icon: Icons.dark_mode_rounded,
                iconBg: const Color(0xFF2E1065),
                iconColor: const Color(0xFFA855F7),
                isSelected: currentMode == ThemeMode.dark,
                onTap: () {
                  ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOptionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? AppColors.primary : context.borderColor,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      tileColor: isSelected
          ? AppColors.primary.withValues(
              alpha: context.isDarkMode ? 0.15 : 0.06,
            )
          : context.surfaceColor,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: context.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 22,
            )
          : Icon(
              Icons.radio_button_unchecked_rounded,
              color: context.borderColor,
              size: 22,
            ),
    );
  }

  void _showNotificationTestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Uji Coba Suara & Notifikasi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
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
                  Navigator.pop(ctx);
                  await NotificationService.instance
                      .showAttendanceSubmittedNotification(
                        eventType: AttendanceEventType.startShift,
                      );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEE2E2),
                  child: Icon(
                    Icons.cancel_rounded,
                    color: Color(0xFFEF4444),
                  ),
                ),
                title: const Text('Presensi Gagal (Fallback)'),
                subtitle: const Text(
                  'Notifikasi gagal + Suara Unsuccessful.mp3',
                ),
                onTap: () async {
                  Navigator.pop(ctx);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appVersion = ref.watch(appVersionDisplayProvider);
    final isNotifEnabled = ref.watch(notificationEnabledProvider);

    return ProfileCardGroup(
      children: [
        ProfileRowItem(
          iconBg: context.isDarkMode
              ? const Color(0xFF3B1524)
              : const Color(0xFFFFF1F5),
          icon: Icons.notifications_active_rounded,
          iconColor: AppColors.primary,
          title: 'Pengingat Presensi',
          trailing: Switch.adaptive(
            value: isNotifEnabled,
            activeTrackColor: AppColors.primary,
            onChanged: (val) {
              ref.read(notificationEnabledProvider.notifier).toggle(val);
              onShowToast(
                val
                    ? 'Pengingat presensi otomatis diaktifkan'
                    : 'Pengingat presensi dinonaktifkan',
              );
            },
          ),
          onTap: () => _showNotificationTestSheet(context),
        ),
        Divider(
          height: 1,
          indent: 56,
          color: context.dividerColor,
        ),
        ProfileRowItem(
          iconBg: context.isDarkMode
              ? const Color(0xFF3B1524)
              : const Color(0xFFFFF1F5),
          icon: Icons.palette_rounded,
          iconColor: AppColors.primary,
          title: 'Tema Tampilan',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final mode = ref.watch(themeProvider);
                  final label = switch (mode) {
                    ThemeMode.light => 'Terang',
                    ThemeMode.dark => 'Gelap',
                    ThemeMode.system => 'Sistem',
                  };
                  return Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondaryColor,
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: context.textMutedColor,
              ),
            ],
          ),
          onTap: () => _showThemeModeSheet(context, ref),
        ),
        Divider(
          height: 1,
          indent: 56,
          color: context.dividerColor,
        ),
        ProfileRowItem(
          iconBg: context.isDarkMode
              ? const Color(0xFF3B1524)
              : const Color(0xFFFFF1F5),
          icon: Icons.policy_rounded,
          iconColor: AppColors.primary,
          title: 'Kebijakan Privasi',
          trailing: Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: context.textMutedColor,
          ),
          onTap: () => PrivacyPolicySheet.show(context),
        ),
        Divider(
          height: 1,
          indent: 56,
          color: context.dividerColor,
        ),
        ProfileRowItem(
          iconBg: context.isDarkMode
              ? const Color(0xFF283344)
              : const Color(0xFFF3F4F6),
          icon: Icons.info_rounded,
          iconColor: context.textSecondaryColor,
          title: 'Versi Aplikasi',
          trailing: Text(
            appVersion,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

