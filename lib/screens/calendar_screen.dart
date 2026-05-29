
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/calendar_event.dart';
import '../services/calendar_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Caching events by month: 'YYYY-MM' -> List of events
  final Map<String, List<CalendarEvent>> _monthCache = {};
  Map<DateTime, List<CalendarEvent>> _events = {};
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchEventsForMonth(_focusedDay);
  }

  Future<void> _fetchEventsForMonth(DateTime month) async {
    final monthStr = DateFormat('yyyy-MM').format(month);
    
    if (_monthCache.containsKey(monthStr)) {
      _loadFromCache(monthStr);
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await CalendarService.getCalendarEvents(monthStr);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        final List<dynamic> data = result['data'] ?? [];
        final events = data.map((item) => CalendarEvent.fromJson(item)).toList();
        _monthCache[monthStr] = events;
        _loadFromCache(monthStr);
      } else {
        _error = result['message'] ?? 'Failed to load calendar events';
      }
    });
  }

  void _loadFromCache(String monthStr) {
    final events = _monthCache[monthStr] ?? [];
    final Map<DateTime, List<CalendarEvent>> newEventsMap = {};
    
    for (var event in events) {
      final date = DateTime(event.date.year, event.date.month, event.date.day);
      if (newEventsMap[date] == null) {
        newEventsMap[date] = [];
      }
      newEventsMap[date]!.add(event);
    }
    
    setState(() {
      _events = newEventsMap;
    });
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      
      final events = _getEventsForDay(selectedDay);
      if (events.isNotEmpty) {
        _showDetailsBottomSheet(selectedDay, events);
      }
    }
  }

  void _showDetailsBottomSheet(DateTime date, List<CalendarEvent> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CalendarDetailsSheet(date: date, events: events),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              final monthStr = DateFormat('yyyy-MM').format(_focusedDay);
              _monthCache.remove(monthStr);
              _fetchEventsForMonth(_focusedDay);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendarCard(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppSectionHeader(
              title: DateFormat('MMMM d, yyyy').format(_selectedDay ?? _focusedDay),
              subtitle: 'Records for this day',
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                ? AppEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'Oops!',
                    message: _error!,
                    actionLabel: 'Try again',
                    onAction: () => _fetchEventsForMonth(_focusedDay),
                  )
                : _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return AppSurfaceCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.only(bottom: 8),
      child: TableCalendar<CalendarEvent>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppTheme.brand),
          rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppTheme.brand),
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
          markerDecoration: BoxDecoration(
            color: AppTheme.brand,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
        ),
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() => _calendarFormat = format);
          }
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
            _selectedDay = focusedDay;
          });
          _fetchEventsForMonth(focusedDay);
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
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay ?? _focusedDay);
    if (events.isEmpty) {
      return AppEmptyState(
        icon: Icons.event_busy_rounded,
        title: 'No records',
        message: 'There are no activities recorded for this date.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppSurfaceCard(
            padding: const EdgeInsets.all(16),
            onTap: () => _showDetailsBottomSheet(_selectedDay ?? _focusedDay, events),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: event.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    event.type == 'leave' ? Icons.event_note_rounded : Icons.qr_code_scanner_rounded,
                    color: event.color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AppStatusPill(
                        label: event.status.toUpperCase(),
                        color: event.color,
                        backgroundColor: event.color.withValues(alpha: 0.08),
                        icon: Icons.info_outline_rounded,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CalendarDetailsSheet extends StatelessWidget {
  final DateTime date;
  final List<CalendarEvent> events;

  const _CalendarDetailsSheet({required this.date, required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.brandSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.calendar_month_rounded, color: AppTheme.brand),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Day Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(date),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...events.map((event) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppSurfaceCard(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: event.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      event.type == 'leave' ? Icons.event_note_rounded : Icons.qr_code_scanner_rounded,
                      color: event.color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            AppStatusPill(
                              label: event.status.toUpperCase(),
                              color: event.color,
                              backgroundColor: event.color.withValues(alpha: 0.08),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              event.type.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary.withValues(alpha: 0.6),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: 'Dismiss',
            onPressed: () => Navigator.pop(context),
            icon: Icons.close_rounded,
          ),
        ],
      ),
    );
  }
}
