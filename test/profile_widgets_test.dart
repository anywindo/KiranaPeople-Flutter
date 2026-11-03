import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/data/models/user_model.dart';
import 'package:kirana_people/features/profile/widgets/profile_account_security_section.dart';
import 'package:kirana_people/features/profile/widgets/profile_card_group.dart';
import 'package:kirana_people/features/profile/widgets/profile_employment_location_section.dart';
import 'package:kirana_people/features/profile/widgets/profile_header_banner.dart';
import 'package:kirana_people/features/profile/widgets/profile_personal_info_section.dart';
import 'package:kirana_people/features/profile/widgets/profile_preferences_section.dart';

void main() {
  group('Profile Sub-Widgets Tests', () {
    testWidgets('ProfileCardGroup and ProfileRowItem render properly', (tester) async {
      bool itemTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileCardGroup(
              children: [
                ProfileRowItem(
                  iconBg: Colors.blue,
                  icon: Icons.person,
                  iconColor: Colors.white,
                  title: 'Test Row',
                  trailing: const Text('Trailing Text'),
                  onTap: () => itemTapped = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Row'), findsOneWidget);
      expect(find.text('Trailing Text'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);

      await tester.tap(find.text('Test Row'));
      await tester.pump();

      expect(itemTapped, isTrue);
    });

    testWidgets('ProfileHeaderBanner renders user name and employee ID handle', (tester) async {
      bool avatarEditTapped = false;
      final user = UserModel(
        id: 1,
        name: 'Budi Santoso',
        employeeId: 'KTI-001',
        email: 'budi@kirana.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileHeaderBanner(
                user: user,
                onAvatarEditTap: () => avatarEditTapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('KTI-001'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pump();

      expect(avatarEditTapped, isTrue);
    });

    testWidgets('ProfileAccountSecuritySection renders details and triggers callbacks', (tester) async {
      bool phoneTapped = false;
      bool changePasswordTapped = false;
      String? copiedLabel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileAccountSecuritySection(
              phoneStr: '08123456789',
              userEmail: 'budi@kirana.com',
              onPhoneTap: () => phoneTapped = true,
              onChangePasswordTap: () => changePasswordTapped = true,
              onCopy: (text, label) => copiedLabel = label,
            ),
          ),
        ),
      );

      expect(find.text('PENGATURAN AKUN & KEAMANAN'), findsOneWidget);
      expect(find.text('Nomor Telepon'), findsOneWidget);
      expect(find.text('08123456789'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Ubah Sandi'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('budi@kirana.com'), findsOneWidget);

      await tester.tap(find.text('Nomor Telepon'));
      await tester.pump();
      expect(phoneTapped, isTrue);

      await tester.tap(find.text('Ubah Sandi'));
      await tester.pump();
      expect(changePasswordTapped, isTrue);

      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pump();
      expect(copiedLabel, equals('Email'));
    });

    testWidgets('ProfileEmploymentLocationSection renders employment details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileEmploymentLocationSection(
              employeeId: 'KTI-001',
              roleName: 'Karyawan',
              officeName: 'Kantor Pusat',
              radiusStr: '100 meter',
              joinedStr: '1 Januari 2024',
              onCopy: (text, label) {},
            ),
          ),
        ),
      );

      expect(find.text('DATA KEPEGAWAIAN & LOKASI'), findsOneWidget);
      expect(find.text('ID Karyawan'), findsOneWidget);
      expect(find.text('KTI-001'), findsOneWidget);
      expect(find.text('Jabatan'), findsOneWidget);
      expect(find.text('Karyawan'), findsOneWidget);
      expect(find.text('Lokasi Kantor'), findsOneWidget);
      expect(find.text('Kantor Pusat'), findsOneWidget);
      expect(find.text('Radius Presensi'), findsOneWidget);
      expect(find.text('100 meter'), findsOneWidget);
      expect(find.text('Bergabung'), findsOneWidget);
      expect(find.text('1 Januari 2024'), findsOneWidget);
    });

    testWidgets('ProfilePersonalInfoSection renders NIK and DOB', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfilePersonalInfoSection(
              nikStr: '33250123456789',
              dobStr: '15 Mei 1995',
              onCopy: (text, label) {},
            ),
          ),
        ),
      );

      expect(find.text('IDENTITAS PRIBADI'), findsOneWidget);
      expect(find.text('NIK'), findsOneWidget);
      expect(find.text('33250123456789'), findsOneWidget);
      expect(find.text('Tanggal Lahir'), findsOneWidget);
      expect(find.text('15 Mei 1995'), findsOneWidget);
    });

    testWidgets('ProfilePreferencesSection renders notif toggle, theme row, and version', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProfilePreferencesSection(
                onShowToast: (_, {isError = false}) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Pengingat Presensi'), findsOneWidget);
      expect(find.text('Tema Tampilan'), findsOneWidget);
      expect(find.text('Kebijakan Privasi'), findsOneWidget);
      expect(find.text('Versi Aplikasi'), findsOneWidget);
    });
  });
}

