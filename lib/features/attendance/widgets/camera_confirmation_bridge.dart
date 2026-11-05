import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../data/models/attendance_event_model.dart';
import '../../../data/models/work_location_model.dart';
import '../attendance_confirmation_view.dart';

class CameraConfirmationBridge extends StatelessWidget {
  final File photoFile;
  final AttendanceEventType action;
  final int? shiftId;
  final WorkLocation? workLocation;
  final Position? initialPosition;
  final Future<void>? imageProcessFuture;
  final bool isFrontCamera;
  final Future<void> Function() onRetake;
  final VoidCallback onSubmittedSuccess;

  const CameraConfirmationBridge({
    super.key,
    required this.photoFile,
    required this.action,
    this.shiftId,
    this.workLocation,
    this.initialPosition,
    this.imageProcessFuture,
    required this.isFrontCamera,
    required this.onRetake,
    required this.onSubmittedSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await onRetake();
      },
      child: AttendanceConfirmationView(
        photoFile: photoFile,
        action: action,
        shiftId: shiftId,
        workLocation: workLocation,
        initialPosition: initialPosition,
        imageProcessFuture: imageProcessFuture,
        isFrontCamera: isFrontCamera,
        onRetake: onRetake,
        onSubmittedSuccess: onSubmittedSuccess,
      ),
    );
  }
}
