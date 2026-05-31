import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../data/calendar_repository.dart';
import '../models/calendar_event.dart';
import '../models/calendar_feed.dart';
import '../models/calendar_filter_option.dart';
import '../models/calendar_query.dart';
import '../models/calendar_summary.dart';

enum CalendarViewMode { month, week, day }

class CalendarController extends ChangeNotifier {
  final CalendarRepository repository;

  CalendarController({
    CalendarRepository? repository,
  }) : repository = repository ??
            CalendarRepository(
              ApiClient(baseUrl: AppConfig.baseUrl),
            );

  CalendarViewMode viewMode = CalendarViewMode.month;
  DateTime focusedDate = DateTime.now();
  DateTime selectedDate = DateTime.now();

  List<CalendarEvent> events = [];
  CalendarSummary summary = CalendarSummary.empty();
  CalendarFilterOptions filterOptions = CalendarFilterOptions.empty();

  String? selectedEmployeeId;
  String? selectedDepartment;
  String? selectedBranch;
  String? selectedEventType;
  String? selectedStatus;

  bool loading = false;
  bool refreshing = false;
  bool filtersLoading = false;
  bool saving = false;
  String? error;
  DateTime? lastUpdatedAt;

  final Map<String, CalendarFeed> _cache = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await loadFilters();
    await refresh(force: true);
  }

  CalendarQuery get currentQuery {
    final range = _currentRange();
    return CalendarQuery(
      startDate: range.start,
      endDate: range.end,
      employeeId: selectedEmployeeId,
      department: selectedDepartment,
      branch: selectedBranch,
      eventType: selectedEventType,
      status: selectedStatus,
    );
  }

  DateTimeRange _currentRange() {
    final date = _stripTime(selectedDate);
    switch (viewMode) {
      case CalendarViewMode.month:
        final start = DateTime(date.year, date.month, 1);
        final end = DateTime(date.year, date.month + 1, 0);
        return DateTimeRange(start: start, end: end);
      case CalendarViewMode.week:
        final start = date.subtract(Duration(days: date.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return DateTimeRange(start: _stripTime(start), end: _stripTime(end));
      case CalendarViewMode.day:
        return DateTimeRange(start: date, end: date);
    }
  }

  Future<void> loadFilters() async {
    filtersLoading = true;
    notifyListeners();

    final result = await repository.fetchFilters();
    if (result.success && result.data != null) {
      filterOptions = result.data!;
    }

    filtersLoading = false;
    notifyListeners();
  }

  Future<void> refresh({bool force = false}) async {
    final query = currentQuery;
    final cacheKey = _cacheKey(query);

    if (!force && _cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      events = cached.events;
      summary = cached.summary;
      error = null;
      lastUpdatedAt = DateTime.now();
      notifyListeners();
      return;
    }

    error = null;
    if (events.isEmpty) {
      loading = true;
    } else {
      refreshing = true;
    }
    notifyListeners();

    final result = await repository.fetchEvents(query);
    if (result.success && result.data != null) {
      final feed = result.data!;
      events = feed.events;
      summary = feed.summary;
      _cache[cacheKey] = feed;
      lastUpdatedAt = DateTime.now();
    } else {
      error = result.message ?? 'Failed to load calendar events';
    }

    loading = false;
    refreshing = false;
    notifyListeners();
  }

  Future<void> setViewMode(CalendarViewMode mode) async {
    if (viewMode == mode) return;
    viewMode = mode;
    notifyListeners();
    await refresh();
  }

  Future<void> selectDate(DateTime date) async {
    selectedDate = _stripTime(date);
    focusedDate = selectedDate;
    notifyListeners();
    await refresh();
  }

  Future<void> today() async {
    selectedDate = _stripTime(DateTime.now());
    focusedDate = selectedDate;
    notifyListeners();
    await refresh(force: true);
  }

  Future<void> previous() async {
    switch (viewMode) {
      case CalendarViewMode.month:
        selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
        focusedDate = selectedDate;
        break;
      case CalendarViewMode.week:
        selectedDate = selectedDate.subtract(const Duration(days: 7));
        focusedDate = selectedDate;
        break;
      case CalendarViewMode.day:
        selectedDate = selectedDate.subtract(const Duration(days: 1));
        focusedDate = selectedDate;
        break;
    }
    notifyListeners();
    await refresh(force: true);
  }

  Future<void> next() async {
    switch (viewMode) {
      case CalendarViewMode.month:
        selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
        focusedDate = selectedDate;
        break;
      case CalendarViewMode.week:
        selectedDate = selectedDate.add(const Duration(days: 7));
        focusedDate = selectedDate;
        break;
      case CalendarViewMode.day:
        selectedDate = selectedDate.add(const Duration(days: 1));
        focusedDate = selectedDate;
        break;
    }
    notifyListeners();
    await refresh(force: true);
  }

  Future<void> applyFilters({
    String? employeeId,
    String? department,
    String? branch,
    String? eventType,
    String? status,
  }) async {
    selectedEmployeeId = employeeId;
    selectedDepartment = department;
    selectedBranch = branch;
    selectedEventType = eventType;
    selectedStatus = status;
    await refresh(force: true);
  }

  Future<void> clearFilters() async {
    selectedEmployeeId = null;
    selectedDepartment = null;
    selectedBranch = null;
    selectedEventType = null;
    selectedStatus = null;
    await refresh(force: true);
  }

  List<CalendarEvent> eventsForDate(DateTime date) {
    final day = _stripTime(date);
    return events.where((event) {
      final start = _stripTime(event.startAt);
      final end = _stripTime(event.endAt);
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList()
      ..sort(_sortEvents);
  }

  Map<DateTime, List<CalendarEvent>> groupedEvents() {
    final grouped = <DateTime, List<CalendarEvent>>{};
    for (final event in events) {
      final start = _stripTime(event.startAt);
      final end = _stripTime(event.endAt);
      for (var day = start; !day.isAfter(end); day = day.add(const Duration(days: 1))) {
        grouped.putIfAbsent(day, () => []);
        grouped[day]!.add(event);
      }
    }
    for (final entry in grouped.entries) {
      entry.value.sort(_sortEvents);
    }
    return grouped;
  }

  List<CalendarEvent> get upcomingEvents {
    final anchor = _stripTime(selectedDate);
    final list = events.where((event) {
      return !_stripTime(event.endAt).isBefore(anchor);
    }).toList()
      ..sort(_sortEvents);
    return list;
  }

  bool get hasActiveFilters {
    return selectedEmployeeId != null ||
        selectedDepartment != null ||
        selectedBranch != null ||
        selectedEventType != null ||
        selectedStatus != null;
  }

  Future<ApiResult<void>> saveEvent({
    required CalendarEvent event,
    required bool isEdit,
  }) async {
    saving = true;
    error = null;
    notifyListeners();

    final result = isEdit
        ? await repository.updateEvent(event.uuid, event.toRequestJson())
        : await repository.createEvent(event.toRequestJson());

    saving = false;

    if (result.success) {
      await refresh(force: true);
      return ApiResult.ok(message: result.message, statusCode: result.statusCode, raw: result.raw);
    }

    error = result.message;
    notifyListeners();
    return ApiResult.fail(message: result.message, statusCode: result.statusCode, raw: result.raw);
  }

  Future<ApiResult<void>> deleteEvent(CalendarEvent event) async {
    if (event.readOnly) {
      return ApiResult.fail(message: 'Leave items are read-only.');
    }

    saving = true;
    notifyListeners();
    final result = await repository.deleteEvent(event.uuid);
    saving = false;
    if (result.success) {
      await refresh(force: true);
    } else {
      error = result.message;
      notifyListeners();
    }
    return result;
  }

  Future<ApiResult<void>> approveLeave(CalendarEvent event) async {
    final leaveUuid = event.leaveUuid ?? event.uuid;
    saving = true;
    notifyListeners();
    final result = await repository.approveLeave(leaveUuid);
    saving = false;
    if (result.success) {
      await refresh(force: true);
      return ApiResult.ok(message: result.message, statusCode: result.statusCode, raw: result.raw);
    } else {
      error = result.message;
      notifyListeners();
      return ApiResult.fail(message: result.message, statusCode: result.statusCode, raw: result.raw);
    }
  }

  Future<ApiResult<void>> rejectLeave(CalendarEvent event) async {
    final leaveUuid = event.leaveUuid ?? event.uuid;
    saving = true;
    notifyListeners();
    final result = await repository.rejectLeave(leaveUuid);
    saving = false;
    if (result.success) {
      await refresh(force: true);
      return ApiResult.ok(message: result.message, statusCode: result.statusCode, raw: result.raw);
    } else {
      error = result.message;
      notifyListeners();
      return ApiResult.fail(message: result.message, statusCode: result.statusCode, raw: result.raw);
    }
  }

  int countByStatus(String status) => summary.countFor(status);

  String _cacheKey(CalendarQuery query) {
    return [
      query.startDate.toIso8601String(),
      query.endDate.toIso8601String(),
      query.employeeId ?? '',
      query.department ?? '',
      query.branch ?? '',
      query.eventType ?? '',
      query.status ?? '',
      viewMode.name,
    ].join('|');
  }

  DateTime _stripTime(DateTime date) => DateTime(date.year, date.month, date.day);

  int _sortEvents(CalendarEvent a, CalendarEvent b) {
    final start = a.startAt.compareTo(b.startAt);
    if (start != 0) return start;
    if (a.isLeave != b.isLeave) return a.isLeave ? 1 : -1;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }
}
