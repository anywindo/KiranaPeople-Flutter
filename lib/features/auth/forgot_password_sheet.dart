import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';

enum ForgotPasswordStep { inputEmail, inputOtp, resetPassword }

class ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;
  final Function(String email)? onResetSuccess;

  const ForgotPasswordSheet({
    super.key,
    this.initialEmail = '',
    this.onResetSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    String initialEmail = '',
    Function(String email)? onResetSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ForgotPasswordSheet(
        initialEmail: initialEmail,
        onResetSuccess: onResetSuccess,
      ),
    );
  }

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  final AuthRepository _repository = AuthRepository();

  ForgotPasswordStep _step = ForgotPasswordStep.inputEmail;

  // Controllers
  late final TextEditingController _emailController;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Focus nodes
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _otpFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  // State
  bool _isLoading = false;
  String? _errorMessage;
  String? _successBannerMessage;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Timer
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail.trim());

    _emailController.addListener(_onFieldChanged);
    _otpController.addListener(_onFieldChanged);
    _newPasswordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);

    _emailFocus.addListener(_onFocusChanged);
    _otpFocus.addListener(_onFocusChanged);
    _newPasswordFocus.addListener(_onFocusChanged);
    _confirmPasswordFocus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    _emailFocus.dispose();
    _otpFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  // Validations
  bool get _isEmailValid {
    final email = _emailController.text.trim();
    if (email.isEmpty) return false;
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  bool get _isOtpValid {
    final otp = _otpController.text.trim();
    return otp.length == 6 && RegExp(r'^[0-9]{6}$').hasMatch(otp);
  }

  bool get _hasMinLength => _newPasswordController.text.length >= 8;
  bool get _hasMixedCase {
    final p = _newPasswordController.text;
    return p.contains(RegExp(r'[A-Z]')) && p.contains(RegExp(r'[a-z]'));
  }

  bool get _hasNumber => _newPasswordController.text.contains(RegExp(r'[0-9]'));
  bool get _isPasswordMatching {
    final p = _newPasswordController.text;
    final c = _confirmPasswordController.text;
    return p.isNotEmpty && p == c;
  }

  bool get _isResetFormValid =>
      _isOtpValid &&
      _hasMinLength &&
      _hasMixedCase &&
      _hasNumber &&
      _isPasswordMatching;

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() {
      _resendCooldown = seconds;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown > 1) {
        setState(() {
          _resendCooldown--;
        });
      } else {
        setState(() {
          _resendCooldown = 0;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (!_isEmailValid) {
      setState(() {
        _errorMessage = 'Invalid email address format.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final msg = await _repository.requestForgotPasswordOtp(email);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = ForgotPasswordStep.inputOtp;
        _successBannerMessage = msg;
        _errorMessage = null;
      });
      _startCooldown(60);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _otpFocus.requestFocus();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0 || _isLoading) return;
    final email = _emailController.text.trim();
    if (!_isEmailValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final msg = await _repository.requestForgotPasswordOtp(email);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _successBannerMessage = msg;
      });
      _startCooldown(60);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _proceedToResetPassword() {
    if (!_isOtpValid) {
      setState(() {
        _errorMessage = 'OTP code must be 6 digits.';
      });
      return;
    }
    setState(() {
      _errorMessage = null;
      _step = ForgotPasswordStep.resetPassword;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _newPasswordFocus.requestFocus();
    });
  }

  Future<void> _submitResetPassword() async {
    if (!_isResetFormValid) {
      if (!_isOtpValid) {
        _errorMessage = 'OTP code is invalid or empty (must be 6 digits).';
      } else if (!_hasMinLength) {
        _errorMessage = 'New password must be at least 8 characters.';
      } else if (!_hasMixedCase) {
        _errorMessage =
            'Password must contain uppercase and lowercase letters.';
      } else if (!_hasNumber) {
        _errorMessage = 'Password must contain at least 1 number.';
      } else if (!_isPasswordMatching) {
        _errorMessage = 'Password confirmation does not match.';
      }
      setState(() {});
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final msg = await _repository.resetPassword(
        email: email,
        otp: _otpController.text.trim(),
        password: _newPasswordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      _showSuccessDialog(email, msg);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _showSuccessDialog(String email, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Berhasil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message.isNotEmpty ? message : 'Kata sandi Anda berhasil diperbarui. Silakan masuk menggunakan kata sandi baru.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Close bottom sheet
                widget.onResetSuccess?.call(email);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Masuk Sekarang',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    setState(() {
      _errorMessage = null;
      if (_step == ForgotPasswordStep.resetPassword) {
        _step = ForgotPasswordStep.inputOtp;
      } else if (_step == ForgotPasswordStep.inputOtp) {
        _step = ForgotPasswordStep.inputEmail;
      }
    });
  }

  String get _headerTitle {
    switch (_step) {
      case ForgotPasswordStep.inputEmail:
        return 'Lupa Kata Sandi';
      case ForgotPasswordStep.inputOtp:
        return 'Verifikasi OTP';
      case ForgotPasswordStep.resetPassword:
        return 'Atur Kata Sandi Baru';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top grabber bar
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Back button or empty spacer
                if (_step != ForgotPasswordStep.inputEmail)
                  InkWell(
                    onTap: _goBack,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_left_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Kembali',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 40),

                // Center Title
                Expanded(
                  child: Text(
                    _headerTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),

                // Close Button
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF2F2F7)),

          // Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
              physics: const BouncingScrollPhysics(),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentStepContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_step) {
      case ForgotPasswordStep.inputEmail:
        return _buildStep1InputEmail();
      case ForgotPasswordStep.inputOtp:
        return _buildStep2InputOtp();
      case ForgotPasswordStep.resetPassword:
        return _buildStep3ResetPassword();
    }
  }

  // ===========================================================================
  // STEP 1: Input Email
  // ===========================================================================
  Widget _buildStep1InputEmail() {
    return Column(
      key: const ValueKey('step_1'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),

        // Circular Pink Badge
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 32,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Masukkan Email Akun',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 8),

        const Text(
          'Kami akan mengirimkan 6 digit kode OTP ke alamat email terdaftar untuk memverifikasi permintaan reset kata sandi Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93), height: 1.4),
        ),
        const SizedBox(height: 24),

        if (_errorMessage != null) ...[
          _buildErrorBanner(_errorMessage!),
          const SizedBox(height: 16),
        ],

        // Email Field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alamat Email',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _emailFocus.hasFocus
                      ? AppColors.primary
                      : const Color(0xFFE5E7EB),
                  width: _emailFocus.hasFocus ? 1.5 : 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      cursorColor: AppColors.primary,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'nama@kiranagroup.com',
                        hintStyle: TextStyle(
                          color: Color(0xFFC7C7CC),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                      onSubmitted: (_) {
                        if (_isEmailValid && !_isLoading) {
                          _submitEmail();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Kirim Kode OTP Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isEmailValid && !_isLoading
                  ? AppColors.primary
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isEmailValid && !_isLoading
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isEmailValid && !_isLoading ? _submitEmail : null,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              size: 16,
                              color: _isEmailValid
                                  ? Colors.white
                                  : const Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kirim Kode OTP',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _isEmailValid
                                    ? Colors.white
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Option to skip directly to entering OTP if user already got OTP or is rate-limited
        InkWell(
          onTap: () {
            setState(() {
              _step = ForgotPasswordStep.inputOtp;
              _errorMessage = null;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _otpFocus.requestFocus();
            });
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Sudah punya kode OTP? Masukkan Kode',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 2: Input OTP
  // ===========================================================================
  Widget _buildStep2InputOtp() {
    return Column(
      key: const ValueKey('step_2'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),

        // Circular Pink Badge
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.shield_outlined,
              size: 32,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Masukkan Kode OTP',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 8),

        Column(
          children: [
            const Text(
              'Kode verifikasi 6 digit telah dikirim ke:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 2),
            Text(
              _emailController.text.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Green Success Banner
        if (_successBannerMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA5D6A7), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _successBannerMessage!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF1B5E20),
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (_errorMessage != null) ...[
          _buildErrorBanner(_errorMessage!),
          const SizedBox(height: 16),
        ],

        // OTP Label + Resend Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kode OTP (6 Digit)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            if (_resendCooldown > 0)
              Text(
                'Kirim ulang (${_resendCooldown}s)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9CA3AF),
                ),
              )
            else
              InkWell(
                onTap: _isLoading ? null : _resendOtp,
                borderRadius: BorderRadius.circular(4),
                child: const Text(
                  'Kirim Ulang OTP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // 6-digit visual boxes with hidden TextField
        _buildOtpBoxes(),
        const SizedBox(height: 24),

        // Lanjutkan Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isOtpValid && !_isLoading
                  ? AppColors.primary
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isOtpValid && !_isLoading
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isOtpValid && !_isLoading
                    ? _proceedToResetPassword
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lanjutkan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _isOtpValid
                              ? Colors.white
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: _isOtpValid
                            ? Colors.white
                            : const Color(0xFF9CA3AF),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Change Email Option
        InkWell(
          onTap: () {
            setState(() {
              _step = ForgotPasswordStep.inputEmail;
              _errorMessage = null;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _emailFocus.requestFocus();
            });
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Salah alamat email? Ubah Email',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBoxes() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Invisible input field catching keyboard input
        Opacity(
          opacity: 0.01,
          child: TextField(
            controller: _otpController,
            focusNode: _otpFocus,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            autofocus: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),

        // Visual 6 digit boxes
        GestureDetector(
          onTap: () {
            _otpFocus.requestFocus();
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final otpText = _otpController.text;
              final char = index < otpText.length ? otpText[index] : '';
              final isFocused =
                  _otpFocus.hasFocus &&
                  (otpText.length == index ||
                      (index == 5 && otpText.length == 6));

              return Container(
                width: 48,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused
                        ? AppColors.primary
                        : const Color(0xFFE5E7EB),
                    width: isFocused ? 2.0 : 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  char,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STEP 3: Reset Password
  // ===========================================================================
  Widget _buildStep3ResetPassword() {
    return Column(
      key: const ValueKey('step_3'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),

        // Circular Pink Badge
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.lock_outline_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'Buat Kata Sandi Baru',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(height: 8),

        const Text(
          'Silakan tentukan kata sandi baru untuk mengamankan akun Anda.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
        ),
        const SizedBox(height: 20),

        if (_errorMessage != null) ...[
          _buildErrorBanner(_errorMessage!),
          const SizedBox(height: 16),
        ],

        // Field 1: Kata Sandi Baru
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kata Sandi Baru',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _newPasswordFocus.hasFocus
                      ? AppColors.primary
                      : const Color(0xFFE5E7EB),
                  width: _newPasswordFocus.hasFocus ? 1.5 : 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newPasswordController,
                      focusNode: _newPasswordFocus,
                      obscureText: !_isNewPasswordVisible,
                      cursorColor: AppColors.primary,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Minimal 8 karakter',
                        hintStyle: TextStyle(
                          color: Color(0xFFC7C7CC),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                      onSubmitted: (_) {
                        _confirmPasswordFocus.requestFocus();
                      },
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                    child: Icon(
                      _isNewPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Field 2: Konfirmasi Kata Sandi Baru
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konfirmasi Kata Sandi Baru',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _confirmPasswordFocus.hasFocus
                      ? AppColors.primary
                      : const Color(0xFFE5E7EB),
                  width: _confirmPasswordFocus.hasFocus ? 1.5 : 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocus,
                      obscureText: !_isConfirmPasswordVisible,
                      cursorColor: AppColors.primary,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ketik ulang kata sandi baru',
                        hintStyle: TextStyle(
                          color: Color(0xFFC7C7CC),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        isDense: true,
                      ),
                      onSubmitted: (_) {
                        if (_isResetFormValid && !_isLoading) {
                          _submitResetPassword();
                        }
                      },
                    ),
                  ),
                  if (_isPasswordMatching) ...[
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                  ],
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                    child: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Requirements Checklist Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              _buildRequirementRow('Minimal 8 karakter', _hasMinLength),
              const SizedBox(height: 8),
              _buildRequirementRow(
                'Kombinasi huruf besar & huruf kecil',
                _hasMixedCase,
              ),
              const SizedBox(height: 8),
              _buildRequirementRow('Mengandung minimal 1 angka', _hasNumber),
              const SizedBox(height: 8),
              _buildRequirementRow(
                'Konfirmasi kata sandi cocok',
                _isPasswordMatching,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Perbarui Kata Sandi Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isResetFormValid && !_isLoading
                  ? AppColors.primary
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isResetFormValid && !_isLoading
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isResetFormValid && !_isLoading
                    ? _submitResetPassword
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Perbarui Kata Sandi',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementRow(String text, bool isSatisfied) {
    return Row(
      children: [
        Icon(
          isSatisfied ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 16,
          color: isSatisfied ? AppColors.success : const Color(0xFFC7C7CC),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isSatisfied
                ? const Color(0xFF1F2937)
                : const Color(0xFF6B7280),
            fontWeight: isSatisfied ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
