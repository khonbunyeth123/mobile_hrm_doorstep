import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarService {
  static String get baseUrl => AppConfig.baseUrl;

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> getCalendarEvents(String month) async {
    try {
      // month format: YYYY-MM
      final response = await http
          .get(
            Uri.parse('$baseUrl/employee/calendar-events?month=$month'),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      return _normalizeResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Map<String, dynamic> _normalizeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final data = _extractEvents(decoded['data'] ?? decoded);
        final successValue = decoded['success'];
        final success = successValue is bool
            ? successValue
            : response.statusCode >= 200 && response.statusCode < 300;
        return {
          ...decoded,
          'status_code': response.statusCode,
          'success': success,
          'data': data,
        };
      }

      if (decoded is List) {
        return {
          'success': response.statusCode >= 200 && response.statusCode < 300,
          'status_code': response.statusCode,
          'data': _extractEvents(decoded),
        };
      }

      return {
        'success': false,
        'status_code': response.statusCode,
        'message': 'Unexpected server response',
      };
    } catch (_) {
      return {
        'success': false,
        'status_code': response.statusCode,
        'message': 'Invalid server response (${response.statusCode})',
      };
    }
  }

  static List<Map<String, dynamic>> _extractEvents(dynamic payload) {
    final events = <Map<String, dynamic>>[];
    _collectEvents(payload, events);
    return events;
  }

  static void _collectEvents(
    dynamic payload,
    List<Map<String, dynamic>> events, {
    String? inferredType,
    bool? inferredPublic,
  }) {
    if (payload is List) {
      for (final item in payload) {
        _collectEvents(
          item,
          events,
          inferredType: inferredType,
          inferredPublic: inferredPublic,
        );
      }
      return;
    }

    if (payload is! Map) return;

    final map = Map<String, dynamic>.from(payload);
    final directType = _inferType(map, inferredType);
    final directPublic = inferredPublic ?? _inferPublic(map, directType);

    final listKeys = <String, String>{
      'events': 'event',
      'calendar_events': 'event',
      'items': 'event',
      'records': 'event',
      'data': 'event',
      'holidays': 'holiday',
      'company_holidays': 'holiday',
      'leave_days': 'leave',
      'approved_leave_days': 'leave',
      'approved_leaves': 'leave',
      'leave_requests': 'leave',
      'shifts': 'shift',
      'assigned_shifts': 'shift',
      'schedules': 'schedule',
      'personal_schedule': 'schedule',
      'reminders': 'reminder',
      'company_events': 'event',
      'company_reminders': 'reminder',
    };

    var foundNestedList = false;
    for (final entry in listKeys.entries) {
      final nested = map[entry.key];
      if (nested is List) {
        foundNestedList = true;
        for (final item in nested) {
          if (item is! Map) continue;
          final normalized = Map<String, dynamic>.from(item);
          normalized.putIfAbsent('type', () => entry.value);
          if (entry.value == 'holiday' || entry.key.contains('company')) {
            normalized.putIfAbsent('is_public', () => true);
            normalized.putIfAbsent('can_edit', () => false);
          }
          if (entry.value == 'leave') {
            if (!normalized.containsKey('status')) {
              if (entry.key.contains('approved')) {
                normalized['status'] = 'approved';
              } else if (entry.key.contains('reject')) {
                normalized['status'] = 'rejected';
              } else if (entry.key.contains('request') ||
                  entry.key.contains('pending')) {
                normalized['status'] = 'pending';
              }
            }
          }
          events.add(normalized);
        }
      }
    }

    if (!foundNestedList && _looksLikeEvent(map)) {
      map.putIfAbsent('type', () => directType);
      if (directPublic != null) {
        map.putIfAbsent('is_public', () => directPublic);
      }
      events.add(map);
    }
  }

  static String _inferType(Map<String, dynamic> json, String? fallback) {
    final raw = (json['type'] ?? json['event_type'] ?? json['category'] ?? fallback ?? '')
        .toString()
        .toLowerCase();

    if (raw.contains('holiday')) return 'holiday';
    if (raw.contains('leave')) return 'leave';
    if (raw.contains('shift')) return 'shift';
    if (raw.contains('reminder') || raw.contains('alert')) return 'reminder';
    if (raw.contains('attendance')) return 'attendance';
    if (raw.contains('schedule')) return 'schedule';
    if (raw.contains('event')) return 'event';

    if (_looksLikeLeave(json)) return 'leave';
    if (_looksLikeHoliday(json)) return 'holiday';
    if (_looksLikeShift(json)) return 'shift';
    if (_looksLikeReminder(json)) return 'reminder';
    if (_looksLikeCompanyEvent(json)) return 'event';

    return fallback ?? 'schedule';
  }

  static bool? _inferPublic(Map<String, dynamic> json, String type) {
    if (json.containsKey('is_public')) {
      final value = json['is_public'];
      if (value is bool) return value;
      final normalized = value.toString().trim().toLowerCase();
      if (['1', 'true', 'yes'].contains(normalized)) return true;
      if (['0', 'false', 'no'].contains(normalized)) return false;
    }

    if (type == 'holiday' || type == 'event') return true;
    if ((json['source'] ?? json['origin'] ?? '').toString().toLowerCase().contains('company')) {
      return true;
    }
    return null;
  }

  static bool _looksLikeEvent(Map<String, dynamic> json) {
    return json.containsKey('date') ||
        json.containsKey('start_date') ||
        json.containsKey('event_date') ||
        json.containsKey('title') ||
        json.containsKey('event_title') ||
        json.containsKey('name');
  }

  static bool _looksLikeLeave(Map<String, dynamic> json) {
    final text = _searchText(json);
    return text.contains('leave') || text.contains('approved_leave') || text.contains('leave_request');
  }

  static bool _looksLikeHoliday(Map<String, dynamic> json) {
    final text = _searchText(json);
    return text.contains('holiday') || text.contains('public holiday');
  }

  static bool _looksLikeShift(Map<String, dynamic> json) {
    final text = _searchText(json);
    return text.contains('shift') || text.contains('duty');
  }

  static bool _looksLikeReminder(Map<String, dynamic> json) {
    final text = _searchText(json);
    return text.contains('reminder') || text.contains('alert') || text.contains('notify');
  }

  static bool _looksLikeCompanyEvent(Map<String, dynamic> json) {
    final text = _searchText(json);
    return text.contains('company') || text.contains('event');
  }

  static String _searchText(Map<String, dynamic> json) {
    final buffer = StringBuffer();
    for (final value in json.values) {
      if (value == null) continue;
      buffer.write('${value.toString().toLowerCase()} ');
    }
    return buffer.toString();
  }
}
