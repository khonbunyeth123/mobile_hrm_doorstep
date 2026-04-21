import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ✅ Change to your server IP for mobile device testing
  static const String baseUrl = 'http://192.168.0.199:8080/api';

  // ─── Get token from SharedPreferences ───────────────────────────────────────
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ─── Auth headers (JSON + Bearer token) ─────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── LOGIN ───────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      final user = data['user'] as Map<String, dynamic>;

      await prefs.setString('token', data['token']?.toString() ?? '');
      await prefs.setString('username', user['username']?.toString() ?? '');
      await prefs.setString('full_name', user['full_name']?.toString() ?? '');
      await prefs.setString('email', user['email']?.toString() ?? '');
      await prefs.setString('role', user['role']?.toString() ?? '');
      await prefs.setInt('user_id', user['id'] ?? 0);
      await prefs.setBool('isLoggedIn', true);
    }

    return data;
  }

  // ─── LOGOUT ──────────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await _authHeaders(),
      );
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ─── GET CURRENT USER (me) ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _authHeaders(),
    );
    return jsonDecode(response.body);
  }

  // ─── GET EMPLOYEES ───────────────────────────────────────────────────────────
  static Future<List<dynamic>> getEmployees() async {
    final response = await http.get(
      Uri.parse('$baseUrl/employees'),
      headers: await _authHeaders(),
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return data['data'] as List<dynamic>;
    }
    throw Exception(data['message'] ?? 'Failed to load employees');
  }

  // ─── GET SINGLE EMPLOYEE ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getEmployee(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/employees/$id'),
      headers: await _authHeaders(),
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception(data['message'] ?? 'Failed to load employee');
  }

  // ─── ATTENDANCE ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> checkIn() async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/checkin'),
      headers: await _authHeaders(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> checkOut() async {
    final response = await http.post(
      Uri.parse('$baseUrl/attendance/checkout'),
      headers: await _authHeaders(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getTodayAttendance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/attendance/today'),
      headers: await _authHeaders(),
    );
    return jsonDecode(response.body);
  }

  // ─── LEAVE ───────────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getLeaveList() async {
    final response = await http.get(
      Uri.parse('$baseUrl/leave/list'),
      headers: await _authHeaders(),
    );
    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      return data['data'] as List<dynamic>;
    }
    throw Exception(data['message'] ?? 'Failed to load leaves');
  }

  static Future<Map<String, dynamic>> createLeave(
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/leave/create'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  // ─── DASHBOARD ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/summary'),
      headers: await _authHeaders(),
    );
    return jsonDecode(response.body);
  }

  // ─── GENERIC GET ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _authHeaders(),
    );
    return jsonDecode(response.body);
  }

  // ─── GENERIC POST ────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }
}
