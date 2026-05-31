import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/auth/auth_service.dart';
import '../../../widgets/app_ui.dart';
import '../../../theme/app_theme.dart';
import '../models/calendar_event.dart';
import '../models/calendar_filter_option.dart';
import '../state/calendar_controller.dart';
import 'calendar_event_form_screen.dart';

class AdminCalendarHomeScreen extends StatefulWidget {
  const AdminCalendarHomeScreen({super.key});

  @override
  State<AdminCalendarHomeScreen> createState() => _AdminCalendarHomeScreenState();
}

class _AdminCalendarHomeScreenState extends State<AdminCalendarHomeScreen> {
  late final CalendarController controller;

  @override
  void initState() {
    super.initState();
    controller = CalendarController();
    controller.init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await controller.refresh(force: true);
  }

  Future<void> _openCreateForm({CalendarEvent? initialEvent}) async {
    final result = await Navigator.push<CalendarEvent>(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarEventFormScreen(initialEvent: initialEvent),
      ),
    );

    if (result == null) return;

    final response = await controller.saveEvent(
      event: result,
      isEdit: initialEvent != null,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.success
              ? (initialEvent == null ? 'Event created' : 'Event updated')
              : (response.message ?? 'Failed to save event'),
        ),
      ),
    );
  }

  Future<void> _openEventDetails(CalendarEvent event) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AdminEventDetailsSheet(
          event: event,
          onEdit: event.readOnly ? null : () {
            Navigator.pop(context);
            _openCreateForm(initialEvent: event);
          },
          onDelete: event.readOnly
              ? null
              : () async {
                  Navigator.pop(context);
                  final response = await controller.deleteEvent(event);
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text(response.message ?? 'Event deleted')),
                  );
                },
          onApproveLeave: event.isLeave
              ? () async {
                  final response = await controller.approveLeave(event);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response.message ?? 'Leave approved')),
                  );
                }
              : null,
          onRejectLeave: event.isLeave
              ? () async {
                  final response = await controller.rejectLeave(event);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response.message ?? 'Leave rejected')),
                  );
                }
              : null,
          onCreateEvent: event.isLeave
              ? null
              : () {
                  Navigator.pop(context);
                  _openCreateForm(initialEvent: null);
                },
        );
      },
    );
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterPanel(controller: controller),
    );
  }

  String _monthLabel() {
    return DateFormat('MMMM yyyy').format(controller.selectedDate);
  }

  String _rangeLabel() {
    final date = controller.selectedDate;
    switch (controller.viewMode) {
      case CalendarViewMode.month:
        return DateFormat('MMMM yyyy').format(date);
      case CalendarViewMode.week:
        final start = date.subtract(Duration(days: date.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
      case CalendarViewMode.day:
        return DateFormat('EEEE, MMM d, yyyy').format(date);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      case 'rejected':
        return AppTheme.danger;
      case 'draft':
        return AppTheme.textSecondary;
      case 'published':
        return AppTheme.brand;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppTheme.brand;
    }
  }

  Color _eventColor(CalendarEvent event) {
    if (event.isLeave) {
      return _statusColor(event.status);
    }
    switch (event.eventType.toLowerCase()) {
      case 'holiday':
        return const Color(0xFFF59E0B);
      case 'reminder':
        return AppTheme.accent;
      case 'shift':
        return AppTheme.brand;
      case 'meeting':
        return const Color(0xFF7C3AED);
      default:
        return AppTheme.brand;
    }
  }

  String _eventTypeLabel(CalendarEvent event) {
    if (event.isLeave) return 'Leave';
    final raw = event.eventType.replaceAll('_', ' ').trim();
    if (raw.isEmpty) return 'Event';
    return raw
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _formatActiveFilter(String label, String? value) {
    if (value == null || value.isEmpty) return '';
    return '$label: $value';
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New event'),
      ),
      appBar: AppBar(
        title: const Text('Calendar Admin'),
        actions: [
          IconButton(
            onPressed: controller.loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _openFilters,
            icon: Stack(
              children: [
                const Icon(Icons.tune_rounded),
                if (controller.hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filters',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth > 1100 ? 1100.0 : double.infinity;
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: _HeroHeader(
                              monthLabel: _monthLabel(),
                              rangeLabel: _rangeLabel(),
                              refreshing: controller.refreshing,
                              lastUpdatedAt: controller.lastUpdatedAt,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: _Toolbar(
                              viewMode: controller.viewMode,
                              onMonth: () => controller.setViewMode(CalendarViewMode.month),
                              onWeek: () => controller.setViewMode(CalendarViewMode.week),
                              onDay: () => controller.setViewMode(CalendarViewMode.day),
                              onPrevious: controller.previous,
                              onNext: controller.next,
                              onToday: controller.today,
                              onFilters: _openFilters,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: _SummaryStrip(controller: controller),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: _FilterChips(
                              controller: controller,
                              onClear: controller.hasActiveFilters ? controller.clearFilters : null,
                              labelBuilder: _formatActiveFilter,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (controller.loading && controller.events.isEmpty)
                      const SliverToBoxAdapter(child: _LoadingSkeleton())
                    else if (controller.error != null)
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: AppEmptyState(
                                icon: Icons.cloud_off_rounded,
                                title: 'Could not load calendar',
                                message: controller.error!,
                                actionLabel: 'Try again',
                                onAction: _refresh,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: _CalendarSurface(
                                controller: controller,
                                onDaySelected: controller.selectDate,
                                eventLoader: controller.eventsForDate,
                                onEventTap: _openEventDetails,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (!controller.loading || controller.events.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              child: _AgendaSection(
                                controller: controller,
                                onEventTap: _openEventDetails,
                                eventColorBuilder: _eventColor,
                                eventTypeLabelBuilder: _eventTypeLabel,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String monthLabel;
  final String rangeLabel;
  final bool refreshing;
  final DateTime? lastUpdatedAt;

  const _HeroHeader({
    required this.monthLabel,
    required this.rangeLabel,
    required this.refreshing,
    required this.lastUpdatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final updated = lastUpdatedAt == null
        ? 'Live calendar'
        : 'Updated ${DateFormat('MMM d, h:mm a').format(lastUpdatedAt!)}';

    return AppSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.brandDark, AppTheme.brand],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthLabel,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rangeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppStatusPill(
                      label: updated,
                      color: AppTheme.textSecondary,
                      backgroundColor: AppTheme.backgroundAlt,
                      icon: refreshing ? Icons.sync_rounded : Icons.schedule_rounded,
                    ),
                    const AppStatusPill(
                      label: 'Read only leaves',
                      color: AppTheme.warning,
                      backgroundColor: Color(0xFFFFF7E6),
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
}

class _Toolbar extends StatelessWidget {
  final CalendarViewMode viewMode;
  final VoidCallback onMonth;
  final VoidCallback onWeek;
  final VoidCallback onDay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onFilters;

  const _Toolbar({
    required this.viewMode,
    required this.onMonth,
    required this.onWeek,
    required this.onDay,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onFilters,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  label: 'Month',
                  selected: viewMode == CalendarViewMode.month,
                  onTap: onMonth,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModeButton(
                  label: 'Week',
                  selected: viewMode == CalendarViewMode.week,
                  onTap: onWeek,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ModeButton(
                  label: 'Day',
                  selected: viewMode == CalendarViewMode.day,
                  onTap: onDay,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onToday,
                  child: const Text('Today'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onFilters,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.brandSoft : AppTheme.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.brand.withValues(alpha: 0.25) : const Color(0xFFD9E6F8),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.brand : AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final CalendarController controller;

  const _SummaryStrip({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _SummaryCard(
        label: 'Total',
        value: controller.summary.totalTracked.toString(),
        accent: AppTheme.brand,
        icon: Icons.event_rounded,
      ),
      _SummaryCard(
        label: 'Approved',
        value: controller.countByStatus('approved').toString(),
        accent: AppTheme.success,
        icon: Icons.check_circle_rounded,
      ),
      _SummaryCard(
        label: 'Pending',
        value: controller.countByStatus('pending').toString(),
        accent: AppTheme.warning,
        icon: Icons.hourglass_bottom_rounded,
      ),
      _SummaryCard(
        label: 'Rejected',
        value: controller.countByStatus('rejected').toString(),
        accent: AppTheme.danger,
        icon: Icons.cancel_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = width >= 700 ? (width - 18) / 4 : (width - 12) / 2;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: cards
              .map((card) => SizedBox(width: itemWidth, child: card))
              .toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppStatCard(
      icon: icon,
      label: label,
      value: value,
      accent: accent,
    );
  }
}

class _FilterChips extends StatelessWidget {
  final CalendarController controller;
  final VoidCallback? onClear;
  final String Function(String label, String? value) labelBuilder;

  const _FilterChips({
    required this.controller,
    required this.onClear,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    final filters = <String>[
      labelBuilder('Employee', controller.selectedEmployeeId),
      labelBuilder('Department', controller.selectedDepartment),
      labelBuilder('Branch', controller.selectedBranch),
      labelBuilder('Type', controller.selectedEventType),
      labelBuilder('Status', controller.selectedStatus),
    ].where((item) => item.isNotEmpty).toList();

    if (filters.isEmpty) {
      return const AppSurfaceCard(
        padding: EdgeInsets.all(16),
        child: Text(
          'No filters applied. Use the panel to target employee, department, branch, event type, or status.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      );
    }

    for (final filter in filters) {
      chips.add(
        AppStatusPill(
          label: filter,
          color: AppTheme.textPrimary,
          backgroundColor: AppTheme.backgroundAlt,
          icon: Icons.filter_alt_rounded,
        ),
      );
    }

    if (onClear != null) {
      chips.add(
        ActionChip(
          label: const Text('Clear filters'),
          onPressed: onClear,
        ),
      );
    }

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }
}

class _CalendarSurface extends StatelessWidget {
  final CalendarController controller;
  final Future<void> Function(DateTime date) onDaySelected;
  final List<CalendarEvent> Function(DateTime date) eventLoader;
  final void Function(CalendarEvent event) onEventTap;

  const _CalendarSurface({
    required this.controller,
    required this.onDaySelected,
    required this.eventLoader,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.viewMode == CalendarViewMode.day) {
      return AppSurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMM d, yyyy').format(controller.selectedDate),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ..._buildDayAgenda(context),
          ],
        ),
      );
    }

    final format = controller.viewMode == CalendarViewMode.month
        ? CalendarFormat.month
        : CalendarFormat.week;

    return AppSurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: TableCalendar<CalendarEvent>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: controller.focusedDate,
        selectedDayPredicate: (day) => isSameDay(controller.selectedDate, day),
        calendarFormat: format,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Month',
          CalendarFormat.week: 'Week',
        },
        headerVisible: false,
        startingDayOfWeek: StartingDayOfWeek.monday,
        onDaySelected: (selectedDay, focusedDay) {
          onDaySelected(selectedDay);
        },
        onPageChanged: (focusedDay) {
          onDaySelected(focusedDay);
        },
        eventLoader: eventLoader,
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
                      color: _markerColor(event),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildDayAgenda(BuildContext context) {
    final events = eventLoader(controller.selectedDate);
    if (events.isEmpty) {
      return [
        const AppEmptyState(
          icon: Icons.event_busy_rounded,
          title: 'No events',
          message: 'There are no events on this day.',
        ),
      ];
    }

    return events
        .map(
          (event) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _EventCard(
              event: event,
              onTap: () => onEventTap(event),
              eventColor: _markerColor(event),
            ),
          ),
        )
        .toList();
  }

  Color _markerColor(CalendarEvent event) {
    if (event.isLeave) {
      switch (event.status.toLowerCase()) {
        case 'approved':
          return AppTheme.success;
        case 'pending':
          return AppTheme.warning;
        case 'rejected':
          return AppTheme.danger;
        default:
          return AppTheme.brand;
      }
    }
    switch (event.eventType.toLowerCase()) {
      case 'holiday':
        return const Color(0xFFF59E0B);
      case 'reminder':
        return AppTheme.accent;
      case 'shift':
        return AppTheme.brand;
      default:
        return AppTheme.brand;
    }
  }
}

class _AgendaSection extends StatelessWidget {
  final CalendarController controller;
  final void Function(CalendarEvent event) onEventTap;
  final Color Function(CalendarEvent event) eventColorBuilder;
  final String Function(CalendarEvent event) eventTypeLabelBuilder;

  const _AgendaSection({
    required this.controller,
    required this.onEventTap,
    required this.eventColorBuilder,
    required this.eventTypeLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = <DateTime, List<CalendarEvent>>{};
    final events = controller.viewMode == CalendarViewMode.day
        ? controller.eventsForDate(controller.selectedDate)
        : controller.upcomingEvents;

    for (final event in events) {
      final day = DateTime(event.startAt.year, event.startAt.month, event.startAt.day);
      grouped.putIfAbsent(day, () => []);
      grouped[day]!.add(event);
    }

    if (grouped.isEmpty) {
      return const AppSurfaceCard(
        padding: EdgeInsets.all(18),
        child: AppEmptyState(
          icon: Icons.event_busy_rounded,
          title: 'Nothing to show',
          message: 'There are no calendar events in the current range.',
        ),
      );
    }

    final sortedDays = grouped.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: controller.viewMode == CalendarViewMode.day ? 'Day agenda' : 'Agenda',
          subtitle: 'Events grouped by date.',
        ),
        const SizedBox(height: 12),
        ...sortedDays.expand((day) {
          final dayEvents = grouped[day] ?? const [];
          return [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                DateFormat('EEEE, MMM d, yyyy').format(day),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            ...dayEvents.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EventCard(
                  event: event,
                  onTap: () => onEventTap(event),
                  eventColor: eventColorBuilder(event),
                  typeLabel: eventTypeLabelBuilder(event),
                ),
              ),
            ),
          ];
        }),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onTap;
  final Color eventColor;
  final String? typeLabel;

  const _EventCard({
    required this.event,
    required this.onTap,
    required this.eventColor,
    this.typeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(event);
    final showLeaveActions = event.isLeave;

    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: eventColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(_icon(), color: eventColor),
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
                    if (event.readOnly)
                      const Icon(Icons.lock_rounded, size: 16, color: AppTheme.textSecondary),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  typeLabel ?? (event.isLeave ? 'Leave' : event.eventType),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description.isEmpty ? event.displayRange : event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppStatusPill(
                      label: event.status.toUpperCase(),
                      color: statusColor,
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                      icon: Icons.bolt_rounded,
                    ),
                    AppStatusPill(
                      label: event.allDay ? 'All day' : DateFormat('h:mm a').format(event.startAt),
                      color: AppTheme.textSecondary,
                      backgroundColor: AppTheme.backgroundAlt,
                      icon: Icons.schedule_rounded,
                    ),
                    if (event.recurrence != null && event.recurrence!.isNotEmpty)
                      AppStatusPill(
                        label: event.recurrenceLabel,
                        color: AppTheme.brand,
                        backgroundColor: AppTheme.brandSoft,
                        icon: Icons.repeat_rounded,
                      ),
                    if (showLeaveActions)
                      AppStatusPill(
                        label: 'Read only',
                        color: AppTheme.warning,
                        backgroundColor: const Color(0xFFFFF7E6),
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

  Color _statusColor(CalendarEvent event) {
    switch (event.status.toLowerCase()) {
      case 'approved':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      case 'rejected':
        return AppTheme.danger;
      case 'published':
        return AppTheme.brand;
      default:
        return eventColor;
    }
  }

  IconData _icon() {
    if (event.isLeave) return Icons.event_note_rounded;
    switch (event.eventType.toLowerCase()) {
      case 'holiday':
        return Icons.celebration_rounded;
      case 'shift':
        return Icons.work_history_rounded;
      case 'reminder':
        return Icons.notifications_active_rounded;
      case 'meeting':
        return Icons.groups_rounded;
      default:
        return Icons.event_rounded;
    }
  }
}

class _AdminEventDetailsSheet extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onApproveLeave;
  final VoidCallback? onRejectLeave;
  final VoidCallback? onCreateEvent;

  const _AdminEventDetailsSheet({
    required this.event,
    this.onEdit,
    this.onDelete,
    this.onApproveLeave,
    this.onRejectLeave,
    this.onCreateEvent,
  });

  Color _statusColor() {
    switch (event.status.toLowerCase()) {
      case 'approved':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      case 'rejected':
        return AppTheme.danger;
      case 'published':
        return AppTheme.brand;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _icon() {
    if (event.isLeave) return Icons.event_note_rounded;
    switch (event.eventType.toLowerCase()) {
      case 'holiday':
        return Icons.celebration_rounded;
      case 'shift':
        return Icons.work_history_rounded;
      case 'reminder':
        return Icons.notifications_active_rounded;
      default:
        return Icons.event_rounded;
    }
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
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(_icon(), color: _statusColor()),
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
                          event.displayRange,
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
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppStatusPill(
                    label: event.status.toUpperCase(),
                    color: _statusColor(),
                    backgroundColor: _statusColor().withValues(alpha: 0.1),
                    icon: Icons.bolt_rounded,
                  ),
                  AppStatusPill(
                    label: event.allDay ? 'All day' : DateFormat('h:mm a').format(event.startAt),
                    color: AppTheme.textSecondary,
                    backgroundColor: AppTheme.backgroundAlt,
                    icon: Icons.schedule_rounded,
                  ),
                  if (event.recurrence != null && event.recurrence!.isNotEmpty)
                    AppStatusPill(
                      label: event.recurrenceLabel,
                      color: AppTheme.brand,
                      backgroundColor: AppTheme.brandSoft,
                      icon: Icons.repeat_rounded,
                    ),
                ],
              ),
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  event.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
              if (event.targets.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Targets',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: event.targets
                      .map(
                        (target) => AppStatusPill(
                          label: target.displayLabel,
                          color: AppTheme.textPrimary,
                          backgroundColor: AppTheme.backgroundAlt,
                          icon: Icons.group_rounded,
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 18),
              if (event.isLeave) ...[
                if (onApproveLeave != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onApproveLeave,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Approve leave'),
                    ),
                  ),
                const SizedBox(height: 10),
                if (onRejectLeave != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onRejectLeave,
                      icon: const Icon(Icons.cancel_rounded),
                      label: const Text('Reject leave'),
                    ),
                  ),
              ] else ...[
                if (onEdit != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit event'),
                    ),
                  ),
                const SizedBox(height: 10),
                if (onDelete != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete event'),
                    ),
                  ),
              ],
              const SizedBox(height: 10),
              if (onCreateEvent != null)
                TextButton.icon(
                  onPressed: onCreateEvent,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create another event'),
                ),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterPanel extends StatefulWidget {
  final CalendarController controller;

  const _FilterPanel({required this.controller});

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  String? employeeId;
  String? department;
  String? branch;
  String? eventType;
  String? status;

  @override
  void initState() {
    super.initState();
    employeeId = widget.controller.selectedEmployeeId;
    department = widget.controller.selectedDepartment;
    branch = widget.controller.selectedBranch;
    eventType = widget.controller.selectedEventType;
    status = widget.controller.selectedStatus;
  }

  List<DropdownMenuItem<String?>> _menuItems(List<CalendarLookupOption> options) {
    return [
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Any'),
      ),
      ...options.map(
        (option) => DropdownMenuItem<String?>(
          value: option.value,
          child: Text(option.label.isEmpty ? option.value : option.label),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filters = widget.controller.filterOptions;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 16;

    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: employeeId,
                items: _menuItems(filters.employees),
                onChanged: (value) => setState(() => employeeId = value),
                decoration: const InputDecoration(labelText: 'Employee'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: department,
                items: _menuItems(filters.departments),
                onChanged: (value) => setState(() => department = value),
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: branch,
                items: _menuItems(filters.branches),
                onChanged: (value) => setState(() => branch = value),
                decoration: const InputDecoration(labelText: 'Branch'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: eventType,
                items: _menuItems(filters.eventTypes),
                onChanged: (value) => setState(() => eventType = value),
                decoration: const InputDecoration(labelText: 'Event type'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: status,
                items: _menuItems(filters.statuses),
                onChanged: (value) => setState(() => status = value),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await widget.controller.clearFilters();
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await widget.controller.applyFilters(
                          employeeId: employeeId,
                          department: department,
                          branch: branch,
                          eventType: eventType,
                          status: status,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        children: List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppSurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EEF7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14, width: double.infinity, color: const Color(0xFFE9EEF7)),
                        const SizedBox(height: 10),
                        Container(height: 12, width: 140, color: const Color(0xFFE9EEF7)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            3,
                            (index) => Container(
                              height: 28,
                              width: 88,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9EEF7),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
