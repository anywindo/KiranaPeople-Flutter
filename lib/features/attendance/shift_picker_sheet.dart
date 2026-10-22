import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/shift_model.dart';

class ShiftPickerSheet extends StatefulWidget {
  final List<Shift> shifts;
  final Shift? selectedShift;
  final ValueChanged<Shift> onShiftSelected;

  const ShiftPickerSheet({
    super.key,
    required this.shifts,
    this.selectedShift,
    required this.onShiftSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Shift> shifts,
    Shift? selectedShift,
    required ValueChanged<Shift> onShiftSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShiftPickerSheet(
        shifts: shifts,
        selectedShift: selectedShift,
        onShiftSelected: onShiftSelected,
      ),
    );
  }

  @override
  State<ShiftPickerSheet> createState() => _ShiftPickerSheetState();
}

class _ShiftPickerSheetState extends State<ShiftPickerSheet> {
  late Shift? _currentSelection;

  @override
  void initState() {
    super.initState();
    _currentSelection = widget.selectedShift ?? (widget.shifts.isNotEmpty ? widget.shifts.first : null);
  }

  String _formatTime(String raw) {
    if (raw.length >= 5) {
      return raw.substring(0, 5);
    }
    return raw;
  }

  List<Shift> get _uniqueShifts {
    final seen = <String>{};
    return widget.shifts.where((s) {
      final key = '${s.id}_${s.name.trim().toLowerCase()}_${s.startTime}_${s.endTime}';
      return seen.add(key);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final uniqueList = _uniqueShifts;
    final maxHeight = MediaQuery.of(context).size.height * 0.70;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    'Pilih Shift Kerja',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.dividerColor),

          // Info description
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time_filled_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pilih shift yang sedang Anda jalani hari ini sebelum presensi masuk.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondaryColor,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Shift List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: uniqueList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final shift = uniqueList[index];
                final isSelected = _currentSelection?.id == shift.id;
                final start = _formatTime(shift.startTime);
                final end = _formatTime(shift.endTime);

                return InkWell(
                  onTap: () {
                    setState(() {
                      _currentSelection = shift;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : context.surfaceSecondaryColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : context.borderColor,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isSelected
                              ? AppColors.primary
                              : context.borderColor,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shift.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppColors.primary
                                      : context.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$start - $end WIB',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.textSecondaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (shift.breakStartTime != null && shift.breakEndTime != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.borderColor),
                            ),
                            child: Text(
                              'Istirahat ${_formatTime(shift.breakStartTime!)} - ${_formatTime(shift.breakEndTime!)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _currentSelection != null
                    ? () {
                        widget.onShiftSelected(_currentSelection!);
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Pilih Shift Ini',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
