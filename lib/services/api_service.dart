import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';


class ApiService {
  static String get baseUrl => AppConfig.baseUrl;
  static const Duration _timeout = Duration(seconds: 15);

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

  static Future<void> _persistLoginData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ employee login returns 'employee', admin login returns 'user'
    final rawUser = data['employee'] ?? data['user'];
    final user = rawUser is Map<String, dynamic>
        ? rawUser
        : <String, dynamic>{};
    final userId = _asInt(user['id']);

    await prefs.setString('token', data['token']?.toString() ?? '');
    await prefs.setString('username', user['username']?.toString() ?? '');
    await prefs.setString('full_name', user['full_name']?.toString() ?? '');
    await prefs.setString('email', user['email']?.toString() ?? '');
    await prefs.setString('role', user['role']?.toString() ?? '');
    await prefs.setInt('user_id', userId);
    await prefs.setInt('employee_id', userId); // ✅ ProfileService reads this
    await prefs.setBool('isLoggedIn', true);
  }

  static Future<Map<String, dynamic>> _loginWithEndpoint(
    String endpoint,
    String username,
    String password,
  ) async {
    try {
      // Get FCM token before login
      final fcmToken = await FirebaseMessaging.instance.getToken();

      final response = await http
          .post(
            Uri.parse('$baseUrl/$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'password': password,
              'fcm_token': fcmToken ?? '',
            }),
          )
          .timeout(_timeout);

      final data = _parseResponse(response);

      if (data['success'] == true) {
        await _persistLoginData(data);
      }

      return data;
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    return loginEmployee(username, password);
  }

  static Future<Map<String, dynamic>> loginAdmin(
    String username,
    String password,
  ) async {
    return _loginWithEndpoint('auth/admin/login', username, password);
  }

  static Future<Map<String, dynamic>> loginEmployee(
    String username,
    String password,
  ) async {
    return _loginWithEndpoint('auth/employee/login', username, password);
  }


  static void listenFcmTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await post('auth/fcm-token', {'fcm_token': newToken});
      } catch (_) {}
    });
  }

  static Future<void> logout() async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/auth/logout'),
            headers: await _authHeaders(),
          )
          .timeout(_timeout);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<Map<String, dynamic>> getMe() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/auth/me'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> getAdminMe() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/auth/admin/me'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> getEmployeeMe() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/auth/employee/me'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);
    return _parseResponse(response);
  }

  static Future<List<dynamic>> getEmployees() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/employees'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);
    final data = _parseResponse(response);
    if (data['success'] == true) {
      return (data['data'] as List<dynamic>?) ?? <dynamic>[];
    }
    throw Exception(data['message'] ?? 'Failed to load employees');
  }

  static Future<Map<String, dynamic>> getEmployee(int id) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/employees/$id'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);
    final data = _parseResponse(response);
    if (data['success'] == true) {
      return (data['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    }
    throw Exception(data['message'] ?? 'Failed to load employee');
  }

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/dashboard/summary'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/$endpoint'),
          headers: await _authHeaders(),
        )
        .timeout(_timeout);
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/$endpoint'),
          headers: await _authHeaders(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _parseResponse(response);
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return {
          'success': false,
          'status_code': response.statusCode,
          'message': 'Unexpected response format',
        };
      }

      final result = <String, dynamic>{
        ...decoded,
        'status_code': response.statusCode,
      };
      result.putIfAbsent(
        'success',
        () => response.statusCode >= 200 && response.statusCode < 300,
      );
      return result;
    } catch (_) {
      return {
        'success': false,
        'status_code': response.statusCode,
        'message': 'Invalid server response (${response.statusCode})',
      };
    }
  }
}
