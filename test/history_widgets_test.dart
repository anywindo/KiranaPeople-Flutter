import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/data/models/attendance_event_model.dart';
import 'package:kirana_people/data/models/attendance_model.dart';
import 'package:kirana_people/data/models/shift_model.dart';
import 'package:kirana_people/features/history/widgets/history_empty_state.dart';
import 'package:kirana_people/features/history/widgets/history_filter_bar.dart';
import 'package:kirana_people/features/history/widgets/history_item_card.dart';
import 'package:kirana_people/features/history/widgets/history_summary_card.dart';
import 'package:kirana_people/features/history/widgets/history_filter_sheet.dart';
import 'package:kirana_people/features/history/widgets/history_location_modal.dart';

void main() {
  group('History Sub-Widgets Tests', () {
    testWidgets('HistoryEmptyState renders message and triggers reset callback', (tester) async {
      bool resetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryEmptyState(
              onResetFilter: () => resetCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Tidak Ada Riwayat Sesuai Filter'), findsOneWidget);
      expect(find.text('Reset Semua Filter'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list_off_rounded), findsOneWidget);

      await tester.tap(find.text('Reset Semua Filter'));
      await tester.pump();

      expect(resetCalled, isTrue);
    });

    testWidgets('HistoryItemCard renders record details, status badge, and triggers tap', (tester) async {
      AttendanceEvent? tappedEvent;

      final testEvent = AttendanceEvent(
        id: 1,
        eventType: AttendanceEventType.startShift,
        timestamp: '2026-11-03 07:55:00',
        latitude: -7.025648,
        longitude: 109.957296,
        selfieUrl: 'selfie.jpg',
      );

      final record = AttendanceRecord(
        id: 10,
        date: '2026-11-03',
        status: 'Tepat Waktu',
        shift: Shift(
          id: 1,
          name: 'Pagi',
          startTime: '08:00',
          endTime: '17:00',
          attendanceRuleEnabled: false,
        ),
        events: [testEvent],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryItemCard(
              item: record,
              onEventTap: (event) => tappedEvent = event,
            ),
          ),
        ),
      );

      expect(find.text('3 November, 2026'), findsOneWidget);
      expect(find.text('Tepat Waktu'), findsOneWidget);
      expect(find.text('Pagi'), findsOneWidget);
      expect(find.text(AttendanceEventType.startShift.label), findsOneWidget);
      // expect(find.text('Lokasi GPS'), findsOneWidget);

      await tester.tap(find.text(AttendanceEventType.startShift.label));
      await tester.pump();

      expect(tappedEvent, isNotNull);
      expect(tappedEvent!.id, equals(1));
    });

    testWidgets('HistoryFilterBar renders pills and interacts with Riverpod historyProvider', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HistoryFilterBar(),
            ),
          ),
        ),
      );

      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Tepat Waktu'), findsOneWidget);
      expect(find.text('Terlambat'), findsOneWidget);
      expect(find.text('Tanggal'), findsOneWidget);

      // Tap on 'Tepat Waktu' pill
      await tester.tap(find.text('Tepat Waktu'));
      await tester.pumpAndSettle();

      // Reset pill should now appear because a filter is active
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('HistoryFilterOptionTile renders and triggers callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryFilterOptionTile(
              title: 'Hari Ini',
              subtitle: '4 Nov 2026',
              isSelected: true,
              icon: Icons.calendar_today_rounded,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Hari Ini'), findsOneWidget);
      expect(find.text('4 Nov 2026'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      await tester.tap(find.text('Hari Ini'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('HistoryFilterChip renders and triggers callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryFilterChip(
              label: 'Semua Status',
              isSelected: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Semua Status'), findsOneWidget);
      await tester.tap(find.text('Semua Status'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('HistoryLocationRadiusBadge renders inside and outside states', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HistoryLocationRadiusBadge(
                  isInside: true,
                  distance: 25.0,
                  radius: 50.0,
                ),
                HistoryLocationRadiusBadge(
                  isInside: false,
                  distance: 1250.0,
                  radius: 50.0,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Dalam radius presensi (25 m dari kantor)'), findsOneWidget);
      expect(find.text('Jarak 1.25 km dari titik kantor (Radius: 50m)'), findsOneWidget);
    });

    testWidgets('HistorySummaryCard calculates metrics and renders summary counts', (tester) async {
      final records = [
        AttendanceRecord(
          id: 1,
          date: '2026-11-01',
          status: 'ON_TIME',
          events: [],
        ),
        AttendanceRecord(
          id: 2,
          date: '2026-11-02',
          status: 'LATE',
          events: [],
        ),
        AttendanceRecord(
          id: 3,
          date: '2026-11-03',
          status: 'ON_TIME',
          events: [],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistorySummaryCard(records: records),
          ),
        ),
      );

      expect(find.text('Ringkasan Kehadiran'), findsOneWidget);
      expect(find.text('Total Hadir'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Tepat Waktu'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Terlambat'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
