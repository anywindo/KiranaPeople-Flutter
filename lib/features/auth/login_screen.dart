import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/widgets/offline_banner.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/package_info_provider.dart';
import 'forgot_password_sheet.dart';
import 'widgets/login_form_card.dart';
import 'widgets/login_header.dart';
import 'widgets/login_motivation_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isPasswordVisible = false;
  bool _rememberMe = true;
  int _quoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _quoteIndex = DateTime.now().day % islamicQuotes.length;
    _identifierFocus.addListener(_onStateUpdate);
    _passwordFocus.addListener(_onStateUpdate);
    _identifierController.addListener(_onStateUpdate);
    _passwordController.addListener(_onStateUpdate);
    _loadSavedCredentials();
  }

  void _onStateUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('saved_login_identifier');
      final remember = prefs.getBool('remember_login_credentials') ?? true;
      if (mounted) {
        setState(() {
          _rememberMe = remember;
          if (remember && savedId != null && savedId.isNotEmpty) {
            _identifierController.text = savedId;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _identifierController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  void _submit() async {
    if (!_isFormValid) return;
    AppHaptics.medium();
    FocusScope.of(context).unfocus();

    final isOffline = ref.read(isOfflineProvider);
    if (isOffline) {
      AppHaptics.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak ada koneksi internet. Silakan periksa koneksi Anda untuk masuk.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final identifier = _identifierController.text.trim();
    final success = await ref
        .read(authProvider.notifier)
        .login(identifier, _passwordController.text);
    if (success) {
      AppHaptics.success();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_login_credentials', _rememberMe);
        if (_rememberMe) {
          await prefs.setString('saved_login_identifier', identifier);
        } else {
          await prefs.remove('saved_login_identifier');
        }
      } catch (_) {}
    } else {
      AppHaptics.error();
    }
  }

  void _showForgotPasswordDialog() {
    final currentEmail = _identifierController.text.trim();
    ForgotPasswordSheet.show(
      context,
      initialEmail: currentEmail.contains('@') ? currentEmail : '',
      onResetSuccess: (resetEmail) {
        setState(() {
          _identifierController.text = resetEmail;
          _passwordController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata sandi berhasil diperbarui. Silakan masuk.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _nextQuote() {
    setState(() {
      _quoteIndex = (_quoteIndex + 1) % islamicQuotes.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final appVersion = ref.watch(appVersionDisplayProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // 1. Logo & Greeting Header
                            const LoginHeader(),

                            // 2. Material 3 Form Card Surface
                            LoginFormCard(
                              identifierController: _identifierController,
                              passwordController: _passwordController,
                              identifierFocus: _identifierFocus,
                              passwordFocus: _passwordFocus,
                              isPasswordVisible: _isPasswordVisible,
                              rememberMe: _rememberMe,
                              isFormValid: _isFormValid,
                              isLoading: authState.isLoading,
                              errorMessage: authState.errorMessage,
                              onTogglePasswordVisibility: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              onRememberMeChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? true;
                                });
                              },
                              onForgotPasswordTap: _showForgotPasswordDialog,
                              onSubmit: _submit,
                            ),
                            const SizedBox(height: 20),

                            // 3. Islamic Motivation Card
                            LoginMotivationCard(
                              quoteIndex: _quoteIndex,
                              onTap: _nextQuote,
                            ),

                            const Spacer(),
                            const SizedBox(height: 24),

                            // 4. Version Section Footer
                            Text(
                              'Versi $appVersion',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: context.textMutedColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
