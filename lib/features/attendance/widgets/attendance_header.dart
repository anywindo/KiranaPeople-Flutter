import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/continuous_marquee_text.dart';
import '../../../data/models/user_model.dart';
import '../../navigation/main_navigation_screen.dart';
import '../../profile/profile_screen.dart';
import 'attendance_live_clock.dart';

class AttendanceHeader extends StatelessWidget {
  final UserModel? user;
  final bool isBackgroundSyncing;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const AttendanceHeader({
    super.key,
    required this.user,
    required this.isBackgroundSyncing,
    required this.onRefresh,
    required this.onLogout,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) {
      return 'Selamat Pagi,';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang,';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore,';
    } else {
      return 'Selamat Malam,';
    }
  }

  Widget _buildUserInitial(String name) {
    final trimmed = name.trim();
    String initial = 'US';
    if (trimmed.isNotEmpty) {
      final parts = trimmed.split(' ');
      if (parts.length >= 2) {
        initial = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initial =
            parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
      }
    }
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Subtle background sync indicator (2px, zero layout shift)
        AnimatedOpacity(
          opacity: isBackgroundSyncing ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // 1. Top Header Bar (KIRANA GROUP + Refresh + Logout)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'KIRANA GROUP',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: context.textPrimaryColor,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: onRefresh,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: context.isDarkMode ? 0.2 : 0.04,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isBackgroundSyncing
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: context.textSecondaryColor,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onLogout,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: context.isDarkMode ? 0.2 : 0.04,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. User Greeting Section (tap redirects to Profile) & Small Live Clock
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    final mainNav = MainNavigationScreen.of(context);
                    if (mainNav != null) {
                      mainNav.switchToTab(3);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    }
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      children: [
                        // Avatar photo or initials
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4338CA),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.isDarkMode
                                  ? context.surfaceColor
                                  : Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: context.isDarkMode ? 0.3 : 0.10,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: user?.avatar != null &&
                                    user!.avatar!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: user!.avatar!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) =>
                                        _buildUserInitial(user?.name ?? 'User'),
                                  )
                                : _buildUserInitial(user?.name ?? 'User'),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Greeting + Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.textMutedColor,
                                ),
                              ),
                              ContinuousMarqueeText(
                                text: user?.name ?? 'User',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                                blankSpace: 28.0,
                                velocity: 28.0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const AttendanceLiveClock(),
          ],
        ),
      ],
    );
  }
}
