import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/data/models/user_model.dart';
import 'package:kirana_people/features/auth/widgets/forgot_password_stepper_header.dart';
import 'package:kirana_people/features/auth/widgets/forgot_password_success_dialog.dart';
import 'package:kirana_people/features/onboarding/widgets/onboarding_logout_dialog.dart';
import 'package:kirana_people/features/onboarding/widgets/onboarding_password_header.dart';
import 'package:kirana_people/features/onboarding/widgets/onboarding_password_requirements.dart';
import 'package:kirana_people/features/onboarding/widgets/onboarding_policy_agreement.dart';

void main() {
  group('Auth & Onboarding Sub-Widgets Tests (Paket D)', () {
    testWidgets('ForgotPasswordStepperHeader renders title and actions', (tester) async {
      bool backTapped = false;
      bool closeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ForgotPasswordStepperHeader(
              title: 'Verifikasi OTP',
              showBackButton: true,
              onBack: () => backTapped = true,
              onClose: () => closeTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Verifikasi OTP'), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget);

      await tester.tap(find.text('Kembali'));
      await tester.pump();
      expect(backTapped, isTrue);

      await tester.tap(find.text('Tutup'));
      await tester.pump();
      expect(closeTapped, isTrue);
    });

    testWidgets('ForgotPasswordSuccessDialog renders and triggers login callback', (tester) async {
      bool loginTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ForgotPasswordSuccessDialog.show(
                  context,
                  email: 'test@kirana.com',
                  message: 'Berhasil direset!',
                  onLoginNow: () => loginTapped = true,
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Berhasil'), findsOneWidget);
      expect(find.text('Berhasil direset!'), findsOneWidget);
      expect(find.text('Masuk Sekarang'), findsOneWidget);

      await tester.tap(find.text('Masuk Sekarang'));
      await tester.pumpAndSettle();
      expect(loginTapped, isTrue);
    });

    testWidgets('OnboardingPasswordHeader renders user greeting', (tester) async {
      final user = UserModel(
        id: 1,
        name: 'Ahmad Fauzi',
        email: 'fauzi@kirana.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnboardingPasswordHeader(user: user),
          ),
        ),
      );

      expect(find.text('Aktivasi Kata Sandi'), findsOneWidget);
      expect(find.textContaining('Halo Ahmad Fauzi'), findsOneWidget);
      expect(find.byIcon(Icons.key_rounded), findsOneWidget);
    });

    testWidgets('OnboardingPasswordRequirements updates checklist icons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingPasswordRequirements(
              hasMinLength: true,
              hasMixedCase: false,
              hasNumber: true,
              isMatching: false,
            ),
          ),
        ),
      );

      expect(find.text('Minimal 8 karakter'), findsOneWidget);
      expect(find.text('Kombinasi huruf besar & huruf kecil'), findsOneWidget);
      expect(find.text('Mengandung minimal 1 angka'), findsOneWidget);
      expect(find.text('Konfirmasi kata sandi cocok'), findsOneWidget);

      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.circle_outlined), findsNWidgets(2));
    });

    testWidgets('OnboardingLogoutDialog renders and triggers logout action', (tester) async {
      bool logoutTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => OnboardingLogoutDialog.show(
                  context,
                  onConfirmLogout: () => logoutTapped = true,
                ),
                child: const Text('Show Logout Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Logout Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Batalkan Aktivasi?'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);

      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();
      expect(logoutTapped, isTrue);
    });

    testWidgets('OnboardingPolicyAgreement renders and toggles checkbox', (tester) async {
      bool currentVal = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return OnboardingPolicyAgreement(
                  hasAcceptedPolicies: currentVal,
                  onChanged: (val) => setState(() => currentVal = val),
                );
              },
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('Saya telah membaca dan menyetujui'),
        ),
        findsOneWidget,
      );
      expect(find.byType(Checkbox), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(currentVal, isTrue);
    });
  });
}
