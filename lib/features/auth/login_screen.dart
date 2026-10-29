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

class _IslamicWorkQuote {
  final String quote;
  final String source;
  final String topic;

  const _IslamicWorkQuote({
    required this.quote,
    required this.source,
    required this.topic,
  });
}

const List<_IslamicWorkQuote> _islamicQuotes = [
  _IslamicWorkQuote(
    quote:
        'Sesungguhnya Allah mencintai seorang hamba yang apabila bekerja, ia melakukannya dengan itqan (sungguh-sungguh, rapi, dan profesional).',
    source: 'HR. Al-Baihaqi & Ath-Thabrani',
    topic: 'Profesionalisme',
  ),
  _IslamicWorkQuote(
    quote:
        'Dan katakanlah, "Bekerjalah kamu, maka Allah dan Rasul-Nya serta orang-orang mukmin akan melihat pekerjaanmu itu."',
    source: 'QS. At-Taubah: 105',
    topic: 'Etos Kerja',
  ),
  _IslamicWorkQuote(
    quote:
        'Tidaklah seseorang memakan suatu makanan yang lebih baik daripada makanan dari hasil usaha dan keringatnya sendiri.',
    source: 'HR. Bukhari no. 2072',
    topic: 'Kemandirian',
  ),
  _IslamicWorkQuote(
    quote:
        'Barangsiapa di sore hari merasa lelah karena bekerja mencari rezeki yang halal, maka pada saat itu diampuni dosa-dosanya.',
    source: 'HR. Ath-Thabrani',
    topic: 'Penggugur Dosa',
  ),
  _IslamicWorkQuote(
    quote:
        'Mencari rezeki yang halal adalah kewajiban setelah kewajiban pokok beribadah.',
    source: 'HR. Al-Baihaqi & Ath-Thabrani',
    topic: 'Nafkah Halal',
  ),
  _IslamicWorkQuote(
    quote:
        'Maka apabila engkau telah selesai (dari suatu urusan), tetaplah bekerja keras (untuk urusan yang lain), dan hanya kepada Tuhanmulah engkau berharap.',
    source: 'QS. Al-Insyirah: 7-8',
    topic: 'Pantang Menyerah',
  ),
  _IslamicWorkQuote(
    quote:
        'Bersemangatlah terhadap hal-hal yang bermanfaat bagimu, mohonlah pertolongan kepada Allah, dan janganlah merasa lemah.',
    source: 'HR. Muslim no. 2664',
    topic: 'Optimisme',
  ),
  _IslamicWorkQuote(
    quote:
        'Sesungguhnya Allah suka melihat hamba-Nya bersungguh-sungguh dalam mencari nafkah yang halal.',
    source: 'HR. Ad-Dailami',
    topic: 'Keberkahan',
  ),
];

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
    _quoteIndex = DateTime.now().day % _islamicQuotes.length;
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
    final isDark = context.isDarkMode;

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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Kirana Logo Asset (logoKiranaSquare.jpeg)
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
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
                      const SizedBox(height: 24),

                      // Title & Subtitle
                      Text(
                        'Masuk ke Akun Anda',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.textPrimaryColor,
                              letterSpacing: -0.3,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Silakan masukkan identitas dan kata sandi Anda',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.textSecondaryColor,
                            ),
                      ),
                      const SizedBox(height: 28),

                      // Material 3 Form Card Surface
                      Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        color: context.surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(color: context.borderColor),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Error message banner if any
                              if (authState.errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.error.withValues(alpha: 0.30),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          authState.errorMessage!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                              ],

                              // Field 1: Email / ID Karyawan / NIK (M3 Outlined TextField)
                              TextField(
                                controller: _identifierController,
                                focusNode: _identifierFocus,
                                cursorColor: AppColors.primary,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
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
                                  labelText: 'Email / ID Karyawan / NIK',
                                  hintText: 'Masukkan email, ID, atau NIK',
                                  labelStyle: TextStyle(
                                    color: _identifierFocus.hasFocus
                                        ? AppColors.primary
                                        : context.textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.badge_outlined,
                                    size: 20,
                                    color: _identifierFocus.hasFocus
                                        ? AppColors.primary
                                        : context.textMutedColor,
                                  ),
                                  suffixIcon: _identifierController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.cancel_rounded,
                                            size: 18,
                                            color: context.textMutedColor,
                                          ),
                                          onPressed: () {
                                            _identifierController.clear();
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: isDark
                                      ? AppColors.darkBackground.withValues(alpha: 0.5)
                                      : AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: context.borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: context.borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Field 2: Kata Sandi (M3 Outlined TextField)
                              TextField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: !_isPasswordVisible,
                                cursorColor: AppColors.primary,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: context.textPrimaryColor,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Kata Sandi',
                                  hintText: 'Masukkan kata sandi',
                                  labelStyle: TextStyle(
                                    color: _passwordFocus.hasFocus
                                        ? AppColors.primary
                                        : context.textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                    color: _passwordFocus.hasFocus
                                        ? AppColors.primary
                                        : context.textMutedColor,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: _isPasswordVisible
                                        ? 'Sembunyikan sandi'
                                        : 'Tampilkan sandi',
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: context.textMutedColor,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? AppColors.darkBackground.withValues(alpha: 0.5)
                                      : AppColors.background,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: context.borderColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: context.borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Options Row: M3 Checkbox (Ingat Saya) + M3 TextButton (Lupa Kata Sandi?)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              activeColor: AppColors.primary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              side: BorderSide(
                                                color: context.textMutedColor,
                                                width: 1.5,
                                              ),
                                              onChanged: (val) {
                                                setState(() {
                                                  _rememberMe = val ?? true;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Ingat Saya',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                              color: context.textPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Lupa Kata Sandi?',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Material 3 FilledButton (Masuk)
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: _isFormValid && !authState.isLoading
                                      ? _submit
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: isDark
                                        ? AppColors.darkSurfaceSecondary
                                        : const Color(0xFFE5E7EB),
                                    disabledForegroundColor: isDark
                                        ? AppColors.darkTextMuted
                                        : const Color(0xFF9CA3AF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: authState.isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Masuk'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Islamic Motivation Card
                      _buildIslamicMotivationCard(context, isDark),

                      const Spacer(),
                      const SizedBox(height: 24),

                      // Version section
                      Text(
                        'Versi 1.0.1 (Build 1)',
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
    );
  }

  void _nextQuote() {
    setState(() {
      _quoteIndex = (_quoteIndex + 1) % _islamicQuotes.length;
    });
  }

  Widget _buildIslamicMotivationCard(BuildContext context, bool isDark) {
    final quote = _islamicQuotes[_quoteIndex];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? context.borderColor : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _nextQuote,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: Column(
                key: ValueKey<int>(_quoteIndex),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '“${quote.quote}”',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      quote.source,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.9)
                            : AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
