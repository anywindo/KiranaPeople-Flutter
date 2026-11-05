import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bouncing_button.dart';
import '../../../data/models/shift_model.dart';
import '../shift_picker_sheet.dart';

class ShiftConfirmationDialog extends StatefulWidget {
  final Shift initialShift;
  final List<Shift> availableShifts;
  final ValueChanged<Shift>? onShiftChanged;

  const ShiftConfirmationDialog({
    super.key,
    required this.initialShift,
    required this.availableShifts,
    this.onShiftChanged,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Shift shift,
    required List<Shift> availableShifts,
    ValueChanged<Shift>? onShiftChanged,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ShiftConfirmationDialog(
        initialShift: shift,
        availableShifts: availableShifts,
        onShiftChanged: onShiftChanged,
      ),
    );
  }

  @override
  State<ShiftConfirmationDialog> createState() =>
      _ShiftConfirmationDialogState();
}

class _ShiftConfirmationDialogState extends State<ShiftConfirmationDialog> {
  late Shift _selectedShift;

  @override
  void initState() {
    super.initState();
    _selectedShift = widget.initialShift;
  }

  String _formatTime(String raw) {
    if (raw.length >= 5) {
      return raw.substring(0, 5);
    }
    return raw;
  }

  void _openShiftPicker() {
    final list = widget.availableShifts.isNotEmpty
        ? widget.availableShifts
        : [_selectedShift];
    ShiftPickerSheet.show(
      context,
      shifts: list,
      selectedShift: _selectedShift,
      onShiftSelected: (newShift) {
        setState(() {
          _selectedShift = newShift;
        });
        widget.onShiftChanged?.call(newShift);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasBreakTime = _selectedShift.breakStartTime != null &&
        _selectedShift.breakEndTime != null &&
        _selectedShift.breakStartTime!.isNotEmpty &&
        _selectedShift.breakEndTime!.isNotEmpty;

    return AlertDialog(
      elevation: 0,
      backgroundColor: context.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.borderColor, width: 1.2),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),

          // Title
          Text(
            'Konfirmasi Shift Kerja',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          Text(
            'Pastikan shift yang dipilih sudah sesuai sebelum memulai presensi Masuk Kerja.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondaryColor,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),

          // Shift Card (Tappable to pick/change shift)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openShiftPicker,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: context.surfaceSecondaryColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.borderColor, width: 1.2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedShift.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_filled_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${_formatTime(_selectedShift.startTime)} - ${_formatTime(_selectedShift.endTime)} WIB',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          if (hasBreakTime) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.coffee_rounded,
                                  size: 13,
                                  color: context.textSecondaryColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Istirahat: ${_formatTime(_selectedShift.breakStartTime!)} - ${_formatTime(_selectedShift.breakEndTime!)}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Pilih > pill button (matching shift card design)
                    BouncingButton(
                      scaleDown: 0.90,
                      onPressed: _openShiftPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pilih',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.borderColor, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Lanjutkan',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
