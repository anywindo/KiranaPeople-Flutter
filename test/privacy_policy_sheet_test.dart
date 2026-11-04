import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/theme/app_theme.dart';
import 'package:kirana_people/features/onboarding/privacy_policy_sheet.dart';

void main() {
  group('PrivacyPolicySheet Tests', () {
    testWidgets('renders comprehensive privacy policy sections and highlights banner', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: PrivacyPolicySheet(),
          ),
        ),
      );

      // Verify Header
      expect(find.text('Kebijakan Privasi'), findsOneWidget);
      expect(find.text('UU PDP No. 27/2022'), findsOneWidget);

      // Verify Highlights
      expect(find.text('Ikhtisar Komitmen Privasi Kami'), findsOneWidget);
      expect(find.text('Tanpa Background GPS'), findsOneWidget);
      expect(find.text('Selfie Bukti Presensi'), findsOneWidget);
      expect(find.text('Zero Third-Party Sharing'), findsOneWidget);

      // Verify Key Sections
      expect(find.textContaining('Ruang Lingkup & Landasan Hukum'), findsOneWidget);
      expect(find.textContaining('Data Pribadi yang Kami Kumpulkan'), findsOneWidget);
      expect(find.textContaining('Batasan Tegas Terkait Lokasi & Kamera'), findsOneWidget);

      // Verify Close/Understand Button when onAccept is null
      expect(find.text('Saya Mengerti & Tutup'), findsOneWidget);
    });

    testWidgets('triggers onAccept callback and dismisses sheet when button tapped', (tester) async {
      bool accepted = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    PrivacyPolicySheet.show(
                      context,
                      onAccept: () => accepted = true,
                    );
                  },
                  child: const Text('Buka Kebijakan'),
                );
              },
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Buka Kebijakan'));
      await tester.pumpAndSettle();

      // Verify onAccept button text
      expect(find.text('Saya Telah Membaca & Menyetujui'), findsOneWidget);

      // Tap Accept
      await tester.tap(find.text('Saya Telah Membaca & Menyetujui'));
      await tester.pumpAndSettle();

      expect(accepted, isTrue);
      expect(find.text('Kebijakan Privasi'), findsNothing);
    });

    testWidgets('renders cleanly in dark mode without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: PrivacyPolicySheet(),
          ),
        ),
      );

      expect(find.text('Kebijakan Privasi'), findsOneWidget);
      expect(find.text('Saya Mengerti & Tutup'), findsOneWidget);
    });

    testWidgets('PrivacyPolicyHighlightsBanner renders custom items properly', (tester) async {
      const customItems = [
        PrivacyHighlight(
          icon: Icons.shield,
          title: 'Custom Title',
          desc: 'Custom Description',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: PrivacyPolicyHighlightsBanner(items: customItems),
          ),
        ),
      );

      expect(find.text('Ikhtisar Komitmen Privasi Kami'), findsOneWidget);
      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Custom Description'), findsOneWidget);
      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('PrivacyPolicySectionCard renders section number, badge, and bullets', (tester) async {
      const testSection = PrivacyPolicySection(
        icon: Icons.verified_user,
        sectionNumber: '99',
        title: 'Ketentuan Khusus',
        badge: 'Penting',
        badgeColor: Colors.deepOrange,
        content: 'Isi ringkas ketentuan.',
        bulletPoints: ['Poin A', 'Poin B'],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: PrivacyPolicySectionCard(section: testSection),
          ),
        ),
      );

      expect(find.text('99. Ketentuan Khusus'), findsOneWidget);
      expect(find.text('Penting'), findsOneWidget);
      expect(find.text('Isi ringkas ketentuan.'), findsOneWidget);
      expect(find.text('Poin A'), findsOneWidget);
      expect(find.text('Poin B'), findsOneWidget);
      expect(find.byIcon(Icons.verified_user), findsOneWidget);
    });

    test('privacySections and privacyHighlights static data integrity', () {
      expect(privacySections.length, equals(12));
      expect(privacyHighlights.length, equals(4));

      for (final s in privacySections) {
        expect(s.sectionNumber.isNotEmpty, isTrue);
        expect(s.title.isNotEmpty, isTrue);
        expect(s.content.isNotEmpty, isTrue);
      }
    });
  });
}

