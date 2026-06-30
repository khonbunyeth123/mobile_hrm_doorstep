import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../core/auth/token_storage.dart';

class HistoryService {
  static String get baseUrl => AppConfig.baseUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final token = await TokenStorage.readToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> getAttendanceHistory({
    int? month,
    int? year,
    int page = 1,
    int perPage = 100,  
  }) async {
    try {
      final now = DateTime.now();
      final m = month ?? now.month;
      final y = year ?? now.year;
      final url = '$baseUrl/attendance/history?month=$m&year=$y&page=$page&per_page=$perPage';
      final response = await http
          .get(Uri.parse(url), headers: await _authHeaders())
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getLeaveHistory({
    int page = 1,
    int perPage = 100,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/leave/history?page=$page&per_page=$perPage'),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
