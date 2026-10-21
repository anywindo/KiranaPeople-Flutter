import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/attendance_model.dart';
import '../data/repositories/attendance_repository.dart';
import 'auth_provider.dart';

class HistoryState {
  final AsyncValue<List<AttendanceRecord>> records;
  final int currentPage;
  final bool hasMore;

  const HistoryState({
    this.records = const AsyncValue.loading(),
    this.currentPage = 1,
    this.hasMore = true,
  });

  HistoryState copyWith({
    AsyncValue<List<AttendanceRecord>>? records,
    int? currentPage,
    bool? hasMore,
  }) {
    return HistoryState(
      records: records ?? this.records,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
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

  Future<void> loadHistory({int page = 1}) async {
    // Prevent fetching or retaining state when not authenticated
    if (!ref.read(authProvider).isAuthenticated) {
      state = const HistoryState();
      return;
    }

    final repo = ref.read(attendanceRepositoryProvider);
    if (page == 1) {
      state = state.copyWith(records: const AsyncValue.loading());
    }

    try {
      final list = await repo.getAttendanceHistory(page: page);
      if (page == 1) {
        state = state.copyWith(
          records: AsyncValue.data(list),
          currentPage: 1,
          hasMore: list.length >= 15,
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
      state = state.copyWith(records: AsyncValue.error(e, st));
    }
  }

  Future<void> refresh() async {
    await loadHistory(page: 1);
  }
}

final historyProvider =
    NotifierProvider<HistoryNotifier, HistoryState>(HistoryNotifier.new);
