import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_haptics.dart';
import '../../data/models/user_model.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import 'change_password_dialog.dart';
import 'widgets/profile_account_security_section.dart';
import 'widgets/profile_actions.dart';
import 'widgets/profile_employment_location_section.dart';
import 'widgets/profile_header_banner.dart';
import 'widgets/profile_personal_info_section.dart';
import 'widgets/profile_preferences_section.dart';

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

  void _copyToClipboard(BuildContext context, String text, String label) {
    AppHaptics.light();
    Clipboard.setData(ClipboardData(text: text));
    ProfileActions.showCustomToast(context, '$label berhasil disalin');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final attendanceState = ref.watch(todayAttendanceProvider);
    final workLoc = attendanceState.data.value?.workLocation ?? user?.location;

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
              // 1. Header Banner with Avatar & User Info
              ProfileHeaderBanner(
                user: user,
                onAvatarEditTap: () =>
                    ProfileActions.showPhotoSourceSheet(context, ref),
              ),
              const SizedBox(height: 20),

              // Sections in horizontal padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // 2. Section: PENGATURAN AKUN & KEAMANAN
                    ProfileAccountSecuritySection(
                      phoneStr: phoneStr,
                      userEmail: userEmail,
                      onPhoneTap: () => ProfileActions.showEditPhoneBottomSheet(
                        context,
                        ref,
                        user?.phone,
                      ),
                      onChangePasswordTap: () =>
                          ChangePasswordDialog.show(context),
                      onCopy: (text, label) =>
                          _copyToClipboard(context, text, label),
                    ),
                    const SizedBox(height: 20),

                    // 3. Section: DATA KEPEGAWAIAN & LOKASI
                    ProfileEmploymentLocationSection(
                      employeeId: employeeId,
                      roleName: roleName,
                      officeName: officeName,
                      radiusStr: radiusStr,
                      joinedStr: joinedStr,
                      onCopy: (text, label) =>
                          _copyToClipboard(context, text, label),
                    ),
                    const SizedBox(height: 20),

                    // 4. Section: IDENTITAS PRIBADI
                    ProfilePersonalInfoSection(
                      nikStr: nikStr,
                      dobStr: dobStr,
                      onCopy: (text, label) =>
                          _copyToClipboard(context, text, label),
                    ),
                    const SizedBox(height: 16),

                    // 5. Section: Preferences (Notif, Theme, Version)
                    ProfilePreferencesSection(
                      onShowToast: (msg, {isError = false}) =>
                          ProfileActions.showCustomToast(
                        context,
                        msg,
                        isError: isError,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6. Logout Button
                    InkWell(
                      onTap: () => ProfileActions.showLogoutDialog(context, ref),
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
}
