import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kirana_people/features/attendance/widgets/camera_controls_bar.dart';
import 'package:kirana_people/features/attendance/widgets/camera_preview_surface.dart';

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
  });
}

