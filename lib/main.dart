import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/server_settings_sheet.dart';
import 'features/navigation/main_navigation_screen.dart';
import 'features/onboarding/onboarding_password_screen.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: KiranaPeopleApp(),
    ),
  );
}

class KiranaPeopleApp extends StatelessWidget {
  const KiranaPeopleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kirana People',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RootScreen(),
    );
  }
}

class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // 1. Session checking state (mirroring iOS ContentView)
    if (authState.isCheckingSession) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      isDark
                          ? 'assets/images/LogoDark.png'
                          : 'assets/images/LogoLight.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark ? Colors.black : Colors.white,
                          child: Center(
                            child: Text(
                              'KIRANA',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Memeriksa sesi...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).cancelSessionCheck();
                  },
                  child: const Text(
                    'Batal & Masuk ke Akun',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => ServerSettingsSheet.show(context),
                  icon: const Icon(Icons.settings, size: 16, color: AppColors.textSecondary),
                  label: const Text(
                    'Pengaturan Server',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Authenticated user
    if (authState.isAuthenticated) {
      if (authState.requiresOnboarding) {
        return const OnboardingPasswordScreen();
      }
      return MainNavigationScreen(key: ValueKey(authState.user?.id));
    }

    // 3. Unauthenticated -> Login
    return const LoginScreen();
  }
}
