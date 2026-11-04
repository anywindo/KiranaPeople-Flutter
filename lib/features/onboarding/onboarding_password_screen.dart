import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'widgets/onboarding_logout_dialog.dart';
import 'widgets/onboarding_password_header.dart';
import 'widgets/onboarding_password_requirements.dart';
import 'widgets/onboarding_policy_agreement.dart';

export 'widgets/onboarding_logout_dialog.dart';
export 'widgets/onboarding_password_header.dart';
export 'widgets/onboarding_password_requirements.dart';
export 'widgets/onboarding_policy_agreement.dart';

class OnboardingPasswordScreen extends ConsumerStatefulWidget {
  const OnboardingPasswordScreen({super.key});

  @override
  ConsumerState<OnboardingPasswordScreen> createState() =>
      _OnboardingPasswordScreenState();
}

class _OnboardingPasswordScreenState
    extends ConsumerState<OnboardingPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _newPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _hasAcceptedPolicies = true;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() {
      if (mounted) setState(() {});
    });
    _confirmPasswordController.addListener(() {
      if (mounted) setState(() {});
    });
    _newPasswordFocus.addListener(() {
      if (mounted) setState(() {});
    });
    _confirmPasswordFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  String get _newPassword => _newPasswordController.text;
  String get _confirmPassword => _confirmPasswordController.text;

  bool get _hasMinLength => _newPassword.length >= 8;
  bool get _hasMixedCase =>
      RegExp(r'[A-Z]').hasMatch(_newPassword) &&
      RegExp(r'[a-z]').hasMatch(_newPassword);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_newPassword);
  bool get _isMatching =>
      _newPassword.isNotEmpty && _newPassword == _confirmPassword;
  bool get _isNotDefault =>
      _newPassword.isNotEmpty && _newPassword.toLowerCase() != 'password';

  bool get _isFormValid =>
      _hasMinLength &&
      _hasMixedCase &&
      _hasNumber &&
      _isMatching &&
      _isNotDefault &&
      _hasAcceptedPolicies;

  Future<void> _submit() async {
    if (!_isFormValid) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _localError = null;
    });

    final success = await ref
        .read(authProvider.notifier)
        .updateOnboardingPassword(
          password: _newPassword,
          confirmPassword: _confirmPassword,
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata sandi berhasil diaktivasi! Selamat datang.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final authError = ref.read(authProvider).errorMessage;
        setState(() {
          _localError = authError ?? 'Gagal memperbarui kata sandi.';
        });
      }
    }
  }

  void _showLogoutConfirmDialog() {
    OnboardingLogoutDialog.show(
      context,
      onConfirmLogout: () {
        Navigator.of(
          context,
          rootNavigator: true,
        ).popUntil((route) => route.isFirst);
        ref.read(authProvider.notifier).logout();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final errorMessage = _localError;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showLogoutConfirmDialog();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: authState.isLoading
                    ? null
                    : _showLogoutConfirmDialog,
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Keluar',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header (Icon, Title, Subtitle)
                OnboardingPasswordHeader(user: user),
                const SizedBox(height: 24),

                // Error Banner
                if (errorMessage != null && errorMessage.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: AppColors.error,
                          ),
                          onPressed: () {
                            setState(() {
                              _localError = null;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // New Password Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kata Sandi Baru',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _newPasswordFocus.hasFocus
                              ? AppColors.primary
                              : const Color(0xFFE5E7EB),
                          width: _newPasswordFocus.hasFocus ? 1.5 : 1,
                        ),
                      ),
                      child: TextField(
                        controller: _newPasswordController,
                        focusNode: _newPasswordFocus,
                        obscureText: !_isNewPasswordVisible,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Minimal 8 karakter',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isNewPasswordVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: const Color(0xFF9CA3AF),
                            ),
                            onPressed: () {
                              setState(() {
                                _isNewPasswordVisible = !_isNewPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Konfirmasi Kata Sandi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _confirmPasswordFocus.hasFocus
                              ? AppColors.primary
                              : const Color(0xFFE5E7EB),
                          width: _confirmPasswordFocus.hasFocus ? 1.5 : 1,
                        ),
                      ),
                      child: TextField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocus,
                        obscureText: !_isConfirmPasswordVisible,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: 'Ketik ulang kata sandi',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isMatching)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 18,
                                    color: AppColors.success,
                                  ),
                                ),
                              IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 18,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Requirements Checklist
                OnboardingPasswordRequirements(
                  hasMinLength: _hasMinLength,
                  hasMixedCase: _hasMixedCase,
                  hasNumber: _hasNumber,
                  isMatching: _isMatching,
                ),
                const SizedBox(height: 18),

                // Privacy Policy Checkbox
                OnboardingPolicyAgreement(
                  hasAcceptedPolicies: _hasAcceptedPolicies,
                  onChanged: (val) {
                    setState(() {
                      _hasAcceptedPolicies = val;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid
                          ? AppColors.primary
                          : const Color(0xFFE5E7EB),
                      foregroundColor: _isFormValid
                          ? Colors.white
                          : const Color(0xFF9CA3AF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _isFormValid ? 2 : 0,
                    ),
                    onPressed: (_isFormValid && !authState.isLoading)
                        ? _submit
                        : null,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Simpan & Lanjutkan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
