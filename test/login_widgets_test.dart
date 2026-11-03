import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/features/auth/widgets/login_form_card.dart';
import 'package:kirana_people/features/auth/widgets/login_header.dart';
import 'package:kirana_people/features/auth/widgets/login_motivation_card.dart';

void main() {
  group('Login Sub-Widgets Tests', () {
    testWidgets('LoginHeader renders logo image and greeting texts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: LoginHeader()),
          ),
        ),
      );

      expect(find.text('Masuk ke Akun Anda'), findsOneWidget);
      expect(find.text('Silakan masukkan identitas dan kata sandi Anda'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('LoginFormCard renders fields, triggers callbacks, and toggles rememberMe', (tester) async {
      final idController = TextEditingController(text: 'test@kirana.com');
      final passController = TextEditingController(text: 'password123');
      final idFocus = FocusNode();
      final passFocus = FocusNode();
      bool submitCalled = false;
      bool forgotPasswordCalled = false;
      bool visibilityToggled = false;
      bool? newRememberMe;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LoginFormCard(
                identifierController: idController,
                passwordController: passController,
                identifierFocus: idFocus,
                passwordFocus: passFocus,
                isPasswordVisible: false,
                rememberMe: true,
                isFormValid: true,
                isLoading: false,
                onTogglePasswordVisibility: () => visibilityToggled = true,
                onRememberMeChanged: (val) => newRememberMe = val,
                onForgotPasswordTap: () => forgotPasswordCalled = true,
                onSubmit: () => submitCalled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Email / ID Karyawan / NIK'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Ingat Saya'), findsOneWidget);
      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);

      // Tap submit button
      await tester.tap(find.text('Masuk'));
      await tester.pump();
      expect(submitCalled, isTrue);

      // Tap forgot password
      await tester.tap(find.text('Lupa Kata Sandi?'));
      await tester.pump();
      expect(forgotPasswordCalled, isTrue);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(visibilityToggled, isTrue);

      // Tap Ingat Saya checkbox row
      await tester.tap(find.text('Ingat Saya'));
      await tester.pump();
      expect(newRememberMe, isFalse);

      idController.dispose();
      passController.dispose();
      idFocus.dispose();
      passFocus.dispose();
    });

    testWidgets('LoginMotivationCard renders quote and advances to next quote on tap', (tester) async {
      int quoteIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LoginMotivationCard(
                  quoteIndex: quoteIndex,
                  onTap: () => setState(() => quoteIndex++),
                );
              },
            ),
          ),
        ),
      );

      final firstQuote = islamicQuotes[0];
      expect(find.text('“${firstQuote.quote}”'), findsOneWidget);
      expect(find.text(firstQuote.source), findsOneWidget);

      await tester.tap(find.byType(LoginMotivationCard));
      await tester.pumpAndSettle();

      final secondQuote = islamicQuotes[1];
      expect(find.text('“${secondQuote.quote}”'), findsOneWidget);
      expect(find.text(secondQuote.source), findsOneWidget);
    });
  });
}

