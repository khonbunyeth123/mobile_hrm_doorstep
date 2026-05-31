import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../models/calendar_event.dart';
import '../models/calendar_feed.dart';
import '../models/calendar_filter_option.dart';
import '../models/calendar_query.dart';
import '../models/calendar_summary.dart';
import '../models/leave_item.dart';

class CalendarRepository {
  final ApiClient client;

  const CalendarRepository(this.client);

  static const _basePath = '/api/calendar';

  Future<ApiResult<CalendarFeed>> fetchEvents(CalendarQuery query) async {
    final response = await client.get(
      '$_basePath/events',
      queryParameters: query.toQueryParameters(),
    );

    if (!response.success) {
      return ApiResult.fail(
        message: response.message,
        statusCode: response.statusCode,
        raw: response.raw,
      );
    }

    final payload = _extractPayload(response.data);
    final events = _parseEvents(payload);
    final summary = _parseSummary(response.raw, events);

    return ApiResult.ok(
      data: CalendarFeed(events: events, summary: summary),
      message: response.message,
      statusCode: response.statusCode,
      raw: response.raw,
    );
  }

  Future<ApiResult<CalendarEvent>> fetchEvent(String uuid) async {
    final response = await client.get('$_basePath/events/$uuid');
    if (!response.success) {
      return ApiResult.fail(
        message: response.message,
        statusCode: response.statusCode,
        raw: response.raw,
      );
    }

    final payload = _firstMap(_extractPayload(response.data)) ?? <String, dynamic>{};
    return ApiResult.ok(
      data: CalendarEvent.fromJson(payload),
      message: response.message,
      statusCode: response.statusCode,
      raw: response.raw,
    );
  }

  Future<ApiResult<void>> createEvent(Map<String, dynamic> body) async {
    final response = await client.post('$_basePath/events', body: body);
    return _asVoid(response);
  }

  Future<ApiResult<void>> updateEvent(String uuid, Map<String, dynamic> body) async {
    final response = await client.put('$_basePath/events/$uuid', body: body);
    return _asVoid(response);
  }

  Future<ApiResult<void>> deleteEvent(String uuid) async {
    final response = await client.delete('$_basePath/events/$uuid');
    return _asVoid(response);
  }

  Future<ApiResult<CalendarFilterOptions>> fetchFilters() async {
    final response = await client.get('$_basePath/filters');
    if (!response.success) {
      return ApiResult.fail(
        message: response.message,
        statusCode: response.statusCode,
        raw: response.raw,
      );
    }

    final payload = _firstMap(_extractPayload(response.data)) ?? <String, dynamic>{};
    return ApiResult.ok(
      data: CalendarFilterOptions.fromJson(payload),
      message: response.message,
      statusCode: response.statusCode,
      raw: response.raw,
    );
  }

  Future<ApiResult<LeaveItem>> approveLeave(String uuid) async {
    final response = await client.post('$_basePath/leaves/$uuid/approve');
    if (!response.success) {
      return ApiResult.fail(
        message: response.message,
        statusCode: response.statusCode,
        raw: response.raw,
      );
    }

    return ApiResult.ok(
      data: _maybeLeave(response.data),
      message: response.message ?? 'Leave approved',
      statusCode: response.statusCode,
      raw: response.raw,
    );
  }

  Future<ApiResult<LeaveItem>> rejectLeave(String uuid) async {
    final response = await client.post('$_basePath/leaves/$uuid/reject');
    if (!response.success) {
      return ApiResult.fail(
        message: response.message,
        statusCode: response.statusCode,
        raw: response.raw,
      );
    }

    return ApiResult.ok(
      data: _maybeLeave(response.data),
      message: response.message ?? 'Leave rejected',
      statusCode: response.statusCode,
      raw: response.raw,
    );
  }

  ApiResult<void> _asVoid(ApiResult<dynamic> response) {
    return response.success
        ? ApiResult.ok(message: response.message, statusCode: response.statusCode, raw: response.raw)
        : ApiResult.fail(message: response.message, statusCode: response.statusCode, raw: response.raw);
  }

  dynamic _extractPayload(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      if (payload['events'] != null) return payload['events'];
      if (payload['items'] != null) return payload['items'];
      if (payload['data'] != null) return payload['data'];
      return payload;
    }
    return payload;
  }

  List<CalendarEvent> _parseEvents(dynamic payload) {
    final items = <CalendarEvent>[];
    final rawList = _asList(payload);
    for (final item in rawList) {
      final map = _firstMap(item);
      if (map != null) {
        items.add(CalendarEvent.fromJson(map));
      }
    }
    return items;
  }

  CalendarSummary _parseSummary(Map<String, dynamic>? raw, List<CalendarEvent> events) {
    final data = raw?['data'];
    final rawSummary = raw?['summary'] ??
        (data is Map<String, dynamic> ? data['summary'] : null);
    final parsed = CalendarSummary.fromJson(rawSummary);
    if (parsed.totalTracked > 0 || parsed.statusCounts.isNotEmpty) {
      return parsed;
    }

    final counts = <String, int>{};
    for (final event in events) {
      final key = event.status.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return CalendarSummary(total: events.length, statusCounts: counts);
  }

  LeaveItem? _maybeLeave(dynamic payload) {
    final map = _firstMap(_extractPayload(payload));
    if (map == null) return null;
    return LeaveItem.fromJson(map);
  }

  List<dynamic> _asList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map<String, dynamic>) {
      if (payload['events'] is List) return payload['events'] as List;
      if (payload['items'] is List) return payload['items'] as List;
      if (payload['data'] is List) return payload['data'] as List;
    }
    return const [];
  }

  Map<String, dynamic>? _firstMap(dynamic payload) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is List) {
      for (final item in payload) {
        if (item is Map<String, dynamic>) return item;
      }
    }
    return null;
  }
}
