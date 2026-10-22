import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/attendance_model.dart';
import '../data/repositories/attendance_repository.dart';
import 'auth_provider.dart';

class HistoryState {
  final AsyncValue<List<AttendanceRecord>> records;
  final int currentPage;
  final bool hasMore;
  final bool isBackgroundSyncing;

  const HistoryState({
    this.records = const AsyncValue.loading(),
    this.currentPage = 1,
    this.hasMore = true,
    this.isBackgroundSyncing = false,
  });

  HistoryState copyWith({
    AsyncValue<List<AttendanceRecord>>? records,
    int? currentPage,
    bool? hasMore,
    bool? isBackgroundSyncing,
  }) {
    return HistoryState(
      records: records ?? this.records,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isBackgroundSyncing: isBackgroundSyncing ?? this.isBackgroundSyncing,
    );
  }
}

class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      return const HistoryState();
    }

    Future.microtask(() => loadHistory(page: 1));
    return const HistoryState();
  }

  void reset() {
    state = const HistoryState();
  }

  Future<void> loadHistory({int page = 1, bool isBackground = false}) async {
    // Prevent fetching or retaining state when not authenticated
    if (!ref.read(authProvider).isAuthenticated) {
      state = const HistoryState();
      return;
    }

    final repo = ref.read(attendanceRepositoryProvider);
    final hasExistingRecords = state.records.hasValue;

    if (page == 1) {
      if (hasExistingRecords || isBackground) {
        state = state.copyWith(isBackgroundSyncing: true);
      } else {
        state = state.copyWith(records: const AsyncValue.loading());
      }
    }

    try {
      final list = await repo.getAttendanceHistory(page: page);
      if (page == 1) {
        state = state.copyWith(
          records: AsyncValue.data(list),
          currentPage: 1,
          hasMore: list.length >= 15,
          isBackgroundSyncing: false,
        );
      } else {
        final currentList = state.records.value ?? [];
        state = state.copyWith(
          records: AsyncValue.data([...currentList, ...list]),
          currentPage: page,
          hasMore: list.length >= 15,
        );
      }
    } catch (e, st) {
      if (page == 1 && hasExistingRecords) {
        state = state.copyWith(isBackgroundSyncing: false);
      } else {
        state = state.copyWith(
          records: AsyncValue.error(e, st),
          isBackgroundSyncing: false,
        );
      }
    }
  }

  Future<void> refresh({bool isBackground = false}) async {
    await loadHistory(page: 1, isBackground: isBackground);
  }
}

final historyProvider =
    NotifierProvider<HistoryNotifier, HistoryState>(HistoryNotifier.new);
