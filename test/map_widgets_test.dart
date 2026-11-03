import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/core/theme/app_theme.dart';
import 'package:kirana_people/data/models/shift_model.dart';
import 'package:kirana_people/features/map/widgets/map_attendance_action_card.dart';
import 'package:kirana_people/features/map/widgets/map_controls_overlay.dart';
import 'package:kirana_people/features/map/widgets/map_top_location_pill.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('Map Sub-Widgets Tests', () {
    testWidgets('MapTopLocationPill renders office name and handles refresh callback', (tester) async {
      bool refreshed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Stack(
              children: [
                MapTopLocationPill(
                  officeName: 'Kantor Pusat Kirana',
                  topPadding: 24,
                  isRefreshing: false,
                  onRefresh: () => refreshed = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Kantor Pusat Kirana'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();

      expect(refreshed, isTrue);
    });

    testWidgets('MapTopLocationPill displays CircularProgressIndicator when isRefreshing is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Stack(
              children: [
                MapTopLocationPill(
                  officeName: 'Kantor Cabang',
                  topPadding: 24,
                  isRefreshing: true,
                  onRefresh: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('MapControlsOverlay renders recenter and fit-bounds buttons and triggers callbacks', (tester) async {
      bool recentered = false;
      bool fitted = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MapControlsOverlay(
              onRecenter: () => recentered = true,
              onFitBounds: () => fitted = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.near_me_rounded), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out_map_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.near_me_rounded));
      await tester.pump();
      expect(recentered, isTrue);

      await tester.tap(find.byIcon(Icons.zoom_out_map_rounded));
      await tester.pump();
      expect(fitted, isTrue);
    });

    testWidgets('MapAttendanceActionCard renders inside-radius state, shift details, and triggers action', (tester) async {
      bool actionTapped = false;
      final shift = Shift(
        id: 1,
        name: 'Pagi',
        startTime: '08:00:00',
        endTime: '17:00:00',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MapAttendanceActionCard(
                hasLocation: true,
                isInsideRadius: true,
                distance: 25.4,
                officeLatLng: const LatLng(-6.9897, 109.8765),
                officeName: 'Kantor Utama',
                selectedShift: shift,
                isActionDisabled: false,
                actionBtnLabel: 'Ambil Presensi: Masuk Kerja',
                onAction: () => actionTapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Dalam Radius Presensi'), findsOneWidget);
      expect(find.text('25 m dari titik kantor'), findsOneWidget);
      expect(find.text('Rute'), findsOneWidget);
      expect(find.textContaining('Shift: Pagi [08:00 - 17:00]'), findsOneWidget);
      expect(find.text('Ambil Presensi: Masuk Kerja'), findsOneWidget);

      await tester.tap(find.text('Ambil Presensi: Masuk Kerja'));
      await tester.pump();

      expect(actionTapped, isTrue);
    });

    testWidgets('MapAttendanceActionCard renders outside-radius state and disabled action button', (tester) async {
      bool actionTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MapAttendanceActionCard(
                hasLocation: true,
                isInsideRadius: false,
                distance: 350.0,
                officeLatLng: const LatLng(-6.9897, 109.8765),
                officeName: 'Kantor Utama',
                isActionDisabled: true,
                actionBtnLabel: 'Presensi Hari Ini Selesai',
                onAction: () => actionTapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Di Luar Radius Presensi'), findsOneWidget);
      expect(find.text('350 m dari titik kantor'), findsOneWidget);
      expect(find.text('Presensi Hari Ini Selesai'), findsOneWidget);

      await tester.tap(find.text('Presensi Hari Ini Selesai'));
      await tester.pump();

      // Disabled button should not trigger onAction
      expect(actionTapped, isFalse);
    });

    testWidgets('Map sub-widgets render in Dark Mode cleanly without visual overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  MapControlsOverlay(
                    onRecenter: () {},
                    onFitBounds: () {},
                  ),
                  MapAttendanceActionCard(
                    hasLocation: false,
                    locationError: 'Sinyal GPS Lemah',
                    isInsideRadius: false,
                    distance: 0,
                    officeLatLng: const LatLng(-6.9897, 109.8765),
                    officeName: 'Kantor Utama',
                    isActionDisabled: false,
                    actionBtnLabel: 'Ambil Presensi: Masuk Kerja',
                    onAction: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sinyal GPS Lemah'), findsOneWidget);
      expect(find.text('Ketuk tombol refresh untuk memuat koordinat'), findsOneWidget);
    });
  });
}

