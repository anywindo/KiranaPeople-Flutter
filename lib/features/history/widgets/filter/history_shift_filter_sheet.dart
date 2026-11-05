import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/history_provider.dart';
import 'history_filter_option_tile.dart';

class HistoryShiftFilterSheet extends StatelessWidget {
  const HistoryShiftFilterSheet({super.key});

  static void show(BuildContext context, WidgetRef ref, List<String> shifts) {
    final historyState = ref.read(historyProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Filter Shift Kerja',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...shifts.map((s) {
              final isSelected =
                  (historyState.filter.shift ?? 'Semua Shift') == s;
              return HistoryFilterOptionTile(
                title: s,
                isSelected: isSelected,
                onTap: () {
                  ref
                      .read(historyProvider.notifier)
                      .setShiftFilter(s == 'Semua Shift' ? null : s);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
