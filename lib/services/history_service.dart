// ============================================================
//  lib/services/history_service.dart
//  Fetches attendance and leave history for the logged-in employee
// ============================================================

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static String get baseUrl => AppConfig.baseUrl;

  // ─── Get token from SharedPreferences ───────────────────
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ─── Auth headers ────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Attendance History ──────────────────────────────────
  static Future<Map<String, dynamic>> getAttendanceHistory({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$baseUrl/attendance/history?page=$page&per_page=$perPage',
            ),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ─── Leave History ───────────────────────────────────────
  static Future<Map<String, dynamic>> getLeaveHistory({
    int page = 1,
    int perPage = 20,
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
