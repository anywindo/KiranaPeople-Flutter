import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import 'widgets/history_empty_state.dart';
import 'widgets/history_filter_bar.dart';
import 'widgets/history_filter_sheet.dart';
import 'widgets/history_item_card.dart';
import 'widgets/history_location_modal.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

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
            child: RefreshIndicator(
              color: AppColors.primary,
              edgeOffset: headerContentHeight,
              onRefresh: () => ref.read(historyProvider.notifier).refresh(),
              child: historyState.records.when(
                loading: () => HistoryListSkeleton(
                  padding: EdgeInsets.fromLTRB(16, listTopPadding, 16, 128),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.0, listTopPadding, 24.0, 128.0),
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
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24.0, listTopPadding, 24.0, 128.0),
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
                    );
                  }

                  final filteredList = historyState.filteredRecords;
                  if (filteredList.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, listTopPadding + 20, 16, 128),
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
                    itemCount: filteredList.length + (showLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 18),
                    itemBuilder: (context, index) {
                      if (index == filteredList.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: HistoryCardSkeleton(),
                        );
                      }
                      final item = filteredList[index];

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
                      colors: [
                        Colors.black,
                        Colors.black,
                        Colors.transparent,
                      ],
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
                          const SizedBox(width: 80),
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
                            onTap: () => HistoryFilterSheet.showFullFilter(context),
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
                                          : const Color(0xFFE2E8F0)),
                                  width: 1.2,
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
                            onTap: () => ref.read(historyProvider.notifier).refresh(),
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
                                      : const Color(0xFFE2E8F0),
                                  width: 1.2,
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1),
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
