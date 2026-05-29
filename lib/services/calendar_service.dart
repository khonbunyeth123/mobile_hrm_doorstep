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

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
