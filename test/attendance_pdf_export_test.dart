import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/data/models/attendance_event_model.dart';
import 'package:kirana_people/data/models/attendance_model.dart';
import 'package:kirana_people/data/models/shift_model.dart';
import 'package:kirana_people/data/models/user_model.dart';
import 'package:kirana_people/data/models/work_location_model.dart';
import 'package:kirana_people/features/history/attendance_pdf_preview_screen.dart';
import 'package:kirana_people/features/history/services/attendance_pdf_service.dart';
import 'package:kirana_people/features/history/widgets/attendance_export_period_sheet.dart';
import 'package:kirana_people/features/history/widgets/history_summary_card.dart';
import 'package:printing/printing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockUser = UserModel(
    id: 1,
    name: 'Budi Santoso',
    email: 'budi@kirana.com',
    employeeId: 'EMP-00123',
    nik: '3201010101010001',
    location: WorkLocation(
      id: 1,
      name: 'Kantor Pusat Jakarta',
      latitude: -6.2,
      longitude: 106.8,
      radius: 100,
    ),
  );

  final mockShift = Shift(
    id: 1,
    name: 'Shift Pagi',
    startTime: '08:00',
    endTime: '17:00',
  );

  final mockRecords = [
    AttendanceRecord(
      id: 101,
      date: '2026-11-10',
      status: 'Tepat Waktu',
      shift: mockShift,
      events: [
        AttendanceEvent(
          eventType: AttendanceEventType.startShift,
          timestamp: '2026-11-10T07:55:00.000Z',
        ),
        AttendanceEvent(
          eventType: AttendanceEventType.startBreak,
          timestamp: '2026-11-10T12:00:00.000Z',
        ),
        AttendanceEvent(
          eventType: AttendanceEventType.endBreak,
          timestamp: '2026-11-10T13:00:00.000Z',
        ),
        AttendanceEvent(
          eventType: AttendanceEventType.endShift,
          timestamp: '2026-11-10T17:05:00.000Z',
        ),
      ],
    ),
    AttendanceRecord(
      id: 102,
      date: '2026-11-11',
      status: 'LATE',
      shift: mockShift,
      events: [
        AttendanceEvent(
          eventType: AttendanceEventType.startShift,
          timestamp: '2026-11-11T08:35:00.000Z',
        ),
        AttendanceEvent(
          eventType: AttendanceEventType.endShift,
          timestamp: '2026-11-11T17:00:00.000Z',
        ),
      ],
    ),
  ];

  group('AttendancePdfService Tests', () {
    test('generateAttendanceReport returns valid PDF document bytes', () async {
      final pdfBytes = await AttendancePdfService.generateAttendanceReport(
        user: mockUser,
        records: mockRecords,
        filterPeriodLabel: '10 Nov 2026 s.d 11 Nov 2026',
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.isNotEmpty, isTrue);

      // A valid PDF file begins with the ASCII header "%PDF-"
      final header = ascii.decode(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generateAttendanceReport handles empty records gracefully', () async {
      final pdfBytes = await AttendancePdfService.generateAttendanceReport(
        user: mockUser,
        records: [],
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.isNotEmpty, isTrue);
      final header = ascii.decode(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generateAttendanceReport handles 35 records across multiple pages', () async {
      final manyRecords = List.generate(
        35,
        (i) => AttendanceRecord(
          id: 200 + i,
          date: '2026-11-${(i + 1).toString().padLeft(2, '0')}',
          status: i % 3 == 0 ? 'LATE' : 'Tepat Waktu',
          shift: mockShift,
          events: [
            AttendanceEvent(
              eventType: AttendanceEventType.startShift,
              timestamp: '2026-11-${(i + 1).toString().padLeft(2, '0')}T08:00:00.000Z',
            ),
            AttendanceEvent(
              eventType: AttendanceEventType.endShift,
              timestamp: '2026-11-${(i + 1).toString().padLeft(2, '0')}T17:00:00.000Z',
            ),
          ],
        ),
      );

      final pdfBytes = await AttendancePdfService.generateAttendanceReport(
        user: mockUser,
        records: manyRecords,
      );

      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.isNotEmpty, isTrue);
    });
  });

  group('AttendancePdfPreviewScreen Widget Tests', () {
    testWidgets('renders app bar title and PdfPreview widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AttendancePdfPreviewScreen(
            user: mockUser,
            records: mockRecords,
            periodLabel: 'November 2026',
          ),
        ),
      );

      expect(find.text('Rekap Presensi PDF'), findsOneWidget);
      expect(find.byType(PdfPreview), findsOneWidget);
    });

    testWidgets('HistorySummaryCard renders PDF export button when expanded and triggers callback', (tester) async {
      bool exportCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HistorySummaryCard(
                records: mockRecords,
                initiallyExpanded: true,
                onExportPdf: () => exportCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final exportButton = find.byKey(const Key('summary_export_pdf_button'));
      expect(exportButton, findsOneWidget);

      await tester.tap(exportButton);
      await tester.pump();

      expect(exportCalled, isTrue);
    });

    testWidgets('AttendanceExportPeriodSheet renders month options and returns selected period', (tester) async {
      AttendanceExportPeriodResult? selectedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  selectedResult = await AttendanceExportPeriodSheet.show(ctx);
                },
                child: const Text('Buka Periode Sheet'),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Buka Periode Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Periode Ekspor PDF'), findsOneWidget);
      expect(find.byKey(const Key('export_option_current_month')), findsOneWidget);
      expect(find.byKey(const Key('export_option_last_month')), findsOneWidget);
      expect(find.byKey(const Key('export_option_custom_month')), findsOneWidget);

      // Tap current month
      await tester.tap(find.byKey(const Key('export_option_current_month')));
      await tester.pumpAndSettle();

      expect(selectedResult, isNotNull);
      expect(selectedResult!.startDate.day, equals(1));
    });
  });
}
