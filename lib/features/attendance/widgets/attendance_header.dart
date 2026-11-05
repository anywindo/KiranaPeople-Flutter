import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/continuous_marquee_text.dart';
import '../../../data/models/user_model.dart';
import '../../navigation/main_navigation_screen.dart';
import '../../profile/profile_screen.dart';

/// Sticky Top Bar with "KIRANA GROUP", Sync Indicator, Refresh, and Logout buttons.
/// Has no background when at rest at the top, and uses a feather blur gradient when
/// items scroll behind it.
class AttendanceStickyTopBar extends StatelessWidget {
  final bool isBackgroundSyncing;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final ScrollController? scrollController;
  final double topPadding;

  const AttendanceStickyTopBar({
    super.key,
    required this.isBackgroundSyncing,
    required this.onRefresh,
    required this.onLogout,
    this.scrollController,
    this.topPadding = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final blurHeight = topPadding + 84.0;

    Widget buildBar(double progress) {
      return SizedBox(
        height: blurHeight,
        child: Stack(
          children: [
            // 1. Lightweight Feathered Blur Gradient Background
            if (progress > 0.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: progress,
                    child: ClipRect(
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black,
                              Colors.black,
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.60, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  context.scaffoldBg.withValues(
                                    alpha: context.isDarkMode ? 0.98 : 0.96,
                                  ),
                                  context.scaffoldBg.withValues(
                                    alpha: context.isDarkMode ? 0.96 : 0.94,
                                  ),
                                  context.scaffoldBg.withValues(
                                    alpha: context.isDarkMode ? 0.60 : 0.50,
                                  ),
                                  context.scaffoldBg.withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 0.55, 0.78, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 2. Sticky Header Items (Sync progress, Title, Refresh & Logout buttons)
            Positioned(
              top: topPadding,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Subtle background sync indicator
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

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'KIRANA GROUP',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: context.textPrimaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
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
                                border: Border.all(
                                  color: context.isDarkMode
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
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
                                border: Border.all(
                                  color: context.isDarkMode
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
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
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (scrollController != null) {
      return AnimatedBuilder(
        animation: scrollController!,
        builder: (context, _) {
          final offset = scrollController!.hasClients
              ? scrollController!.offset
              : 0.0;
          final progress = (offset / 36.0).clamp(0.0, 1.0);
          return buildBar(progress);
        },
      );
    }

    return buildBar(0.0);
  }
}

/// User Greeting Section (Avatar with Profile Redirect, Greeting Text,
/// User Name with ContinuousMarqueeText, and AttendanceLiveClock).
class AttendanceGreetingSection extends StatelessWidget {
  final UserModel? user;

  const AttendanceGreetingSection({super.key, required this.user});

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
        initial = parts[0]
            .substring(0, parts[0].length >= 2 ? 2 : 1)
            .toUpperCase();
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
    return Row(
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
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
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
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: user?.avatar != null && user!.avatar!.isNotEmpty
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
        // jelek
        // const SizedBox(width: 8),
        // const AttendanceLiveClock(),
      ],
    );
  }
}

/// Composite Attendance Header for backward compatibility and test stability.
class AttendanceHeader extends StatelessWidget {
  final UserModel? user;
  final bool isBackgroundSyncing;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final bool includeTopBar;
  final ScrollController? scrollController;
  final double topPadding;

  const AttendanceHeader({
    super.key,
    required this.user,
    required this.isBackgroundSyncing,
    required this.onRefresh,
    required this.onLogout,
    this.includeTopBar = true,
    this.scrollController,
    this.topPadding = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!includeTopBar) {
      return AttendanceGreetingSection(user: user);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AttendanceStickyTopBar(
          isBackgroundSyncing: isBackgroundSyncing,
          onRefresh: onRefresh,
          onLogout: onLogout,
          scrollController: scrollController,
          topPadding: topPadding,
        ),
        const SizedBox(height: 12),
        AttendanceGreetingSection(user: user),
      ],
    );
  }
}
