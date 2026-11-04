import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/data/models/user_model.dart';
import 'package:kirana_people/features/attendance/widgets/attendance_header.dart';
import 'package:kirana_people/features/attendance/widgets/attendance_live_clock.dart';

void main() {
  group('AttendanceLiveClock & AttendanceHeader Tests', () {
    testWidgets('AttendanceLiveClock renders icon and time string', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AttendanceLiveClock(),
          ),
        ),
      );

      expect(find.byType(AttendanceLiveClock), findsOneWidget);
      expect(find.byIcon(Icons.access_time_filled_rounded), findsOneWidget);

      // Verifikasi format waktu HH:mm:ss (regex \d{2}:\d{2}:\d{2})
      final timeFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(widget.data ?? ''),
      );
      expect(timeFinder, findsOneWidget);

      // Pump 1 detik untuk memicu timer
      await tester.pump(const Duration(seconds: 1));
      expect(timeFinder, findsOneWidget);
    });

    testWidgets('AttendanceHeader renders both user greeting and live clock side-by-side',
        (tester) async {
      final dummyUser = UserModel(
        id: 1,
        name: 'Budi Santoso',
        email: 'budi@kirana.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttendanceHeader(
              user: dummyUser,
              isBackgroundSyncing: false,
              onRefresh: () {},
              onLogout: () {},
            ),
          ),
        ),
      );

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.byType(AttendanceLiveClock), findsOneWidget);
      expect(find.byIcon(Icons.access_time_filled_rounded), findsOneWidget);
    });
  });
}

