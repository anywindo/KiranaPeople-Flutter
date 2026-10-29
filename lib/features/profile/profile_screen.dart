import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/continuous_marquee_text.dart';
import '../../data/models/user_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'change_password_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _formatIndoDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final dt = DateTime.tryParse(raw);
    if (dt != null) {
      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }
    return raw;
  }

  String _getDisplayRole(UserModel? user) {
    if (user?.roles != null && user!.roles!.isNotEmpty) {
      final r = user.roles!.first;
      final lower = r.toLowerCase();
      if (lower == 'employee' || lower == 'karyawan') return 'Karyawan';
      if (lower == 'admin' || lower == 'administrator') return 'Administrator';
      if (lower == 'manager' || lower == 'manajer') return 'Manajer';
      return r;
    }
    return 'Karyawan';
  }

  void _showCustomToast(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: isError
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E222B).withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showCustomToast(context, '$label berhasil disalin');
  }

  void _showEnlargedPhotoDialog(
    BuildContext context,
    UserModel? user,
    String userName,
  ) {
    final avatarUrl = user?.fullAvatarUrl;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(ctx).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    minHeight: 250,
                    minWidth: double.infinity,
                  ),
                  color: Colors.black,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const SizedBox(
                              height: 300,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => SizedBox(
                              height: 300,
                              width: double.infinity,
                              child: _buildInitialAvatar(userName),
                            ),
                          )
                        : SizedBox(
                            height: 300,
                            width: double.infinity,
                            child: _buildInitialAvatar(userName),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPhotoSourceSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Foto Profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih foto baru dari galeri atau ambil langsung dengan kamera.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? const Color(0xFF332042)
                        : const Color(0xFFFFF1F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Buka Galeri Foto',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.textPrimaryColor,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: context.borderColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(context, ref, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? const Color(0xFF1E3A5F)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                title: Text(
                  'Ambil dengan Kamera',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.textPrimaryColor,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: context.borderColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(context, ref, ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (picked == null) return;

      final file = File(picked.path);
      if (!context.mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Konfirmasi Foto',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.file(
                  file,
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gunakan foto ini sebagai foto profil baru Anda?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Gunakan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) {
        if (source == ImageSource.camera) {
          try {
            if (file.existsSync()) file.deleteSync();
          } catch (_) {}
        }
        return;
      }

      try {
        final success = await ref
            .read(authProvider.notifier)
            .updateProfile(avatarFile: file);
        if (context.mounted) {
          if (success) {
            _showCustomToast(context, 'Foto profil berhasil diperbarui!');
          } else {
            final err =
                ref.read(authProvider).errorMessage ??
                'Gagal memperbarui foto profil.';
            _showCustomToast(context, err, isError: true);
          }
        }
      } finally {
        if (source == ImageSource.camera) {
          try {
            if (file.existsSync()) file.deleteSync();
          } catch (_) {}
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showCustomToast(context, 'Gagal memilih foto: $e', isError: true);
      }
    }
  }

  void _showEditPhoneBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String? currentPhone,
  ) {
    final phoneController = TextEditingController(text: currentPhone ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ubah Nomor Telepon',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Masukkan nomor telepon aktif untuk verifikasi dan kontak.',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                style: TextStyle(color: context.textPrimaryColor),
                decoration: InputDecoration(
                  hintText: '08xxxxxxxxxx',
                  hintStyle: TextStyle(color: context.textMutedColor),
                  prefixIcon: const Icon(
                    Icons.phone_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: context.surfaceSecondaryColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nomor telepon tidak boleh kosong';
                  }
                  final digits = val.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 9 || digits.length > 15) {
                    return 'Nomor harus terdiri dari 9 hingga 15 digit angka';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(ctx);
                      final success = await ref
                          .read(authProvider.notifier)
                          .updateProfile(phone: phoneController.text.trim());
                      if (context.mounted) {
                        if (success) {
                          _showCustomToast(
                            context,
                            'Nomor telepon berhasil diperbarui!',
                          );
                        } else {
                          final err =
                              ref.read(authProvider).errorMessage ??
                              'Gagal memperbarui nomor telepon.';
                          _showCustomToast(context, err, isError: true);
                        }
                      }
                    }
                  },
                  child: const Text(
                    'Simpan Nomor',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => phoneController.dispose());
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.borderColor),
        ),
        title: Text(
          'Konfirmasi Keluar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: context.textPrimaryColor,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(
                context,
                rootNavigator: true,
              ).popUntil((route) => route.isFirst);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text(
              'Keluar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeModeSheet(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pilih Tema Tampilan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sesuaikan tampilan aplikasi dengan kenyamanan mata Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 20),
              _buildThemeOptionTile(
                context,
                title: 'Otomatis (Ikuti Sistem)',
                subtitle: 'Menyesuaikan otomatis dengan tema perangkat',
                icon: Icons.brightness_auto_rounded,
                iconBg: context.isDarkMode
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF3B82F6),
                isSelected: currentMode == ThemeMode.system,
                onTap: () {
                  ref
                      .read(themeProvider.notifier)
                      .setThemeMode(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
              _buildThemeOptionTile(
                context,
                title: 'Mode Terang (Light)',
                subtitle: 'Tampilan bersih dan kontras cerah',
                icon: Icons.light_mode_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFD97706),
                isSelected: currentMode == ThemeMode.light,
                onTap: () {
                  ref
                      .read(themeProvider.notifier)
                      .setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
              _buildThemeOptionTile(
                context,
                title: 'Mode Gelap (Dark)',
                subtitle: 'Nuansa gelap elegan yang nyaman di mata',
                icon: Icons.dark_mode_rounded,
                iconBg: const Color(0xFF2E1065),
                iconColor: const Color(0xFFA855F7),
                isSelected: currentMode == ThemeMode.dark,
                onTap: () {
                  ref.read(themeProvider.notifier).setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOptionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? AppColors.primary : context.borderColor,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      tileColor: isSelected
          ? AppColors.primary.withValues(
              alpha: context.isDarkMode ? 0.15 : 0.06,
            )
          : context.surfaceColor,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: context.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 22,
            )
          : Icon(
              Icons.radio_button_unchecked_rounded,
              color: context.borderColor,
              size: 22,
            ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final attendanceState = ref.watch(todayAttendanceProvider);
    final workLoc = attendanceState.data.value?.workLocation ?? user?.location;

    final userName = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user.name.trim()
        : (user?.employeeId ?? '-');
    final userEmail = user?.email ?? '-';
    final employeeId = user?.employeeId ?? '-';
    final roleName = _getDisplayRole(user);
    final officeName = workLoc?.name ?? '-';
    final radiusStr = workLoc?.radius != null
        ? '${workLoc!.radius.round()} meter'
        : '-';
    final joinedStr = user?.joinedAt != null
        ? _formatIndoDate(user!.joinedAt)
        : '-';
    final nikStr = user?.nik ?? '-';
    final dobStr = user?.dob != null ? _formatIndoDate(user!.dob) : '-';
    final phoneStr = (user?.phone != null && user!.phone!.trim().isNotEmpty)
        ? user.phone!.trim()
        : 'Belum diatur';

    final username =
        (user?.employeeId != null && user!.employeeId!.trim().isNotEmpty)
            ? user.employeeId!.trim()
            : '';
    final userHandle = username;

    final topPadding = MediaQuery.of(context).padding.top;
    final bannerHeight = 125.0 + topPadding;
    const avatarDiameter = 96.0;
    const avatarHalf = avatarDiameter / 2; // 48.0
    final headerTotalHeight = bannerHeight + avatarHalf;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Banner with Avatar
              SizedBox(
                height: headerTotalHeight,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Banner Image
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: bannerHeight,
                      child: Image.asset(
                        'assets/images/header-bar.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFF21A4),
                                  Color(0xFF7C3AED),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Avatar overlapping the banner bottom (Left aligned)
                    Positioned(
                      left: 20,
                      top: bannerHeight - avatarHalf,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomRight,
                        children: [
                          // 1. Tapping avatar enlarges the photo
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _showEnlargedPhotoDialog(
                              context,
                              user,
                              userName,
                            ),
                            child: Container(
                              width: avatarDiameter,
                              height: avatarDiameter,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: context.isDarkMode
                                      ? context.scaffoldBg
                                      : Colors.white,
                                  width: 3.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child:
                                    (user?.fullAvatarUrl != null &&
                                            user!.fullAvatarUrl!.isNotEmpty)
                                        ? CachedNetworkImage(
                                            imageUrl: user.fullAvatarUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                              color:
                                                  context.surfaceSecondaryColor,
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    _buildInitialAvatar(
                                                      userName,
                                                    ),
                                          )
                                        : _buildInitialAvatar(userName),
                              ),
                            ),
                          ),

                          // 2. Tapping camera badge opens photo source modal
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _showPhotoSourceSheet(context, ref),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF2D75),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.isDarkMode
                                        ? context.scaffoldBg
                                        : Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Clearance for overlapping avatar
              const SizedBox(height: 12),

              // User Name & Handle (Left aligned as per reference)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimaryColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (userHandle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        userHandle,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Sections in horizontal padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // 2. Section: PENGATURAN AKUN & KEAMANAN
                    _buildSectionHeader(context, 'PENGATURAN AKUN & KEAMANAN'),
                    _buildCardGroup(context, [
                      _buildRow(
                        context,
                        iconBg: context.isDarkMode
                            ? const Color(0xFF3B1524)
                            : const Color(0xFFFFF1F5),
                        icon: Icons.phone_rounded,
                        iconColor: AppColors.primary,
                        title: 'Nomor Telepon',
                        onTap: () => _showEditPhoneBottomSheet(
                          context,
                          ref,
                          user?.phone,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              phoneStr,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: context.borderColor,
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: context.dividerColor,
                      ),
                      _buildRow(
                        context,
                        iconBg: context.isDarkMode
                            ? const Color(0xFF3B1524)
                            : const Color(0xFFFFF1F5),
                        icon: Icons.shield_outlined,
                        iconColor: AppColors.primary,
                        title: 'Kata Sandi',
                        onTap: () => ChangePasswordDialog.show(context),
                        trailing: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ubah Sandi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF2D75),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: Color(0xFFFF2D75),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: context.dividerColor,
                      ),
                      _buildRow(
                        context,
                        iconBg: context.isDarkMode
                            ? const Color(0xFF3B1524)
                            : const Color(0xFFFFF1F5),
                        icon: Icons.mail_rounded,
                        iconColor: AppColors.primary,
                        title: 'Email',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(
                                userEmail,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () =>
                                  _copyToClipboard(context, userEmail, 'Email'),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: context.textMutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // 3. Section: DATA KEPEGAWAIAN & LOKASI
                    _buildSectionHeader(context, 'DATA KEPEGAWAIAN & LOKASI'),
                    _buildCardGroup(context, [
                      _buildRow(
                        context,
                        iconBg: context.isDarkMode
                            ? const Color(0xFF3B1524)
                            : const Color(0xFFFFF1F5),
                        icon: Icons.badge_rounded,
                        iconColor: AppColors.primary,
                        title: 'ID Karyawan',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              employeeId,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _copyToClipboard(
                                context,
                                employeeId,
                                'ID Karyawan',
                              ),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: context.textMutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: context.dividerColor,
                      ),
                      _buildRow(
                        context,
                        iconBg: context.isDarkMode
                            ? const Color(0xFF3B1524)
                            : const Color(0xFFFFF1F5),
                        icon: Icons.work_rounded,
                        iconColor: AppColors.primary,
                        title: 'Jabatan',
                        trailing: Text(
                          roleName,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: context.dividerColor,
                      ),
                      _buildRow(
                        context,
                        iconBg: context.isDarkMode
                            ? const Color(0xFF3B1524)
                            : const Color(0xFFFFF1F5),
                        icon: Icons.apartment_rounded,
                        iconColor: AppColors.primary,
                        title: 'Lokasi Kantor',
                        isTrailingExpanded: true,
                        trailing: ContinuousMarqueeText(
                          text: officeName,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: context.dividerColor,
                      ),
                      _buildRow(
                        context,
                        iconBg: context.isDarkMode
                            ? const Color(0xFF3B1524)
                            : const Color(0xFFFFF1F5),
                        icon: Icons.near_me_rounded,
                        iconColor: AppColors.primary,
                        title: 'Radius Presensi',
                        trailing: Text(
                          radiusStr,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: context.dividerColor,
                      ),
                      _buildRow(
                        context,
                        iconBg: context.isDarkMode
                            ? const Color(0xFF3B1524)
                            : const Color(0xFFFFF1F5),
                        icon: Icons.calendar_month_rounded,
                        iconColor: AppColors.primary,
                        title: 'Bergabung',
                        trailing: Text(
                          joinedStr,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // 4. Section: IDENTITAS PRIBADI
                    _buildSectionHeader(context, 'IDENTITAS PRIBADI'),
                    _buildCardGroup(context, [
                      _buildRow(
                        context,
                        iconBg: context.isDarkMode
                            ? const Color(0xFF3B1524)
                            : const Color(0xFFFFF1F5),
                        icon: Icons.credit_card_rounded,
                        iconColor: AppColors.primary,
                        title: 'NIK',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              nikStr,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () =>
                                  _copyToClipboard(context, nikStr, 'NIK'),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: context.textMutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: context.dividerColor,
                      ),
                      _buildRow(
                        context,
                        iconBg: context.isDarkMode
                            ? const Color(0xFF3B1524)
                            : const Color(0xFFFFF1F5),
                        icon: Icons.card_giftcard_rounded,
                        iconColor: AppColors.primary,
                        title: 'Tanggal Lahir',
                        trailing: Text(
                          dobStr,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // 5. Section: Tampilan & Versi Aplikasi Card
                    _buildCardGroup(context, [
                      _buildRow(
                        context,
                        iconBg: context.isDarkMode
                            ? const Color(0xFF3B1524)
                            : const Color(0xFFFFF1F5),
                        icon: Icons.palette_rounded,
                        iconColor: AppColors.primary,
                        title: 'Tema Tampilan',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Consumer(
                              builder: (context, ref, _) {
                                final mode = ref.watch(themeProvider);
                                final label = switch (mode) {
                                  ThemeMode.light => 'Terang',
                                  ThemeMode.dark => 'Gelap',
                                  ThemeMode.system => 'Sistem',
                                };
                                return Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: context.textSecondaryColor,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: context.textMutedColor,
                            ),
                          ],
                        ),
                        onTap: () => _showThemeModeSheet(context, ref),
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color: context.dividerColor,
                      ),
                      _buildRow(
                        context,
                        iconBg: context.isDarkMode
                            ? const Color(0xFF283344)
                            : const Color(0xFFF3F4F6),
                        icon: Icons.info_rounded,
                        iconColor: context.textSecondaryColor,
                        title: 'Versi Aplikasi',
                        trailing: Text(
                          '1.0.1 (Build 1)',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // 6. Logout Button (Matches Screenshot 2)
                    InkWell(
                      onTap: () => _showLogoutDialog(context, ref),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? const Color(0xFF3B151E)
                              : const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: context.isDarkMode
                                ? const Color(0xFF4C1D24)
                                : const Color(0xFFFFE4E6),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Keluar dari Akun',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: context.textMutedColor,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Widget _buildCardGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.25 : 0.02,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
    bool isTrailingExpanded = false,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(width: 12),
          if (isTrailingExpanded)
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: trailing,
              ),
            )
          else ...[
            const Spacer(),
            trailing,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      );
    }
    return content;
  }

  Widget _buildInitialAvatar(String name) {
    String initials = 'UT';
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      initials = name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }
    return Container(
      color: const Color(0xFF4F46E5),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
