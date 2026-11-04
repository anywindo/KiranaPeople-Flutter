import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/features/profile/widgets/dialogs/logout_confirm_dialog.dart';
import 'package:kirana_people/features/profile/widgets/dialogs/photo_confirm_dialog.dart';
import 'package:kirana_people/features/profile/widgets/sheets/edit_phone_sheet.dart';
import 'package:kirana_people/features/profile/widgets/sheets/notification_test_sheet.dart';
import 'package:kirana_people/features/profile/widgets/sheets/photo_source_sheet.dart';
import 'package:kirana_people/features/profile/widgets/sheets/theme_mode_sheet.dart';

void main() {
  group('Profile Dialogs & Sheets Tests', () {
    testWidgets('LogoutConfirmDialog renders title, message, and action buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => LogoutConfirmDialog.show(context, ref),
                    child: const Text('Open Logout Dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Logout Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Keluar'), findsOneWidget);
      expect(
        find.text('Apakah Anda yakin ingin keluar dari akun ini?'),
        findsOneWidget,
      );
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi Keluar'), findsNothing);
    });

    testWidgets('PhotoConfirmDialog renders confirm prompt and actions', (tester) async {
      final dummyFile = File('dummy.jpg');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => PhotoConfirmDialog.show(context, dummyFile),
                child: const Text('Open Photo Confirm'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Photo Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Foto'), findsOneWidget);
      expect(
        find.text('Gunakan foto ini sebagai foto profil baru Anda?'),
        findsOneWidget,
      );
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Gunakan'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi Foto'), findsNothing);
    });

    testWidgets('PhotoSourceSheet renders gallery and camera options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => PhotoSourceSheet.show(context, ref),
                    child: const Text('Open Photo Sheet'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Photo Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Foto Profil'), findsOneWidget);
      expect(find.text('Buka Galeri Foto'), findsOneWidget);
      expect(find.text('Ambil dengan Kamera'), findsOneWidget);
    });

    testWidgets('EditPhoneSheet renders input field, validation, and submit button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => EditPhoneSheet.show(context, ref, '08123456789'),
                    child: const Text('Open Edit Phone Sheet'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Edit Phone Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Ubah Nomor Telepon'), findsOneWidget);
      expect(find.text('08123456789'), findsOneWidget);
      expect(find.text('Simpan Nomor'), findsOneWidget);

      // Clear input and test empty validation
      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Simpan Nomor'));
      await tester.pumpAndSettle();

      expect(find.text('Nomor telepon tidak boleh kosong'), findsOneWidget);

      // Enter short digits and test validation
      await tester.enterText(find.byType(TextFormField), '1234');
      await tester.tap(find.text('Simpan Nomor'));
      await tester.pumpAndSettle();

      expect(find.text('Nomor harus terdiri dari 9 hingga 15 digit angka'), findsOneWidget);
    });

    testWidgets('ThemeModeSheet renders all theme options', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => ThemeModeSheet.show(context, ref),
                    child: const Text('Open Theme Sheet'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Theme Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Tema Tampilan'), findsOneWidget);
      expect(find.text('Otomatis (Ikuti Sistem)'), findsOneWidget);
      expect(find.text('Mode Terang (Light)'), findsOneWidget);
      expect(find.text('Mode Gelap (Dark)'), findsOneWidget);

      await tester.tap(find.text('Mode Gelap (Dark)'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih Tema Tampilan'), findsNothing);
    });

    testWidgets('NotificationTestSheet renders test options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => NotificationTestSheet.show(context),
                child: const Text('Open Notification Test Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Notification Test Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Uji Coba Suara & Notifikasi'), findsOneWidget);
      expect(find.text('Uji Pengingat Jadwal (5 Detik)'), findsOneWidget);
      expect(find.text('Uji Pengingat Presensi (Langsung)'), findsOneWidget);
      expect(find.text('Presensi Berhasil'), findsOneWidget);
      expect(find.text('Presensi Gagal (Fallback)'), findsOneWidget);
    });
  });
}

