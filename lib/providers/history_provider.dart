import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/attendance_model.dart';
import '../data/repositories/attendance_repository.dart';
import 'auth_provider.dart';

enum AttendanceHistoryStatusFilter {
  all('Semua'),
  onTime('Tepat Waktu'),
  late('Terlambat');

  final String label;
  const AttendanceHistoryStatusFilter(this.label);
}

class HistoryFilter {
  final AttendanceHistoryStatusFilter status;
  final DateTimeRange? dateRange;
  final String? dateRangeLabel;
  final String? shift;

  const HistoryFilter({
    this.status = AttendanceHistoryStatusFilter.all,
    this.dateRange,
    this.dateRangeLabel,
    this.shift,
  });

  bool get isActive =>
      status != AttendanceHistoryStatusFilter.all ||
      dateRange != null ||
      (shift != null && shift != 'Semua Shift');

  int get activeFilterCount {
    int count = 0;
    if (status != AttendanceHistoryStatusFilter.all) count++;
    if (dateRange != null) count++;
    if (shift != null && shift != 'Semua Shift') count++;
    return count;
  }

  HistoryFilter copyWith({
    AttendanceHistoryStatusFilter? status,
    DateTimeRange? Function()? dateRange,
    String? Function()? dateRangeLabel,
    String? Function()? shift,
  }) {
    return HistoryFilter(
      status: status ?? this.status,
      dateRange: dateRange != null ? dateRange() : this.dateRange,
      dateRangeLabel:
          dateRangeLabel != null ? dateRangeLabel() : this.dateRangeLabel,
      shift: shift != null ? shift() : this.shift,
    );
  }
}

class HistoryState {
  final AsyncValue<List<AttendanceRecord>> records;
  final int currentPage;
  final bool hasMore;
  final bool isBackgroundSyncing;
  final HistoryFilter filter;

  const HistoryState({
    this.records = const AsyncValue.loading(),
    this.currentPage = 1,
    this.hasMore = true,
    this.isBackgroundSyncing = false,
    this.filter = const HistoryFilter(),
  });

  HistoryState copyWith({
    AsyncValue<List<AttendanceRecord>>? records,
    int? currentPage,
    bool? hasMore,
    bool? isBackgroundSyncing,
    HistoryFilter? filter,
  }) {
    return HistoryState(
      records: records ?? this.records,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isBackgroundSyncing: isBackgroundSyncing ?? this.isBackgroundSyncing,
      filter: filter ?? this.filter,
    );
  }

  List<AttendanceRecord> get filteredRecords {
    final list = records.value ?? [];
    if (!filter.isActive) return list;

    return list.where((item) {
      // 1. Status Filter
      if (filter.status != AttendanceHistoryStatusFilter.all) {
        final rawStatus = (item.status ?? '').toUpperCase();
        final isLate = rawStatus == 'LATE' ||
            rawStatus.contains('TERLAMBAT') ||
            (item.status?.toLowerCase().contains('terlambat') ?? false);

        if (filter.status == AttendanceHistoryStatusFilter.late && !isLate) {
          return false;
        }
        if (filter.status == AttendanceHistoryStatusFilter.onTime && isLate) {
          return false;
        }
      }

      // 2. Date Range Filter
      if (filter.dateRange != null) {
        final dt = DateTime.tryParse(item.date);
        if (dt != null) {
          final day = DateTime(dt.year, dt.month, dt.day);
          final start = DateTime(
            filter.dateRange!.start.year,
            filter.dateRange!.start.month,
            filter.dateRange!.start.day,
          );
          final end = DateTime(
            filter.dateRange!.end.year,
            filter.dateRange!.end.month,
            filter.dateRange!.end.day,
          );
          if (day.isBefore(start) || day.isAfter(end)) {
            return false;
          }
        }
      }

      // 3. Shift Filter
      if (filter.shift != null &&
          filter.shift!.isNotEmpty &&
          filter.shift != 'Semua Shift') {
        final shiftName = item.shift?.name ?? '';
        if (shiftName.toLowerCase() != filter.shift!.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<String> get availableShifts {
    final list = records.value ?? [];
    final names = <String>{};
    for (final item in list) {
      final name = item.shift?.name.trim();
      if (name != null && name.isNotEmpty) {
        names.add(name);
      }
    }
    return ['Semua Shift', ...names];
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

  void setStatusFilter(AttendanceHistoryStatusFilter status) {
    state = state.copyWith(
      filter: state.filter.copyWith(status: status),
    );
  }

  void setDateRangeFilter(DateTimeRange? range, [String? label]) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        dateRange: () => range,
        dateRangeLabel: () => label,
      ),
    );
  }

  void setShiftFilter(String? shift) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        shift: () => shift,
      ),
    );
  }

  void resetFilter() {
    state = state.copyWith(
      filter: const HistoryFilter(),
    );
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
      final statusParam = switch (state.filter.status) {
        AttendanceHistoryStatusFilter.all => null,
        AttendanceHistoryStatusFilter.onTime => 'EXACT',
        AttendanceHistoryStatusFilter.late => 'LATE',
      };
      final startDateParam = state.filter.dateRange != null
          ? '${state.filter.dateRange!.start.year}-${state.filter.dateRange!.start.month.toString().padLeft(2, '0')}-${state.filter.dateRange!.start.day.toString().padLeft(2, '0')}'
          : null;
      final endDateParam = state.filter.dateRange != null
          ? '${state.filter.dateRange!.end.year}-${state.filter.dateRange!.end.month.toString().padLeft(2, '0')}-${state.filter.dateRange!.end.day.toString().padLeft(2, '0')}'
          : null;

      final list = await repo.getAttendanceHistory(
        page: page,
        status: statusParam,
        startDate: startDateParam,
        endDate: endDateParam,
      );
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
