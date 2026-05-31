import 'calendar_target.dart';

class CalendarEvent {
  final String uuid;
  final String title;
  final String description;
  final String eventType;
  final String status;
  final DateTime startAt;
  final DateTime endAt;
  final bool allDay;
  final String? recurrence;
  final List<CalendarTarget> targets;
  final bool isLeave;
  final String? leaveUuid;
  final String? location;
  final String? color;

  const CalendarEvent({
    required this.uuid,
    required this.title,
    required this.description,
    required this.eventType,
    required this.status,
    required this.startAt,
    required this.endAt,
    required this.allDay,
    required this.targets,
    this.recurrence,
    required this.isLeave,
    this.leaveUuid,
    this.location,
    this.color,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      final parsed = DateTime.tryParse(value?.toString() ?? '');
      return parsed ?? DateTime.now();
    }

    final eventType = (json['event_type'] ?? json['type'] ?? 'company_event').toString();
    final status = (json['status'] ?? json['event_status'] ?? 'draft').toString();
    final targetsRaw = json['targets'];

    return CalendarEvent(
      uuid: (json['uuid'] ?? json['id'] ?? json['event_uuid']).toString(),
      title: (json['title'] ?? 'Untitled event').toString(),
      description: (json['description'] ?? '').toString(),
      eventType: eventType,
      status: status,
      startAt: parseDate(json['start_at'] ?? json['start_date'] ?? json['start']),
      endAt: parseDate(json['end_at'] ?? json['end_date'] ?? json['end']),
      allDay: json['all_day'] == true || json['allDay'] == true,
      recurrence: json['recurrence']?.toString() ?? json['recurrence_rule']?.toString(),
      targets: _parseTargets(targetsRaw),
      isLeave: _isLeaveEvent(eventType, json),
      leaveUuid: json['leave_uuid']?.toString() ?? json['leave_id']?.toString(),
      location: json['location']?.toString(),
      color: json['color']?.toString() ?? json['color_code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'description': description,
      'event_type': eventType,
      'status': status,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'all_day': allDay,
      'recurrence': recurrence,
      'targets': targets.map((target) => target.toJson()).toList(),
      'location': location,
      'color': color,
      'leave_uuid': leaveUuid,
    };
  }

  Map<String, dynamic> toRequestJson() {
    return {
      'title': title,
      'description': description,
      'event_type': eventType,
      'status': status,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
      'all_day': allDay,
      'recurrence': recurrence,
      'targets': targets.map((target) => target.toJson()).toList(),
      'location': location,
    };
  }

  static bool _isLeaveEvent(String eventType, Map<String, dynamic> json) {
    final type = eventType.toLowerCase();
    if (type.contains('leave')) return true;
    if (json['is_leave'] == true || json['leave_uuid'] != null) return true;
    return false;
  }

  static List<CalendarTarget> _parseTargets(dynamic rawTargets) {
    if (rawTargets is! List) return const [];
    return rawTargets.whereType<dynamic>().map((item) {
      if (item is Map<String, dynamic>) {
        return CalendarTarget.fromJson(item);
      }
      return CalendarTarget(
        type: CalendarTargetType.company,
        label: item.toString(),
      );
    }).toList();
  }

  String get recurrenceLabel {
    if (recurrence == null || recurrence!.isEmpty) return 'No recurrence';
    return recurrence!;
  }

  String get displayRange {
    final start = _formatShortDateTime(startAt, allDay);
    final end = _formatShortDateTime(endAt, allDay);
    if (start == end) return start;
    return '$start - $end';
  }

  String _formatShortDateTime(DateTime date, bool allDay) {
    final datePart = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (allDay) return datePart;
    final timePart = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$datePart $timePart';
  }

  bool get readOnly => isLeave;
  bool get hasTargets => targets.isNotEmpty;
}
