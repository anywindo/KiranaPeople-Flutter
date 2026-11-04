import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';
import 'widgets/forgot_password_email_step.dart';
import 'widgets/forgot_password_otp_step.dart';
import 'widgets/forgot_password_reset_step.dart';
import 'widgets/forgot_password_stepper_header.dart';
import 'widgets/forgot_password_success_dialog.dart';

export 'widgets/forgot_password_banners.dart';
export 'widgets/forgot_password_email_step.dart';
export 'widgets/forgot_password_otp_step.dart';
export 'widgets/forgot_password_reset_step.dart';
export 'widgets/forgot_password_stepper_header.dart';
export 'widgets/forgot_password_success_dialog.dart';

enum ForgotPasswordStep { inputEmail, inputOtp, resetPassword }

class ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;
  final Function(String email)? onResetSuccess;
  final AuthRepository? repository;

  const ForgotPasswordSheet({
    super.key,
    this.initialEmail = '',
    this.onResetSuccess,
    this.repository,
  });

  static Future<void> show(
    BuildContext context, {
    String initialEmail = '',
    Function(String email)? onResetSuccess,
    AuthRepository? repository,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ForgotPasswordSheet(
        initialEmail: initialEmail,
        onResetSuccess: onResetSuccess,
        repository: repository,
      ),
    );
  }

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  late final AuthRepository _repository;

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

  // Timer
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AuthRepository();
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
        _errorMessage = 'Format alamat email tidak valid.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final msg = await _repository.requestForgotPasswordOtp(email);
      if (msg.toLowerCase().contains('jika email anda terdaftar')) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Email tidak terdaftar dalam sistem.';
        });
        return;
      }

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
      if (msg.toLowerCase().contains('jika email anda terdaftar')) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Email tidak terdaftar dalam sistem.';
        });
        return;
      }

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

  Future<void> _proceedToResetPassword() async {
    if (!_isOtpValid || _isLoading) {
      if (!_isOtpValid) {
        setState(() {
          _errorMessage = 'Kode OTP harus berupa 6 digit angka.';
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _repository.verifyOtp(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _step = ForgotPasswordStep.resetPassword;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _newPasswordFocus.requestFocus();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submitResetPassword() async {
    if (!_isResetFormValid) {
      if (!_isOtpValid) {
        _errorMessage = 'Kode OTP tidak valid (harus 6 digit angka).';
      } else if (!_hasMinLength) {
        _errorMessage = 'Kata sandi baru minimal 8 karakter.';
      } else if (!_hasMixedCase) {
        _errorMessage =
            'Kata sandi harus memuat kombinasi huruf besar dan kecil.';
      } else if (!_hasNumber) {
        _errorMessage = 'Kata sandi harus memuat minimal 1 angka.';
      } else if (!_isPasswordMatching) {
        _errorMessage = 'Konfirmasi kata sandi tidak cocok.';
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

      ForgotPasswordSuccessDialog.show(
        context,
        email: email,
        message: msg,
        onLoginNow: () {
          Navigator.pop(context); // Close bottom sheet
          widget.onResetSuccess?.call(email);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
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
          // Header Bar
          ForgotPasswordStepperHeader(
            title: _headerTitle,
            showBackButton: _step != ForgotPasswordStep.inputEmail,
            onBack: _goBack,
            onClose: () => Navigator.pop(context),
          ),

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
        return ForgotPasswordEmailStep(
          emailController: _emailController,
          emailFocus: _emailFocus,
          isEmailValid: _isEmailValid,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          onSubmit: _submitEmail,
          onAlreadyHaveOtpTap: () {
            setState(() {
              _step = ForgotPasswordStep.inputOtp;
              _errorMessage = null;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _otpFocus.requestFocus();
            });
          },
        );
      case ForgotPasswordStep.inputOtp:
        return ForgotPasswordOtpStep(
          email: _emailController.text.trim(),
          otpController: _otpController,
          otpFocus: _otpFocus,
          isOtpValid: _isOtpValid,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          successBannerMessage: _successBannerMessage,
          resendCooldown: _resendCooldown,
          onResendOtp: _resendOtp,
          onProceed: _proceedToResetPassword,
          onChangeEmailTap: () {
            setState(() {
              _step = ForgotPasswordStep.inputEmail;
              _errorMessage = null;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _emailFocus.requestFocus();
            });
          },
        );
      case ForgotPasswordStep.resetPassword:
        return ForgotPasswordResetStep(
          newPasswordController: _newPasswordController,
          confirmPasswordController: _confirmPasswordController,
          newPasswordFocus: _newPasswordFocus,
          confirmPasswordFocus: _confirmPasswordFocus,
          isResetFormValid: _isResetFormValid,
          hasMinLength: _hasMinLength,
          hasMixedCase: _hasMixedCase,
          hasNumber: _hasNumber,
          isPasswordMatching: _isPasswordMatching,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
          onSubmit: _submitResetPassword,
        );
    }
  }
}
