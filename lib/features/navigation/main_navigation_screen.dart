import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/offline_banner.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/history_provider.dart';
import '../attendance/attendance_screen.dart';
import '../history/history_screen.dart';
import '../map/map_view_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => MainNavigationScreenState();

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

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: isOffline,
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
                    color: context.borderColor.withValues(
                      alpha: context.isDarkMode ? 0.35 : 0.65,
                    ),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: context.isDarkMode ? 0.40 : 0.08,
                      ),
                      blurRadius: 24,
                      spreadRadius: -2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: context.isDarkMode ? 0.06 : 0.03,
                      ),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
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
                          labelTextStyle: WidgetStateProperty.resolveWith((states) {
                            final isSelected = states.contains(WidgetState.selected);
                            return TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : (context.isDarkMode
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary),
                            );
                          }),
                          iconTheme: WidgetStateProperty.resolveWith((states) {
                            final isSelected = states.contains(WidgetState.selected);
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
                          destinations: const [
                            NavigationDestination(
                              icon: Icon(Icons.home_outlined),
                              selectedIcon:
                                  Icon(Icons.home_rounded, color: AppColors.primary),
                              label: 'Beranda',
                              tooltip: '',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.map_outlined),
                              selectedIcon:
                                  Icon(Icons.map_rounded, color: AppColors.primary),
                              label: 'Peta',
                              tooltip: '',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.history_rounded),
                              selectedIcon: Icon(
                                Icons.history_toggle_off_rounded,
                                color: AppColors.primary,
                              ),
                              label: 'Riwayat',
                              tooltip: '',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.person_outline_rounded),
                              selectedIcon:
                                  Icon(Icons.person_rounded, color: AppColors.primary),
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

