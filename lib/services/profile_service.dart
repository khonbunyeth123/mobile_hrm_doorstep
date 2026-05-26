import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ProfileService {
  static String get baseUrl => AppConfig.baseUrl;

  // ─── Auth headers ────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Get employee ID from local storage ──────────────────────────────────────
  static Future<int> _getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    // ✅ Fallback to 'user_id' — api_service.dart saves as 'user_id' on login
    final id = prefs.getInt('employee_id') ?? prefs.getInt('user_id') ?? 0;
    if (id == 0) throw Exception('Employee ID not found. Please log in again.');
    return id;
  }

  // ─── GET profile ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    final id = await _getEmployeeId();
    final response = await http.get(
      Uri.parse('$baseUrl/employees/$id'),
      headers: await _authHeaders(),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }
    throw Exception(data['message'] ?? 'Failed to load profile');
  }

  // ─── UPDATE profile ───────────────────────────────────────────────────────────
  static Future<void> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    required String address,
  }) async {
    final id = await _getEmployeeId();
    final response = await http.put(
      Uri.parse('$baseUrl/employees/$id'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'address': address,
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update profile');
    }
    // ✅ Update local cache so home/other screens see the updated name & email
    await _updateCache(fullName: fullName, email: email);
  }

  // ─── GET cached profile info (from SharedPreferences) ────────────────────────
  static Future<Map<String, String>> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'full_name': prefs.getString('full_name') ?? '',
      'email': prefs.getString('email') ?? '',
      'username': prefs.getString('username') ?? '',
    };
  }

  // ─── Update cached profile after save ────────────────────────────────────────
  static Future<void> _updateCache({
    required String fullName,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('full_name', fullName);
    await prefs.setString('email', email);
  }
}
