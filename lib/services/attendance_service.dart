import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AttendanceService {
  static String get _apiBase => AppConfig.baseUrl;
  static String get _webBase =>
      _apiBase.endsWith('/api')
          ? _apiBase.substring(0, _apiBase.length - 4)
          : _apiBase;

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // POST /api/attendance/scan
  static Future<Map<String, dynamic>> scan(String qrCode) async {
    final code = qrCode.trim();
    if (code.isEmpty) {
      return {
        'success': false,
        'message': 'Invalid QR code.',
      };
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    print('=== SCAN DEBUG ===');
    print('TOKEN: "$token"');
    print('QR: "$qrCode"');
    print('URL: $_apiBase/attendance/scan');

    try {
      final headers = await _headers();
      print('HEADERS: $headers');

      final response = await http.post(
        Uri.parse('$_apiBase/attendance/scan'),
        headers: headers,
        body: jsonEncode({'qr_code': code}),
      );
      print('STATUS: ${response.statusCode}');
      print('RESPONSE: ${response.body}');
      return _handle(response);
    } catch (e) {
      print('ERROR: $e');
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // GET /api/attendance/show?date=YYYY-MM-DD
  static Future<Map<String, dynamic>> getList({String? date}) async {
    final params = date != null ? '?date=$date' : '';
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/attendance/show$params'),
        headers: await _headers(),
      );
      return _handle(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // POST /api/attendance/checkin
  static Future<Map<String, dynamic>> checkIn({String? qrCode}) async {
    try {
      final body = <String, dynamic>{};
      final code = qrCode?.trim() ?? '';
      if (code.isNotEmpty) {
        body['qr_code'] = code;
      }

      final response = await http.post(
        Uri.parse('$_apiBase/attendance/checkin'),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      return _handle(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // GET /api/attendance/qr
  static Future<Map<String, dynamic>> getQr() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBase/attendance/qr'),
        headers: await _headers(),
      );
      return _handle(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // GET /attendance/checkin
  static Future<Map<String, dynamic>> getCheckInPage() async {
    try {
      final response = await http.get(
        Uri.parse('$_webBase/attendance/checkin'),
        headers: await _headers(),
      );
      return _handle(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // POST /attendance/checkin
  static Future<Map<String, dynamic>> postCheckInPage({String? qrCode}) async {
    try {
      final body = <String, dynamic>{};
      final code = qrCode?.trim() ?? '';
      if (code.isNotEmpty) {
        body['qr_code'] = code;
      }

      final response = await http.post(
        Uri.parse('$_webBase/attendance/checkin'),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      return _handle(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Map<String, dynamic> _handle(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body.containsKey('success')) return body;
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        ...body,
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Invalid server response (${response.statusCode})',
      };
    }
  }
}
