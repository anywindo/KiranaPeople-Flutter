import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
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
        'Desember'
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

  void _showCustomToast(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
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

  void _showPhotoSourceSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Foto Profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih foto baru dari galeri atau ambil langsung dengan kamera.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Buka Galeri Foto',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFC7C7CC),
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
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Ambil dengan Kamera',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFC7C7CC),
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

      if (confirm != true) return;

      final success = await ref.read(authProvider.notifier).updateProfile(
            avatarFile: file,
          );
      if (context.mounted) {
        if (success) {
          _showCustomToast(context, 'Foto profil berhasil diperbarui!');
        } else {
          final err = ref.read(authProvider).errorMessage ??
              'Gagal memperbarui foto profil.';
          _showCustomToast(context, err, isError: true);
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
      backgroundColor: Colors.white,
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
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ubah Nomor Telepon',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Masukkan nomor telepon aktif untuk verifikasi dan kontak.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '08xxxxxxxxxx',
                  prefixIcon: const Icon(
                    Icons.phone_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
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
                      final success =
                          await ref.read(authProvider.notifier).updateProfile(
                                phone: phoneController.text.trim(),
                              );
                      if (context.mounted) {
                        if (success) {
                          _showCustomToast(
                            context,
                            'Nomor telepon berhasil diperbarui!',
                          );
                        } else {
                          final err = ref.read(authProvider).errorMessage ??
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Konfirmasi Keluar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
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
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final attendanceState = ref.watch(todayAttendanceProvider);
    final workLoc =
        attendanceState.data.value?.workLocation ?? user?.location;

    final userName = user?.name ?? 'User Testing';
    final userEmail = user?.email ?? 'balmacedam...r@gmail.com';
    final employeeId = user?.employeeId ?? 'TEST';
    final roleName = _getDisplayRole(user);
    final isActive = user?.isActive ?? true;
    final officeName =
        workLoc?.name ?? 'Kantor Utama (Tersono, Batang)';
    final radiusStr = '${workLoc?.radius.round() ?? 100} meter';
    final joinedStr = user?.joinedAt != null
        ? _formatIndoDate(user!.joinedAt)
        : '15 Oktober 2026';
    final nikStr = user?.nik ?? '1234567890123456';
    final dobStr = user?.dob != null
        ? _formatIndoDate(user!.dob)
        : '1 Januari 2000';
    final phoneStr = (user?.phone != null && user!.phone!.isNotEmpty)
        ? user.phone!
        : 'Belum diatur';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7FA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profil',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1C1E),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 40),
        child: Column(
          children: [
            // 1. Profile Avatar & Badges Header (Matches Screenshot 1)
            Center(
              child: Column(
                children: [
                  // Circular Avatar with Camera Badge
                  GestureDetector(
                    onTap: () => _showPhotoSourceSheet(context, ref),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: (user?.fullAvatarUrl != null &&
                                    user!.fullAvatarUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: user.fullAvatarUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: const Color(0xFFE5E7EB),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        _buildInitialAvatar(userName),
                                  )
                                : _buildInitialAvatar(userName),
                          ),
                        ),
                        // Camera Icon Badge
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF2D75),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // User Name
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Badges: Karyawan & Aktif
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          roleName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF2D75),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Aktif' : 'Non-Aktif',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Employee ID Subtitle
                  Text(
                    employeeId,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8E8E93),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Section: PENGATURAN AKUN & KEAMANAN
            _buildSectionHeader('PENGATURAN AKUN & KEAMANAN'),
            _buildCardGroup([
              _buildRow(
                iconBg: const Color(0xFFE0F2FE),
                icon: Icons.phone_rounded,
                iconColor: const Color(0xFF0284C7),
                title: 'Nomor Telepon',
                onTap: () => _showEditPhoneBottomSheet(context, ref, user?.phone),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      phoneStr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFFC7C7CC),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF2F2F7)),
              _buildRow(
                iconBg: const Color(0xFFF3E8FF),
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF9333EA),
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
              const Divider(height: 1, indent: 56, color: Color(0xFFF2F2F7)),
              _buildRow(
                iconBg: const Color(0xFFFEF3C7),
                icon: Icons.mail_rounded,
                iconColor: const Color(0xFFD97706),
                title: 'Email',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        userEmail,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _copyToClipboard(context, userEmail, 'Email'),
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // 3. Section: DATA KEPEGAWAIAN & LOKASI
            _buildSectionHeader('DATA KEPEGAWAIAN & LOKASI'),
            _buildCardGroup([
              _buildRow(
                iconBg: const Color(0xFFFFE4E6),
                icon: Icons.badge_rounded,
                iconColor: const Color(0xFFFF2D75),
                title: 'ID Karyawan',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      employeeId,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () =>
                          _copyToClipboard(context, employeeId, 'ID Karyawan'),
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF2F2F7)),
              _buildRow(
                iconBg: const Color(0xFFD1FAE5),
                icon: Icons.work_rounded,
                iconColor: const Color(0xFF059669),
                title: 'Jabatan',
                trailing: Text(
                  roleName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF2F2F7)),
              _buildRow(
                iconBg: const Color(0xFFDBEAFE),
                icon: Icons.apartment_rounded,
                iconColor: const Color(0xFF2563EB),
                title: 'Lokasi Kantor',
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    officeName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF2F2F7)),
              _buildRow(
                iconBg: const Color(0xFFCCFBF1),
                icon: Icons.near_me_rounded,
                iconColor: const Color(0xFF0D9488),
                title: 'Radius Presensi',
                trailing: Text(
                  radiusStr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF2F2F7)),
              _buildRow(
                iconBg: const Color(0xFFFFE4E6),
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFFFF2D75),
                title: 'Bergabung',
                trailing: Text(
                  joinedStr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // 4. Section: IDENTITAS PRIBADI
            _buildSectionHeader('IDENTITAS PRIBADI'),
            _buildCardGroup([
              _buildRow(
                iconBg: const Color(0xFFE0E7FF),
                icon: Icons.credit_card_rounded,
                iconColor: const Color(0xFF4F46E5),
                title: 'NIK',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nikStr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _copyToClipboard(context, nikStr, 'NIK'),
                      child: const Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF2F2F7)),
              _buildRow(
                iconBg: const Color(0xFFFFE4E6),
                icon: Icons.card_giftcard_rounded,
                iconColor: const Color(0xFFFF2D75),
                title: 'Tanggal Lahir',
                trailing: Text(
                  dobStr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // 5. Section: Versi Aplikasi Card
            _buildCardGroup([
              _buildRow(
                iconBg: const Color(0xFFF3F4F6),
                icon: Icons.info_rounded,
                iconColor: const Color(0xFF6B7280),
                title: 'Versi Aplikasi',
                trailing: const Text(
                  '1.0.0 (Build 1)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
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
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(14),
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8E8E93),
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2F2F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildRow({
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          trailing,
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
