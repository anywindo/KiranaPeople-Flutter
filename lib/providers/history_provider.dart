import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/attendance_model.dart';
import 'attendance_provider.dart';

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
    Future.microtask(() => loadHistory(page: 1));
    return const HistoryState();
  }

  Future<void> loadHistory({int page = 1}) async {
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
          hasMore: list.isNotEmpty,
        );
      } else {
        final currentList = state.records.value ?? [];
        state = state.copyWith(
          records: AsyncValue.data([...currentList, ...list]),
          currentPage: page,
          hasMore: list.isNotEmpty,
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
