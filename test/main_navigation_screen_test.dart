import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/data/models/user_model.dart';
import 'package:kirana_people/features/navigation/main_navigation_screen.dart';
import 'package:kirana_people/providers/auth_provider.dart';

void main() {
  group('MainNavigationScreen Page Transition Tests', () {
    testWidgets('NavigationBar smoothly animates and transitions between tabs',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainNavigationScreen(),
          ),
        ),
      );

      // Pastikan awal di tab 0 (Beranda)
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Tap tab 'Profil'
      await tester.tap(find.text('Profil'));
      await tester.pump(); // frame pertama
      await tester.pump(const Duration(milliseconds: 350)); // selesaikan animasi PageView
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);

      // Tap tab 'Riwayat'
      await tester.tap(find.text('Riwayat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Profil destination displays user avatar when available',
        (tester) async {
      final dummyUser = UserModel(
        id: 1,
        name: 'Alexander Balmaceda',
        email: 'alex@kirana.com',
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              () => AuthNotifierMock(AuthState(user: dummyUser)),
            ),
          ],
          child: const MaterialApp(
            home: MainNavigationScreen(),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsWidgets);
      expect(find.text('Profil'), findsOneWidget);
    });
  });
}

class AuthNotifierMock extends AuthNotifier {
  final AuthState _initialState;
  AuthNotifierMock(this._initialState);

  @override
  AuthState build() => _initialState;
}

