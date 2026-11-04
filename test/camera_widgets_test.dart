import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/data/models/attendance_event_model.dart';
import 'package:kirana_people/features/attendance/widgets/camera_confirmation_bridge.dart';
import 'package:kirana_people/features/attendance/widgets/camera_controls_bar.dart';
import 'package:kirana_people/features/attendance/widgets/camera_device_integrity_dialog.dart';
import 'package:kirana_people/features/attendance/widgets/camera_preview_surface.dart';
import 'package:kirana_people/features/attendance/widgets/camera_session_controller.dart';
import 'package:kirana_people/features/attendance/widgets/camera_top_alert.dart';
import 'package:kirana_people/features/attendance/widgets/camera_top_bar.dart';

void main() {
  group('Camera Sub-Widgets Tests', () {
    testWidgets('CameraControlsBar renders flash, shutter, and flip buttons with callbacks', (tester) async {
      bool flashToggled = false;
      bool pictureTaken = false;
      bool cameraToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraControlsBar(
              isFlashOn: false,
              isScreenFlashWarmup: false,
              isTakingPhoto: false,
              onToggleFlash: () => flashToggled = true,
              onTakePicture: () => pictureTaken = true,
              onToggleCamera: () => cameraToggled = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.flash_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cameraswitch_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.flash_off_rounded));
      await tester.pump();
      expect(flashToggled, isTrue);

      await tester.tap(find.byIcon(Icons.camera_alt_rounded));
      await tester.pump();
      expect(pictureTaken, isTrue);

      await tester.tap(find.byIcon(Icons.cameraswitch_rounded));
      await tester.pump();
      expect(cameraToggled, isTrue);
    });

    testWidgets('CameraControlsBar shows circular progress indicator when photo is being taken', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraControlsBar(
              isFlashOn: true,
              isScreenFlashWarmup: true,
              isTakingPhoto: true,
              onToggleFlash: () {},
              onTakePicture: () {},
              onToggleCamera: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.flash_on_rounded), findsOneWidget);
    });

    testWidgets('CameraPreviewSurface renders fallback loader when camera is not ready', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 400,
              child: CameraPreviewSurface(
                controller: null,
                isCameraReady: false,
                isScreenFlashWarmup: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Image), findsOneWidget); // Headroom.png overlay
    });

    testWidgets('CameraTopBar renders action label and triggers onBack', (tester) async {
      bool backTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraTopBar(
              action: AttendanceEventType.startShift,
              textColor: Colors.white,
              onBack: () => backTapped = true,
            ),
          ),
        ),
      );

      expect(find.text(AttendanceEventType.startShift.label), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pump();
      expect(backTapped, isTrue);
    });

    testWidgets('CameraDeviceIntegrityDialog renders warning and dismisses on action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CameraDeviceIntegrityDialog.show(context),
                child: const Text('Show Warning'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Warning'));
      await tester.pumpAndSettle();

      expect(find.text('Perangkat Tidak Didukung'), findsOneWidget);
      expect(find.textContaining('Aplikasi mendeteksi bahwa perangkat ini telah di-root'), findsOneWidget);
      expect(find.text('Mengerti'), findsOneWidget);

      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();
      expect(find.text('Perangkat Tidak Didukung'), findsNothing);
    });

    testWidgets('CameraTopAlert renders warning message and handles dismiss', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraTopAlert(
              message: 'Wajah tidak terdeteksi. Pastikan wajah terlihat jelas.',
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('Wajah tidak terdeteksi. Pastikan wajah terlihat jelas.'), findsOneWidget);
      expect(find.byIcon(Icons.face_retouching_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(dismissed, isTrue);
    });

    test('CameraSessionController initializes with safe default state', () {
      final controller = CameraSessionController();
      expect(controller.controller, isNull);
      expect(controller.cameras, isEmpty);
      expect(controller.selectedCameraIndex, equals(0));
      expect(controller.isCameraReady, isFalse);
      expect(controller.isTakingPhoto, isFalse);
      expect(controller.isFlashOn, isFalse);
      expect(controller.isScreenFlashing, isFalse);
      expect(controller.isCurrentCameraFront, isTrue);
      controller.dispose();
    });
  });
}


