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
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<String, List<CalendarEvent>> _monthCache = {};
  Map<DateTime, List<CalendarEvent>> _eventsByDay = {};

  bool _isLoading = false;
  String? _error;

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
      } else {
        _error = result['message'] ?? 'Failed to load calendar events';
      }
    });
  }

  void _applyEvents(List<CalendarEvent> events) {
    _eventsByDay = _groupEventsByDay(events);
  }

  Map<DateTime, List<CalendarEvent>> _groupEventsByDay(
    List<CalendarEvent> events,
  ) {
    final grouped = <DateTime, List<CalendarEvent>>{};
    for (final event in events) {
      final start = _dayKey(event.date);
      final end = _dayKey(event.endDate ?? event.date);
      for (var day = start; !day.isAfter(end); day = day.add(const Duration(days: 1))) {
        grouped.putIfAbsent(day, () => []);
        grouped[day]!.add(event);
      }
    }
    for (final list in grouped.values) {
      list.sort(_compareEvents);
    }
    return grouped;
  }

  List<CalendarEvent> _eventsForDay(DateTime day) => _eventsByDay[_dayKey(day)] ?? const [];
  
  DateTime _dayKey(DateTime day) => DateTime(day.year, day.month, day.day);

  int _compareEvents(CalendarEvent a, CalendarEvent b) {
    final dateCompare = a.date.compareTo(b.date);
    if (dateCompare != 0) return dateCompare;
    final typeCompare = _typeOrder(a.type).compareTo(_typeOrder(b.type));
    if (typeCompare != 0) return typeCompare;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  int _typeOrder(String type) {
    switch (type) {
      case 'holiday': return 0;
      case 'leave': return 1;
      case 'shift': return 2;
      default: return 3;
    }
  }

  Color _getColorForPriority(CalendarEvent event) {
    switch (event.type) {
      case 'leave': return AppTheme.danger;
      case 'shift': return AppTheme.brand;
      case 'holiday': return AppTheme.success;
      default: return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMM().format(_focusedDay)),
        actions:[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),
      body: Column(
        children: [
          TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _eventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              tableBorder: const TableBorder(),
              todayDecoration: BoxDecoration(color: AppTheme.brand.withValues(alpha: 0.1), shape: BoxShape.circle),
              selectedDecoration: const BoxDecoration(color: AppTheme.brand, shape: BoxShape.circle),
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
                final children = events.take(2).map((event) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 6, height: 6,
                    decoration: BoxDecoration(color: _getColorForPriority(event), shape: BoxShape.circle),
                  );
                }).toList();
                if (events.length > 2) {
                  children.add(
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      child: const Text('+', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  );
                }
                return Positioned(bottom: 4, child: Row(children: children));
              },
            ),
          ),
          if (_error != null)
          Container(
            width: double.infinity,
            color: AppTheme.danger.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _error!,
              style: const TextStyle(color: AppTheme.danger, fontSize: 13),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _eventsForDay(
                        _selectedDay ?? _focusedDay,
                      ).length,
                      itemBuilder: (context, index) {
                        final event = _eventsForDay(
                          _selectedDay ?? _focusedDay,
                        )[index];
                        return _buildEventCard(event);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(color: _getColorForPriority(event), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${DateFormat('h:mm a').format(event.date)} • ${event.type}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
