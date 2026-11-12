import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/bouncing_button.dart';
import '../../core/widgets/haptic_refresh_indicator.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import 'attendance_pdf_preview_screen.dart';
import 'widgets/attendance_export_period_sheet.dart';
import 'widgets/history_empty_state.dart';
import 'widgets/history_filter_bar.dart';
import 'widgets/history_filter_sheet.dart';
import 'widgets/history_item_card.dart';
import 'widgets/history_location_modal.dart';
import 'widgets/history_summary_card.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() async {
    if (!_scrollController.hasClients) return;

    final shouldShow = _scrollController.offset > 280;
    if (shouldShow != _showScrollToTop) {
      setState(() {
        _showScrollToTop = shouldShow;
      });
    }

    if (_scrollController.position.maxScrollExtent > 0 &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250) {
      final historyState = ref.read(historyProvider);
      if (historyState.hasMore && !_isLoadingMore) {
        setState(() {
          _isLoadingMore = true;
        });
        await ref
            .read(historyProvider.notifier)
            .loadHistory(page: historyState.currentPage + 1);
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      }
    }
  }

  void _scrollToTop() {
    AppHaptics.medium();
    if (_scrollController.hasClients) {
      final currentOffset = _scrollController.offset;
      final durationMs = (380 + (currentOffset / 20)).clamp(380, 550).toInt();
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  Future<void> _openPdfExport(
    BuildContext context,
    HistoryState historyState,
    UserModel? user,
  ) async {
    AppHaptics.selection();

    if (user == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data profil pengguna belum termuat.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 1. Show period selection sheet (Bulan Ini, Bulan Lalu, Bulan Lain, dll)
    final periodResult = await AttendanceExportPeriodSheet.show(
      context,
      activeFilterLabel: historyState.filter.dateRangeLabel,
      activeDateRange: historyState.filter.dateRange,
    );

    if (periodResult == null || !context.mounted) return;

    final start = DateTime(
      periodResult.startDate.year,
      periodResult.startDate.month,
      periodResult.startDate.day,
    );
    final end = DateTime(
      periodResult.endDate.year,
      periodResult.endDate.month,
      periodResult.endDate.day,
      23,
      59,
      59,
    );

    // 1. Filter local records strictly within the selected range
    final allRecords = historyState.records.value ?? [];
    List<AttendanceRecord> exportRecords = allRecords.where((r) {
      final dt = DateTime.tryParse(r.date);
      if (dt == null) return false;
      return !dt.isBefore(start) && !dt.isAfter(end);
    }).toList();

    // 2. If local has no records for this month, try fetching from repository
    if (exportRecords.isEmpty) {
      try {
        final startStr = DateFormatter.formatDateYmd(start);
        final endStr = DateFormatter.formatDateYmd(end);
        final fetched = await ref
            .read(attendanceRepositoryProvider)
            .getAttendanceHistory(startDate: startStr, endDate: endStr);
        // Strictly filter fetched records by date range as well
        final validFetched = fetched.where((r) {
          final dt = DateTime.tryParse(r.date);
          if (dt == null) return false;
          return !dt.isBefore(start) && !dt.isAfter(end);
        }).toList();

        if (validFetched.isNotEmpty) {
          exportRecords = validFetched;
        }
      } catch (_) {
        // Fallback to local
      }
    }

    if (!context.mounted) return;

    if (exportRecords.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak ada riwayat presensi tercatat pada ${periodResult.periodLabel}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendancePdfPreviewScreen(
          user: user,
          records: exportRecords,
          periodLabel: periodResult.periodLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);
    final user = ref.watch(authProvider).user;
    final workLocation = user?.location;

    final topPadding = MediaQuery.of(context).padding.top;
    final headerContentHeight = topPadding + 44 + 48; // Title bar + filter bar
    final gradientHeight = headerContentHeight + 36.0;
    final listTopPadding = headerContentHeight + 10.0;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Stack(
        children: [
          // 1. History List / Content (Passes under the feathered blur header)
          Positioned.fill(
            child: HapticRefreshIndicator(
              color: AppColors.primary,
              edgeOffset: headerContentHeight,
              onRefresh: () => ref.read(historyProvider.notifier).refresh(),
              child: historyState.records.when(
                loading: () => HistoryListSkeleton(
                  padding: EdgeInsets.fromLTRB(16, listTopPadding, 16, 128),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24.0,
                      listTopPadding,
                      24.0,
                      128.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.history_toggle_off,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal memuat riwayat: $err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              ref.read(historyProvider.notifier).refresh(),
                          child: const Text('Muat Ulang'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (records) {
                  if (records.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          24.0,
                          listTopPadding + 60,
                          24.0,
                          128.0,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 48,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada riwayat presensi tercatat.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final filteredList = historyState.filteredRecords;
                  if (filteredList.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        listTopPadding + 20,
                        16,
                        128,
                      ),
                      children: [
                        HistoryEmptyState(
                          onResetFilter: () =>
                              ref.read(historyProvider.notifier).resetFilter(),
                        ),
                      ],
                    );
                  }

                  final showLoadingMore =
                      historyState.hasMore && !historyState.filter.isActive;
                  return ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(16, listTopPadding, 16, 128),
                    itemCount: filteredList.length + 1 + (showLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 18),
                    itemBuilder: (context, index) {
                      // Index 0: Monthly / Filtered Attendance Summary Card
                      if (index == 0) {
                        return HistorySummaryCard(
                          records: historyState.filter.isActive
                              ? filteredList
                              : records,
                          onExportPdf: () =>
                              _openPdfExport(context, historyState, user),
                        );
                      }

                      // Trailing Loading Indicator for pagination
                      if (showLoadingMore && index == filteredList.length + 1) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: HistoryCardSkeleton(),
                        );
                      }

                      final item = filteredList[index - 1];

                      return HistoryItemCard(
                        item: item,
                        onEventTap: (event) => HistoryLocationModal.show(
                          context,
                          event: event,
                          workLocation: workLocation,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // 2. Exact Feathered Blur Gradient from top to bottom behind header & filter bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: gradientHeight,
            child: IgnorePointer(
              child: ClipRect(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.black, Colors.transparent],
                      stops: [0.0, 0.60, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            context.scaffoldBg.withValues(
                              alpha: context.isDarkMode ? 0.98 : 0.96,
                            ),
                            context.scaffoldBg.withValues(
                              alpha: context.isDarkMode ? 0.96 : 0.94,
                            ),
                            context.scaffoldBg.withValues(
                              alpha: context.isDarkMode ? 0.60 : 0.50,
                            ),
                            context.scaffoldBg.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.55, 0.78, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Pinned Header Elements (App Bar Title Row + HistoryFilterBar + Background Syncing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title Bar Row
                  SizedBox(
                    height: 44,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Export PDF Button (Left)
                          InkWell(
                            key: const Key('history_export_pdf_button'),
                            onTap: () =>
                                _openPdfExport(context, historyState, user),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: context.surfaceSecondaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: context.isDarkMode
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf_outlined,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 44),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Riwayat Presensi',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                            ),
                          ),
                          // Filter Button
                          InkWell(
                            onTap: () =>
                                HistoryFilterSheet.showFullFilter(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: historyState.filter.isActive
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : context.surfaceSecondaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: historyState.filter.isActive
                                      ? AppColors.primary
                                      : (context.isDarkMode
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFCBD5E1)),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: historyState.filter.isActive
                                    ? AppColors.primary
                                    : context.textSecondaryColor,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Refresh Button
                          InkWell(
                            onTap: () =>
                                ref.read(historyProvider.notifier).refresh(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: context.surfaceSecondaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: context.isDarkMode
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Filter Chips Bar
                  const HistoryFilterBar(),

                  // Background Syncing Indicator
                  AnimatedOpacity(
                    opacity: historyState.isBackgroundSyncing ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: historyState.isBackgroundSyncing
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(1),
                            child: LinearProgressIndicator(
                              minHeight: 2,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary.withValues(alpha: 0.6),
                              ),
                            ),
                          )
                        : const SizedBox(height: 2),
                  ),
                ],
              ),
            ),
          ),

          // 4. Smooth Floating Center Pill Scroll-to-Top Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 124,
            child: Center(
              child: IgnorePointer(
                ignoring: !_showScrollToTop,
                child: AnimatedSlide(
                  offset: _showScrollToTop
                      ? Offset.zero
                      : const Offset(0, 0.45),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: AnimatedScale(
                    scale: _showScrollToTop ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: _showScrollToTop ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      child: BouncingButton(
                        scaleDown: 0.94,
                        hapticType: BouncingHapticType.selection,
                        onPressed: _scrollToTop,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? AppColors.darkSurface
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: context.isDarkMode
                                  ? AppColors.darkBorder
                                  : const Color(0xFFE2E8F0),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: context.isDarkMode ? 0.35 : 0.08,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.arrow_upward_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Kembali ke Atas',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: context.isDarkMode
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
