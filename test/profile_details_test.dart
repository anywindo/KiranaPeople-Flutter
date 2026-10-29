import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_people/data/models/shift_model.dart';
import 'package:kirana_people/data/models/user_model.dart';
import 'package:kirana_people/features/profile/profile_screen.dart';
import 'package:kirana_people/providers/auth_provider.dart';

void main() {
  group('UserModel parsing tests for new profile fields', () {
    test('parses shift, department, and gender correctly from json', () {
      final json = {
        'id': 1,
        'name': 'Budi Santoso',
        'email': 'budi@kirana.com',
        'nik': '3301010101900001', // male
        'is_active': true,
        'department': 'Teknologi Informasi',
        'shift': {
          'id': 1,
          'name': 'Shift Pagi',
          'start_time': '08:00',
          'end_time': '17:00',
        },
      };

      final user = UserModel.fromJson(json);
      expect(user.department, 'Teknologi Informasi');
      expect(user.shift?.name, 'Shift Pagi');
      expect(user.shift?.startTime, '08:00');
      expect(user.computedGender, 'Laki-laki');
      expect(user.isActive, true);
    });

    test('derives female gender from NIK with day > 40', () {
      final json = {
        'id': 2,
        'name': 'Siti Rahma',
        'email': 'siti@kirana.com',
        'nik': '3301015201950002', // day is 52 -> female
        'is_active': false,
        'teams': [
          {'id': 1, 'name': 'Human Resources'},
        ],
      };

      final user = UserModel.fromJson(json);
      expect(user.department, 'Human Resources');
      expect(user.computedGender, 'Perempuan');
      expect(user.isActive, false);
    });
  });

  group('ProfileScreen widget tests for added fields', () {
    testWidgets('renders status badge, department, shift, and gender', (tester) async {
      final testUser = UserModel(
        id: 10,
        name: 'Arwindo Pratama',
        email: 'arw.prt@gmail.com',
        employeeId: 'EMP-00010',
        nik: '3301011507980001',
        dob: '1998-07-15',
        isActive: true,
        department: 'Operasional & GA',
        roles: ['HR'],
        shift: Shift(
          id: 1,
          name: 'Shift Reguler',
          startTime: '08:00',
          endTime: '17:00',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => MockAuthNotifier(testUser)),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Status Badge
      expect(find.text('Aktif'), findsOneWidget);

      // Check Departemen
      expect(find.text('Departemen'), findsOneWidget);
      expect(find.text('Operasional & GA'), findsOneWidget);

      // Check Shift Kerja
      expect(find.text('Shift Kerja'), findsOneWidget);
      expect(find.text('Shift Reguler (08:00 - 17:00)'), findsOneWidget);

      // Check Jenis Kelamin
      expect(find.text('Jenis Kelamin'), findsOneWidget);
      expect(find.text('Laki-laki'), findsOneWidget);
    });
  });
}

class MockAuthNotifier extends AuthNotifier {
  final UserModel _user;
  MockAuthNotifier(this._user);

  @override
  AuthState build() {
    return AuthState(
      isCheckingSession: false,
      isAuthenticated: true,
      user: _user,
    );
  }
}
