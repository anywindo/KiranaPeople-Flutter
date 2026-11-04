import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/package_info_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../onboarding/privacy_policy_sheet.dart';
import 'profile_card_group.dart';
import 'sheets/notification_test_sheet.dart';
import 'sheets/theme_mode_sheet.dart';

export 'sheets/notification_test_sheet.dart';
export 'sheets/theme_mode_sheet.dart';

class ProfilePreferencesSection extends ConsumerWidget {
  final void Function(String message, {bool isError}) onShowToast;

  const ProfilePreferencesSection({
    super.key,
    required this.onShowToast,
  });

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
          onTap: () => NotificationTestSheet.show(context),
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
          onTap: () => ThemeModeSheet.show(context, ref),
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
