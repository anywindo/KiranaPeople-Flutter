import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/offline_banner.dart';
import '../../data/models/user_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/history_provider.dart';
import '../attendance/attendance_screen.dart';
import '../history/history_screen.dart';
import '../map/map_view_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      MainNavigationScreenState();

  static MainNavigationScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainNavigationScreenState>();
}

class MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void switchToTab(int index) {
    if (index < 0 || index >= _screens.length) return;
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
    _triggerSubtleTabSync(index);
  }

  void _triggerSubtleTabSync(int index) {
    if (index == 0) {
      ref.read(todayAttendanceProvider.notifier).refresh(isBackground: true);
    } else if (index == 2) {
      ref.read(historyProvider.notifier).refresh(isBackground: true);
    }
  }

  final List<Widget> _screens = const [
    AttendanceScreen(),
    MapViewScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  Widget _buildNavAvatar({
    required BuildContext context,
    required UserModel? user,
    required bool isSelected,
  }) {
    final avatarUrl = user?.fullAvatarUrl ?? user?.avatar;
    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (context.isDarkMode
                    ? AppColors.darkTextSecondary.withValues(alpha: 0.45)
                    : AppColors.textSecondary.withValues(alpha: 0.35)),
          width: isSelected ? 2.0 : 1.2,
        ),
      ),
      child: ClipOval(
        child: hasAvatar
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) =>
                    _buildNavFallback(context, user, isSelected),
                placeholder: (_, _) =>
                    Container(color: context.surfaceSecondaryColor),
              )
            : _buildNavFallback(context, user, isSelected),
      ),
    );
  }

  Widget _buildNavFallback(
    BuildContext context,
    UserModel? user,
    bool isSelected,
  ) {
    final name = user?.name.trim() ?? '';
    if (name.isNotEmpty) {
      final initial = name.substring(0, 1).toUpperCase();
      return Container(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : context.surfaceSecondaryColor,
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? AppColors.primary
                  : context.textSecondaryColor,
            ),
          ),
        ),
      );
    }
    return Container(
      color: context.surfaceSecondaryColor,
      child: Center(
        child: Icon(
          isSelected ? Icons.person_rounded : Icons.person_outline_rounded,
          size: 16,
          color: isSelected ? AppColors.primary : context.textSecondaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBannerVisible = ref.watch(isOfflineBannerVisibleProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      extendBody: true,
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: isBannerVisible,
              removeBottom: true,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: _screens,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Exact Feathered Blur Gradient from bottom to top behind navbar
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRect(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black, Colors.black, Colors.transparent],
                      stops: [0.0, 0.60, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
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

          // 2. Floating Island Navigation Bar
          SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: context.isDarkMode
                        ? const Color(0xFF334155).withValues(alpha: 0.8)
                        : const Color(0xFFCBD5E1).withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: context.isDarkMode ? 0.35 : 0.08,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      color: context.surfaceColor.withValues(
                        alpha: context.isDarkMode ? 0.82 : 0.88,
                      ),
                      child: NavigationBarTheme(
                        data: NavigationBarThemeData(
                          height: 64,
                          backgroundColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          indicatorColor: AppColors.primary.withValues(
                            alpha: context.isDarkMode ? 0.22 : 0.14,
                          ),
                          indicatorShape: const StadiumBorder(),
                          labelTextStyle: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            final isSelected = states.contains(
                              WidgetState.selected,
                            );
                            return TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : (context.isDarkMode
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary),
                            );
                          }),
                          iconTheme: WidgetStateProperty.resolveWith((states) {
                            final isSelected = states.contains(
                              WidgetState.selected,
                            );
                            return IconThemeData(
                              size: 22,
                              color: isSelected
                                  ? AppColors.primary
                                  : (context.isDarkMode
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary),
                            );
                          }),
                        ),
                        child: NavigationBar(
                          selectedIndex: _currentIndex,
                          backgroundColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          elevation: 0,
                          animationDuration: const Duration(milliseconds: 350),
                          onDestinationSelected: (index) {
                            if (_currentIndex == index) return;
                            HapticFeedback.selectionClick();
                            switchToTab(index);
                          },
                          destinations: [
                            const NavigationDestination(
                              icon: Icon(Icons.home_outlined),
                              selectedIcon: Icon(
                                Icons.home_rounded,
                                color: AppColors.primary,
                              ),
                              label: 'Beranda',
                              tooltip: '',
                            ),
                            const NavigationDestination(
                              icon: Icon(Icons.map_outlined),
                              selectedIcon: Icon(
                                Icons.map_rounded,
                                color: AppColors.primary,
                              ),
                              label: 'Peta',
                              tooltip: '',
                            ),
                            const NavigationDestination(
                              icon: Icon(Icons.history_rounded),
                              selectedIcon: Icon(
                                Icons.history_toggle_off_rounded,
                                color: AppColors.primary,
                              ),
                              label: 'Riwayat',
                              tooltip: '',
                            ),
                            NavigationDestination(
                              icon: _buildNavAvatar(
                                context: context,
                                user: user,
                                isSelected: false,
                              ),
                              selectedIcon: _buildNavAvatar(
                                context: context,
                                user: user,
                                isSelected: true,
                              ),
                              label: 'Profil',
                              tooltip: '',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
