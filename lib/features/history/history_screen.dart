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

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Riwayat Presensi',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        actions: [
          // Filter Button with Badge
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
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
                            : context.borderColor,
                        width: 1,
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
                if (historyState.filter.isActive)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          '${historyState.filter.activeFilterCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Refresh Button
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => ref.read(historyProvider.notifier).refresh(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.surfaceSecondaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.borderColor, width: 1),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
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

          // History List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(historyProvider.notifier).refresh(),
              child: historyState.records.when(
                loading: () => const HistoryListSkeleton(),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
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
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada riwayat presensi tercatat.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredList = historyState.filteredRecords;
                  if (filteredList.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 96),
                      children: [
                        const SizedBox(height: 40),
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
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
        ],
      ),
    );
  }
}
