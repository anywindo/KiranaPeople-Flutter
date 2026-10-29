import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/data/repositories/auth_repository.dart';
import 'package:kirana_people/features/auth/forgot_password_sheet.dart';

class MockAuthRepository extends AuthRepository {
  final Set<String> registeredEmails;
  final Map<String, String> validOtps;

  MockAuthRepository({
    this.registeredEmails = const {'registered@example.com'},
    this.validOtps = const {'registered@example.com': '123456'},
  });

  @override
  Future<String> requestForgotPasswordOtp(String email) async {
    if (!registeredEmails.contains(email)) {
      throw Exception('Email tidak terdaftar dalam sistem.');
    }
    return 'Kode OTP verifikasi telah dikirimkan ke email Anda.';
  }

  @override
  Future<String> verifyOtp({
    required String email,
    required String otp,
  }) async {
    if (!registeredEmails.contains(email)) {
      throw Exception('Email tidak terdaftar dalam sistem.');
    }
    if (validOtps[email] != otp) {
      throw Exception('Kode OTP yang Anda masukkan salah.');
    }
    return 'Kode OTP valid.';
  }

  @override
  Future<String> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (validOtps[email] != otp) {
      throw Exception('Kode OTP yang Anda masukkan salah.');
    }
    return 'Kata sandi Anda berhasil diperbarui. Silakan masuk kembali.';
  }
}

void main() {
  group('ForgotPasswordSheet Email & OTP Verification Gate Tests', () {
    testWidgets('unregistered email is blocked and cannot advance to OTP step', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ForgotPasswordSheet(
              initialEmail: 'random@example.com',
              repository: mockRepo,
            ),
          ),
        ),
      );
      await tester.pump();

      // Find the 'Kirim Kode OTP' button
      final sendOtpBtn = find.text('Kirim Kode OTP');
      expect(sendOtpBtn, findsOneWidget);

      await tester.tap(sendOtpBtn);
      await tester.pump();

      // Ensure error message is shown and sheet is still on email input step
      expect(find.text('Email tidak terdaftar dalam sistem.'), findsOneWidget);
      expect(find.text('Verifikasi Kode OTP'), findsNothing);
      expect(find.text('Kirim Kode OTP'), findsOneWidget);
    });

    testWidgets('registered email advances to OTP step', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ForgotPasswordSheet(
              initialEmail: 'registered@example.com',
              repository: mockRepo,
            ),
          ),
        ),
      );
      await tester.pump();

      final sendOtpBtn = find.text('Kirim Kode OTP');
      expect(sendOtpBtn, findsOneWidget);

      await tester.tap(sendOtpBtn);
      await tester.pump();

      // Ensure it successfully advances to OTP step
      expect(find.text('Verifikasi OTP'), findsOneWidget);
      expect(find.text('Kode OTP verifikasi telah dikirimkan ke email Anda.'), findsOneWidget);
    });

    testWidgets('wrong OTP is rejected and cannot advance to password reset step', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ForgotPasswordSheet(
              initialEmail: 'registered@example.com',
              repository: mockRepo,
            ),
          ),
        ),
      );
      await tester.pump();

      // Advance to OTP step
      await tester.tap(find.text('Kirim Kode OTP'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Verifikasi OTP'), findsOneWidget);

      // Enter incorrect OTP
      final otpField = find.byKey(const Key('otp_text_field'));
      await tester.enterText(otpField, '000000');
      await tester.pump();

      // Tap Lanjutkan
      final continueBtn = find.text('Lanjutkan');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Should show error and remain on OTP step
      expect(find.text('Kode OTP yang Anda masukkan salah.'), findsOneWidget);
      expect(find.text('Atur Kata Sandi Baru'), findsNothing);
    });

    testWidgets('correct OTP successfully advances to password reset step', (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ForgotPasswordSheet(
              initialEmail: 'registered@example.com',
              repository: mockRepo,
            ),
          ),
        ),
      );
      await tester.pump();

      // Advance to OTP step
      await tester.tap(find.text('Kirim Kode OTP'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Verifikasi OTP'), findsOneWidget);

      // Enter correct OTP
      final otpField = find.byKey(const Key('otp_text_field'));
      await tester.enterText(otpField, '123456');
      await tester.pump();

      // Tap Lanjutkan
      await tester.tap(find.text('Lanjutkan'));
      await tester.pump(const Duration(milliseconds: 300));

      // Should successfully advance to password reset step
      expect(find.text('Atur Kata Sandi Baru'), findsOneWidget);
      expect(find.text('Perbarui Kata Sandi'), findsOneWidget);
    });

    testWidgets('ambiguous backend message (Jika email Anda terdaftar...) is blocked from OTP step on UI', (tester) async {
      final mockRepo = AmbiguousMockAuthRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ForgotPasswordSheet(
              initialEmail: 'this@fake.email',
              repository: mockRepo,
            ),
          ),
        ),
      );
      await tester.pump();

      final sendOtpBtn = find.text('Kirim Kode OTP');
      expect(sendOtpBtn, findsOneWidget);

      await tester.tap(sendOtpBtn);
      await tester.pump();

      // Ensure error is shown on UI and it does NOT advance to OTP step
      expect(find.text('Email tidak terdaftar dalam sistem.'), findsOneWidget);
      expect(find.text('Verifikasi OTP'), findsNothing);
      expect(find.text('Kirim Kode OTP'), findsOneWidget);
    });
  });
}

class AmbiguousMockAuthRepository extends AuthRepository {
  @override
  Future<String> requestForgotPasswordOtp(String email) async {
    // Simulates legacy backend returning ambiguous anti-enumeration string
    return 'Jika email Anda terdaftar, instruksi reset kata sandi dan kode OTP telah dikirimkan ke email Anda.';
  }
}
