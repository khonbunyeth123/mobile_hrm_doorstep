import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/calendar_event.dart';
import '../services/calendar_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

enum _CalendarViewMode { month, agenda }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  _CalendarViewMode _viewMode = _CalendarViewMode.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<String, List<CalendarEvent>> _monthCache = {};
  Map<DateTime, List<CalendarEvent>> _eventsByDay = {};
  List<CalendarEvent> _monthEvents = [];

  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdatedAt;

  @override
  void initState() {
    super.initState();
    _selectedDay = _dayKey(_focusedDay);
    _loadMonth(_focusedDay);
  }

  Future<void> _refresh() => _loadMonth(_focusedDay, force: true);

  Future<void> _loadMonth(DateTime month, {bool force = false}) async {
    final monthKey = DateFormat('yyyy-MM').format(month);
    if (!force && _monthCache.containsKey(monthKey)) {
      setState(() {
        _error = null;
        _isLoading = false;
        _applyEvents(_monthCache[monthKey] ?? []);
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await CalendarService.getCalendarEvents(monthKey);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        final rawData = (result['data'] as List?) ?? const [];
        final events = rawData
            .whereType<Map<String, dynamic>>()
            .map(CalendarEvent.fromJson)
            .toList()
          ..sort(_compareEvents);

        _monthCache[monthKey] = events;
        _applyEvents(events);
        _lastUpdatedAt = DateTime.now();
      } else {
        _error = result['message'] ?? 'Failed to load calendar events';
      }
    });
  }

  void _applyEvents(List<CalendarEvent> events) {
    _monthEvents = events;
    _eventsByDay = _groupEventsByDay(events);
  }

  Map<DateTime, List<CalendarEvent>> _groupEventsByDay(
    List<CalendarEvent> events,
  ) {
    final grouped = <DateTime, List<CalendarEvent>>{};

    for (final event in events) {
      final start = _dayKey(event.date);
      final end = _dayKey(event.endDate ?? event.date);

      for (var day = start;
          !day.isAfter(end);
          day = day.add(const Duration(days: 1))) {
        grouped.putIfAbsent(day, () => []);
        grouped[day]!.add(event);
      }
    }

    for (final list in grouped.values) {
      list.sort(_compareEvents);
    }

    return grouped;
  }

  List<CalendarEvent> _eventsForDay(DateTime day) {
    return _eventsByDay[_dayKey(day)] ?? const [];
  }

  List<CalendarEvent> _upcomingEvents() {
    final anchor = _dayKey(_selectedDay ?? _focusedDay);
    final items = _monthEvents
        .where((event) => !_dayKey(event.endDate ?? event.date).isBefore(anchor))
        .toList()
      ..sort(_compareEvents);
    return items;
  }

  List<CalendarEvent> _eventsForCurrentDay() {
    return _eventsForDay(_selectedDay ?? _focusedDay);
  }

  DateTime _dayKey(DateTime day) => DateTime(day.year, day.month, day.day);

  int _compareEvents(CalendarEvent a, CalendarEvent b) {
    final dateCompare = a.date.compareTo(b.date);
    if (dateCompare != 0) return dateCompare;

    final typeCompare = _typeOrder(a.type).compareTo(_typeOrder(b.type));
    if (typeCompare != 0) return typeCompare;

    final statusCompare = _statusOrder(a.status).compareTo(_statusOrder(b.status));
    if (statusCompare != 0) return statusCompare;

    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  int _typeOrder(String type) {
    switch (type) {
      case 'holiday':
        return 0;
      case 'leave':
        return 1;
      case 'shift':
        return 2;
      case 'event':
        return 3;
      case 'reminder':
        return 4;
      case 'attendance':
        return 5;
      default:
        return 6;
    }
  }

  int _statusOrder(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 0;
      case 'confirmed':
        return 1;
      case 'pending':
        return 2;
      case 'assigned':
        return 3;
      case 'public':
        return 4;
      case 'scheduled':
        return 5;
      case 'rejected':
        return 6;
      default:
        return 7;
    }
  }

  int _countDaysWhere(bool Function(CalendarEvent event) predicate) {
    final days = <DateTime>{};

    for (final event in _monthEvents.where(predicate)) {
      final start = _dayKey(event.date);
      final end = _dayKey(event.endDate ?? event.date);
      for (var day = start;
          !day.isAfter(end);
          day = day.add(const Duration(days: 1))) {
        days.add(day);
      }
    }

    return days.length;
  }

  int _countEventsWhere(bool Function(CalendarEvent event) predicate) {
    return _monthEvents.where(predicate).length;
  }

  String _formatMonthLabel(DateTime date) => DateFormat('MMMM yyyy').format(date);

  String _formatDayLabel(DateTime date) {
    final today = _dayKey(DateTime.now());
    final day = _dayKey(date);
    if (isSameDay(day, today)) return 'Today';
    return DateFormat('EEEE, MMM d').format(date);
  }

  String _formatRelativeUpdated(DateTime? updated) {
    if (updated == null) return 'Live schedule';
    final diff = DateTime.now().difference(updated);
    if (diff.inMinutes < 1) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    return 'Updated ${DateFormat('MMM d, h:mm a').format(updated)}';
  }

  String _prettyLabel(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  String _eventTypeLabel(CalendarEvent event) {
    switch (event.type) {
      case 'holiday':
        return 'Company holiday';
      case 'leave':
        return event.status == 'approved' ? 'Approved leave' : 'Leave request';
      case 'shift':
        return 'Assigned shift';
      case 'reminder':
        return 'Reminder';
      case 'event':
        return event.isPublic ? 'Company event' : 'Event';
      case 'attendance':
        return 'Attendance';
      default:
        return 'Personal schedule';
    }
  }

  String _eventStatusLabel(CalendarEvent event) {
    switch (event.type) {
      case 'holiday':
        return 'Holiday';
      case 'shift':
        return event.status.isNotEmpty ? _prettyLabel(event.status) : 'Assigned';
      case 'leave':
        if (event.status.isNotEmpty) return _prettyLabel(event.status);
        return 'Leave';
      case 'reminder':
        return 'Reminder';
      case 'event':
        return event.isPublic ? 'Read only' : 'Scheduled';
      default:
        return event.status.isNotEmpty ? _prettyLabel(event.status) : 'Scheduled';
    }
  }

  Color _eventStatusColor(CalendarEvent event) {
    switch (event.status.toLowerCase()) {
      case 'approved':
      case 'confirmed':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      case 'rejected':
        return AppTheme.danger;
      case 'public':
        return AppTheme.brand;
      case 'assigned':
        return AppTheme.brand;
      case 'reminder':
        return AppTheme.accent;
      default:
        return event.color;
    }
  }

  String _eventTimeLabel(CalendarEvent event) {
    if (event.isAllDay) return 'All day';
    if (event.timeLabel != null && event.timeLabel!.isNotEmpty) {
      return event.timeLabel!;
    }
    return DateFormat('h:mm a').format(event.date);
  }

  bool _isPublicReadonly(CalendarEvent event) {
    return event.isPublic;
  }

  void _showEventDetails(CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EventDetailsSheet(
        event: event,
        onRequestLeave: () {
          Navigator.pop(context);
          Navigator.pushNamed(this.context, '/leave-request');
        },
        onViewStatus: () {
          Navigator.pop(context);
          Navigator.pushNamed(this.context, '/history');
        },
      ),
    );
  }

  void _setViewMode(_CalendarViewMode mode) {
    if (_viewMode == mode) return;
    setState(() => _viewMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeroCard()),
            SliverToBoxAdapter(child: _buildViewModeToggle()),
            SliverToBoxAdapter(child: _buildStatsSection()),
            SliverToBoxAdapter(child: _buildLegendCard()),
            if (_viewMode == _CalendarViewMode.month) ...[
              SliverToBoxAdapter(child: _buildMonthSection()),
              SliverToBoxAdapter(child: _buildSelectedDaySection()),
            ] else ...[
              SliverToBoxAdapter(child: _buildAgendaHeader()),
              if (_error != null)
                SliverToBoxAdapter(child: _buildErrorState())
              else if (_isLoading && _monthEvents.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_upcomingEvents().isEmpty)
                SliverToBoxAdapter(child: _buildEmptyAgenda())
              else
                SliverToBoxAdapter(child: _buildAgendaList()),
            ],
            SliverToBoxAdapter(child: _buildQuickActionsCard()),
            SliverToBoxAdapter(child: _buildPermissionCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final selectedMonth = _formatMonthLabel(_focusedDay);
    final updatedText = _formatRelativeUpdated(_lastUpdatedAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.brandDark, AppTheme.brand],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brand.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -16,
              child: Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -18,
              bottom: -26,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedMonth,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your schedule, leave, shifts, holidays, and reminders in one fast mobile view.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroChip(
                        icon: Icons.lock_rounded,
                        label: 'Own data only',
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                      ),
                      _HeroChip(
                        icon: Icons.celebration_rounded,
                        label: 'Public company events',
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                      ),
                      _HeroChip(
                        icon: Icons.notifications_active_rounded,
                        label: 'Push approvals',
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          updatedText,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AppStatusPill(
                        label: _viewMode == _CalendarViewMode.month ? 'Month' : 'Agenda',
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        icon: _viewMode == _CalendarViewMode.month
                            ? Icons.grid_view_rounded
                            : Icons.view_agenda_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              child: _ModeButton(
                icon: Icons.calendar_view_month_rounded,
                label: 'Month view',
                selected: _viewMode == _CalendarViewMode.month,
                onTap: () => _setViewMode(_CalendarViewMode.month),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ModeButton(
                icon: Icons.view_agenda_rounded,
                label: 'Agenda view',
                selected: _viewMode == _CalendarViewMode.agenda,
                onTap: () => _setViewMode(_CalendarViewMode.agenda),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final leaveDays = _countDaysWhere((event) => event.isLeave && event.status == 'approved');
    final pendingLeaves = _countEventsWhere((event) => event.isLeave && event.status == 'pending');
    final shiftDays = _countDaysWhere((event) => event.isShift);
    final holidayDays = _countDaysWhere((event) => event.isHoliday);
    final reminderCount = _countEventsWhere((event) => event.isReminder);
    final publicEventCount = _countEventsWhere(
      (event) => event.isPublic && !event.isHoliday && !event.isReminder,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: tileWidth,
                child: AppStatCard(
                  icon: Icons.event_available_rounded,
                  label: 'Approved leave days',
                  value: '$leaveDays',
                  accent: AppTheme.success,
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: AppStatCard(
                  icon: Icons.work_history_rounded,
                  label: 'Assigned shifts',
                  value: '$shiftDays',
                  accent: AppTheme.brand,
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: AppStatCard(
                  icon: Icons.celebration_rounded,
                  label: 'Company holidays',
                  value: '$holidayDays',
                  accent: const Color(0xFFF59E0B),
                ),
              ),
              SizedBox(
                width: tileWidth,
                child: AppStatCard(
                  icon: Icons.timelapse_rounded,
                  label: 'Pending leave',
                  value: '$pendingLeaves',
                  accent: AppTheme.warning,
                ),
              ),
              if (reminderCount > 0 || publicEventCount > 0)
                SizedBox(
                  width: constraints.maxWidth,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (reminderCount > 0)
                        AppStatusPill(
                          label: '$reminderCount reminders',
                          color: AppTheme.accent,
                          backgroundColor: AppTheme.accentSoft,
                          icon: Icons.notifications_rounded,
                        ),
                      if (publicEventCount > 0)
                        AppStatusPill(
                          label: '$publicEventCount company events',
                          color: AppTheme.textSecondary,
                          backgroundColor: AppTheme.backgroundAlt,
                          icon: Icons.event_rounded,
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _LegendItem(label: 'Leave', color: AppTheme.success),
            _LegendItem(label: 'Holiday', color: const Color(0xFFF59E0B)),
            _LegendItem(label: 'Shift', color: AppTheme.brand),
            _LegendItem(label: 'Reminder', color: AppTheme.accent),
            _LegendItem(label: 'Read only', color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppSurfaceCard(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: TableCalendar<CalendarEvent>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _eventsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
            leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppTheme.brand),
            rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppTheme.brand),
          ),
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              color: AppTheme.brandSoft,
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              color: AppTheme.brand,
              fontWeight: FontWeight.bold,
            ),
            selectedDecoration: BoxDecoration(
              color: AppTheme.brand,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            markerDecoration: BoxDecoration(
              color: AppTheme.brand,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = _dayKey(selectedDay);
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
              _selectedDay = _dayKey(focusedDay);
            });
            _loadMonth(focusedDay);
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return null;
              return Positioned(
                bottom: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: events.take(3).map((event) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: event.color,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDaySection() {
    final selectedDate = _selectedDay ?? _focusedDay;
    final events = _eventsForCurrentDay();
    final monthLabel = _formatDayLabel(selectedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: monthLabel,
            subtitle: events.isEmpty
                ? 'No schedule items for this day.'
                : '${events.length} item${events.length == 1 ? '' : 's'} on this date',
          ),
          const SizedBox(height: 12),
          if (_error != null)
            _buildErrorState()
          else if (_isLoading && events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (events.isEmpty)
            _buildEmptyDayState()
          else
            ...events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEventCard(event),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAgendaHeader() {
    final label = _formatDayLabel(_selectedDay ?? _focusedDay);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppSectionHeader(
        title: 'Agenda',
        subtitle: 'Upcoming items starting from $label.',
      ),
    );
  }

  Widget _buildAgendaList() {
    final events = _upcomingEvents();
    final grouped = <DateTime, List<CalendarEvent>>{};
    for (final event in events) {
      final day = _dayKey(event.date);
      grouped.putIfAbsent(day, () => []);
      grouped[day]!.add(event);
    }

    final days = grouped.keys.toList()..sort();
    final widgets = <Widget>[];

    for (final day in days) {
      final dayEvents = grouped[day]!;
      widgets.add(
        Padding(
          padding: EdgeInsets.fromLTRB(16, widgets.isEmpty ? 12 : 20, 16, 0),
          child: Text(
            _formatDayLabel(day),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      );
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: dayEvents
                .map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildEventCard(event),
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    return Column(children: widgets);
  }

  Widget _buildEmptyAgenda() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppEmptyState(
        icon: Icons.event_busy_rounded,
        title: 'Nothing upcoming',
        message:
            'There are no calendar items in this month yet. Approved leave, shifts, company holidays, and reminders will appear here as soon as they are assigned.',
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load calendar',
        message: _error ?? 'Something went wrong while loading this month.',
        actionLabel: 'Try again',
        onAction: () => _refresh(),
      ),
    );
  }

  Widget _buildEmptyDayState() {
    return AppEmptyState(
      icon: Icons.event_available_rounded,
      title: 'No items for this day',
      message:
          'You can request leave, and company holiday or shift updates will show up here when they are assigned.',
      actionLabel: 'Request leave',
      onAction: () => Navigator.pushNamed(context, '/leave-request'),
    );
  }

  Widget _buildQuickActionsCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Request leave, review status, or open push notifications.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/leave-request'),
                icon: const Icon(Icons.event_note_rounded),
                label: const Text('Request leave'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/history'),
                icon: const Icon(Icons.fact_check_rounded),
                label: const Text('View leave status'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
                icon: const Icon(Icons.notifications_none_rounded),
                label: const Text('Open notifications'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppSurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.brandSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.lock_rounded, color: AppTheme.brand),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Employee view only',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'You can see your own schedule, approved leave, assigned shifts, and public company events. Admin-created company events are read-only.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    final statusColor = _eventStatusColor(event);
    final statusLabel = _eventStatusLabel(event);
    final typeLabel = _eventTypeLabel(event);
    final timeLabel = _eventTimeLabel(event);
    final readOnly = _isPublicReadonly(event);

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _showEventDetails(event),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _eventIcon(event),
              color: event.color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  typeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (event.subtitle != null && event.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                if (event.location != null && event.location!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.location!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppStatusPill(
                      label: statusLabel,
                      color: statusColor,
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                      icon: Icons.bolt_rounded,
                    ),
                    AppStatusPill(
                      label: timeLabel,
                      color: AppTheme.textSecondary,
                      backgroundColor: AppTheme.backgroundAlt,
                      icon: Icons.schedule_rounded,
                    ),
                    if (readOnly)
                      AppStatusPill(
                        label: 'Read only',
                        color: AppTheme.textSecondary,
                        backgroundColor: AppTheme.backgroundAlt,
                        icon: Icons.lock_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _eventIcon(CalendarEvent event) {
    switch (event.type) {
      case 'holiday':
        return Icons.celebration_rounded;
      case 'leave':
        return Icons.event_note_rounded;
      case 'shift':
        return Icons.work_history_rounded;
      case 'reminder':
        return Icons.notifications_active_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'attendance':
        return Icons.qr_code_scanner_rounded;
      default:
        return Icons.calendar_today_rounded;
    }
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected ? AppTheme.brandSoft : AppTheme.background;
    final textColor = selected ? AppTheme.brand : AppTheme.textSecondary;
    final borderColor = selected ? AppTheme.brand.withValues(alpha: 0.2) : const Color(0xFFD9E6F8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;

  const _HeroChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppStatusPill(
      label: label,
      color: color,
      backgroundColor: color.withValues(alpha: 0.1),
      icon: Icons.circle_rounded,
    );
  }
}

class _EventDetailsSheet extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onRequestLeave;
  final VoidCallback onViewStatus;

  const _EventDetailsSheet({
    required this.event,
    required this.onRequestLeave,
    required this.onViewStatus,
  });

  String _prettyLabel(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  String _statusLabel() {
    switch (event.type) {
      case 'holiday':
        return 'Holiday';
      case 'leave':
        return event.status.isNotEmpty ? _prettyLabel(event.status) : 'Leave';
      case 'shift':
        return event.status.isNotEmpty ? _prettyLabel(event.status) : 'Assigned';
      case 'reminder':
        return 'Reminder';
      case 'event':
        return event.isPublic ? 'Read only' : 'Scheduled';
      default:
        return event.status.isNotEmpty ? _prettyLabel(event.status) : 'Scheduled';
    }
  }

  Color _statusColor() {
    switch (event.status.toLowerCase()) {
      case 'approved':
      case 'confirmed':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      case 'rejected':
        return AppTheme.danger;
      case 'public':
      case 'assigned':
        return AppTheme.brand;
      case 'reminder':
        return AppTheme.accent;
      default:
        return event.color;
    }
  }

  String _formatDateRange() {
    final start = DateFormat('EEEE, MMM d, yyyy').format(event.date);
    final endDate = event.endDate;
    if (endDate == null || endDate.isAtSameMomentAs(event.date)) {
      return start;
    }
    return '$start - ${DateFormat('EEEE, MMM d, yyyy').format(endDate)}';
  }

  String _timeLabel() {
    if (event.isAllDay) return 'All day';
    if (event.timeLabel != null && event.timeLabel!.isNotEmpty) {
      return event.timeLabel!;
    }
    return DateFormat('h:mm a').format(event.date);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: event.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      _eventIcon(),
                      color: event.color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateRange(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppStatusPill(
                    label: _statusLabel(),
                    color: _statusColor(),
                    backgroundColor: _statusColor().withValues(alpha: 0.1),
                    icon: Icons.bolt_rounded,
                  ),
                  AppStatusPill(
                    label: _timeLabel(),
                    color: AppTheme.textSecondary,
                    backgroundColor: AppTheme.backgroundAlt,
                    icon: Icons.schedule_rounded,
                  ),
                  if (event.isPublic)
                    AppStatusPill(
                      label: 'Read only',
                      color: AppTheme.textSecondary,
                      backgroundColor: AppTheme.backgroundAlt,
                      icon: Icons.lock_rounded,
                    ),
                ],
              ),
              if (event.subtitle != null && event.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  event.subtitle!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
              if (event.description != null && event.description!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  event.description!,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              if (event.location != null && event.location!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              if (event.type == 'leave')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onViewStatus,
                    icon: const Icon(Icons.fact_check_rounded),
                    label: const Text('View leave status'),
                  ),
                )
              else if (event.isPublic)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onRequestLeave,
                    icon: const Icon(Icons.event_note_rounded),
                    label: const Text('Request leave'),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Dismiss'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _eventIcon() {
    switch (event.type) {
      case 'holiday':
        return Icons.celebration_rounded;
      case 'leave':
        return Icons.event_note_rounded;
      case 'shift':
        return Icons.work_history_rounded;
      case 'reminder':
        return Icons.notifications_active_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'attendance':
        return Icons.qr_code_scanner_rounded;
      default:
        return Icons.calendar_today_rounded;
    }
  }
}
