import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'forgot_password_sheet.dart';

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

  @override
  void initState() {
    super.initState();
    _identifierFocus.addListener(() {
      if (mounted) setState(() {});
    });
    _passwordFocus.addListener(() {
      if (mounted) setState(() {});
    });
    _identifierController.addListener(() {
      if (mounted) setState(() {});
    });
    _passwordController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadSavedCredentials();
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
    FocusScope.of(context).unfocus();
    final identifier = _identifierController.text.trim();
    final success = await ref
        .read(authProvider.notifier)
        .login(identifier, _passwordController.text);
    if (success) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_login_credentials', _rememberMe);
        if (_rememberMe) {
          await prefs.setString('saved_login_identifier', identifier);
        } else {
          await prefs.remove('saved_login_identifier');
        }
      } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Kirana Logo Asset (logoKiranaSquare.jpeg)
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/logoKiranaSquare.jpeg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.black,
                                child: const Center(
                                  child: Text(
                                    'KIRANA',
                                    style: TextStyle(
                                      color: Colors.white,
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

                      // Title & Subtitle
                      Text(
                        'Masuk ke Akun Anda',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Silakan masukkan identitas dan kata sandi Anda',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Error message banner if any
                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFEF4444),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  authState.errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Field 1: Email / ID Karyawan / NIK
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _identifierController,
                            focusNode: _identifierFocus,
                            cursorColor: AppColors.primary,
                            style: TextStyle(
                              fontSize: 15,
                              color: context.textPrimaryColor,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_passwordFocus);
                            },
                            autocorrect: false,
                            decoration: InputDecoration(
                              hintText: 'Email / ID Karyawan / NIK',
                              hintStyle: TextStyle(
                                color: context.textMutedColor,
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                          ),
                          Container(
                            height: 1.5,
                            color: _identifierFocus.hasFocus
                                ? AppColors.primary
                                : context.borderColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Field 2: Kata Sandi
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  obscureText: !_isPasswordVisible,
                                  cursorColor: AppColors.primary,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submit(),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: context.textPrimaryColor,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Kata Sandi',
                                    hintStyle: TextStyle(
                                      color: context.textMutedColor,
                                      fontSize: 15,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: context.textMutedColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 1.5,
                            color: _passwordFocus.hasFocus
                                ? AppColors.primary
                                : context.borderColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Options Row: Ingat Saya + Lupa Kata Sandi?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Ingat Saya Checkbox
                          InkWell(
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    _rememberMe
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    size: 20,
                                    color: _rememberMe
                                        ? AppColors.primary
                                        : context.borderColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ingat Saya',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Lupa Kata Sandi?
                          InkWell(
                            onTap: _showForgotPasswordDialog,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                'Lupa Kata Sandi?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Masuk Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _isFormValid && !authState.isLoading
                                ? AppColors.primary
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isFormValid && !authState.isLoading
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isFormValid && !authState.isLoading
                                  ? _submit
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Center(
                                child: authState.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Masuk',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _isFormValid
                                              ? Colors.white
                                              : const Color(0xFF9CA3AF),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 32),

                      // Version section
                      const Text(
                        'Versi 1.0.0 (1)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E93),
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
    );
  }
}
