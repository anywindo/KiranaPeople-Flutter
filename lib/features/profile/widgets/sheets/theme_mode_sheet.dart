import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/theme_provider.dart';

class ThemeModeSheet extends ConsumerWidget {
  const ThemeModeSheet({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const ThemeModeSheet(),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeProvider);

    return SafeArea(
      child: SingleChildScrollView(
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
                  Navigator.pop(context);
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
                  Navigator.pop(context);
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
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
