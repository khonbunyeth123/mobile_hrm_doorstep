import 'package:flutter/material.dart';

class CalendarEvent {
  final DateTime date;
  final DateTime? endDate;
  final String type;
  final String title;
  final String status;
  final Color color;
  final String? subtitle;
  final String? description;
  final String? timeLabel;
  final String? location;
  final String? source;
  final bool isPublic;
  final bool canEdit;
  final bool isAllDay;
  final bool isReminder;

  CalendarEvent({
    required this.date,
    required this.type,
    required this.title,
    required this.status,
    required this.color,
    this.endDate,
    this.subtitle,
    this.description,
    this.timeLabel,
    this.location,
    this.source,
    required this.isPublic,
    required this.canEdit,
    required this.isAllDay,
    required this.isReminder,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json);
    final type = _normalizeType(data);
    final status = _readString(data, [
      'status',
      'leave_status',
      'approval_status',
      'state',
    ]).toLowerCase();
    final isPublic = _readBool(data, [
          'is_public',
          'public',
          'visible_to_all',
        ]) ||
        type == 'holiday' ||
        type == 'event';
    final canEdit = _readBool(data, ['can_edit', 'editable']) && !isPublic;
    final date = _readDate(data, [
          'date',
          'start_date',
          'start',
          'event_date',
          'day',
        ]) ??
        DateTime.now();
    final endDate = _readDate(data, [
      'end_date',
      'end',
      'to_date',
    ]);
    final title = _readString(data, [
      'title',
      'event_title',
      'name',
      'subject',
    ]).trim();

    return CalendarEvent(
      date: date,
      endDate: endDate,
      type: type,
      title: title.isNotEmpty ? title : _fallbackTitle(type, status),
      status: status.isNotEmpty ? status : _fallbackStatus(type),
      color: _parseColor(data['color_code']?.toString()) ??
          _defaultColor(type, status, isPublic),
      subtitle: _firstString(data, [
        'subtitle',
        'note',
        'description',
        'reason',
      ]),
      description: _firstString(data, [
        'description',
        'details',
        'notes',
        'remarks',
        'reason',
      ]),
      timeLabel: _buildTimeLabel(data),
      location: _firstString(data, [
        'location',
        'venue',
        'place',
      ]),
      source: _firstString(data, [
        'source',
        'origin',
        'created_by_type',
      ]),
      isPublic: isPublic,
      canEdit: canEdit,
      isAllDay: _readBool(data, ['all_day', 'is_all_day']) ||
          type == 'holiday' ||
          type == 'leave' && !_hasTimeField(data),
      isReminder: type == 'reminder',
    );
  }

  static String _normalizeType(Map<String, dynamic> json) {
    final raw = _readString(json, [
      'type',
      'event_type',
      'category',
      'kind',
    ]).toLowerCase();

    if (raw.contains('holiday')) return 'holiday';
    if (raw.contains('leave')) return 'leave';
    if (raw.contains('shift')) return 'shift';
    if (raw.contains('reminder') || raw.contains('alert')) return 'reminder';
    if (raw.contains('schedule')) return 'schedule';
    if (raw.contains('attendance')) return 'attendance';
    if (raw.contains('event')) return 'event';

    final source = _readString(json, ['source', 'origin']).toLowerCase();
    if (source.contains('company')) return 'event';
    if (_readBool(json, ['is_public', 'public'])) return 'event';
    if (_readString(json, ['leave_status', 'approval_status']).isNotEmpty) {
      return 'leave';
    }

    return 'schedule';
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final stringValue = value.toString().trim();
      if (stringValue.isNotEmpty) return stringValue;
    }
    return fallback;
  }

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    final value = _readString(json, keys);
    return value.isEmpty ? null : value;
  }

  static bool _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is bool) return value;
      final normalized = value.toString().trim().toLowerCase();
      if (normalized.isEmpty) continue;
      if (['1', 'true', 'yes', 'y'].contains(normalized)) return true;
      if (['0', 'false', 'no', 'n'].contains(normalized)) return false;
    }
    return false;
  }

  static DateTime? _readDate(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;

      if (value is DateTime) return value;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is double) {
        return DateTime.fromMillisecondsSinceEpoch(value.round());
      }

      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static bool _hasTimeField(Map<String, dynamic> json) {
    return _firstString(json, [
          'time',
          'start_time',
          'end_time',
          'shift_time',
        ]) !=
        null;
  }

  static String? _buildTimeLabel(Map<String, dynamic> json) {
    final time = _firstString(json, [
      'time',
      'start_time',
      'shift_time',
    ]);
    final startTime = _firstString(json, ['start_time']);
    final endTime = _firstString(json, ['end_time']);

    if (time != null) return time;
    if (startTime != null && endTime != null) {
      return '$startTime - $endTime';
    }
    if (startTime != null) return startTime;
    return null;
  }

  static Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.replaceFirst('#', '').trim();
    if (normalized.length == 6) {
      try {
        return Color(int.parse('FF$normalized', radix: 16));
      } catch (_) {
        return null;
      }
    }
    if (normalized.length == 8) {
      try {
        return Color(int.parse(normalized, radix: 16));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Color _defaultColor(String type, String status, bool isPublic) {
    switch (type) {
      case 'holiday':
        return const Color(0xFFF59E0B);
      case 'leave':
        if (status == 'approved') return const Color(0xFF10B981);
        if (status == 'pending') return const Color(0xFFF59E0B);
        if (status == 'rejected') return const Color(0xFFE5484D);
        return const Color(0xFF16B8A6);
      case 'shift':
        return const Color(0xFF0F6FDB);
      case 'reminder':
        return const Color(0xFF16B8A6);
      case 'event':
        return isPublic ? const Color(0xFF64748B) : const Color(0xFF0F6FDB);
      case 'attendance':
      case 'schedule':
      default:
        return const Color(0xFF0F6FDB);
    }
  }

  static String _fallbackTitle(String type, String status) {
    switch (type) {
      case 'holiday':
        return 'Company holiday';
      case 'leave':
        return status == 'approved' ? 'Approved leave' : 'Leave request';
      case 'shift':
        return 'Assigned shift';
      case 'reminder':
        return 'Reminder';
      case 'event':
        return 'Company event';
      case 'attendance':
        return 'Attendance record';
      default:
        return 'Personal schedule';
    }
  }

  static String _fallbackStatus(String type) {
    switch (type) {
      case 'holiday':
        return 'public';
      case 'shift':
        return 'assigned';
      case 'event':
        return 'public';
      case 'reminder':
        return 'reminder';
      default:
        return 'scheduled';
    }
  }

  bool get isLeave => type == 'leave';
  bool get isHoliday => type == 'holiday';
  bool get isShift => type == 'shift';
  bool get isCompanyEvent => isPublic && type == 'event';
}
