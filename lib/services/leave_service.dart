import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class LeaveService {
  static String get _base => AppConfig.baseUrl;
  static const List<String> _leaveCreateEndpoints = [
    'leave/create',
    'leave/employee/create',
    'employee/leave/create',
    'employee/leave/request',
    'leave/request',
    'auth/employee/leave/create',
  ];

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // GET /api/leave/list
  static Future<Map<String, dynamic>> getLeaveList() async {
    try {
      final response = await http.get(
        Uri.parse('$_base/leave/list'),
        headers: await _headers(),
      );
      return _handle(response);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // POST /api/leave/create
  static Future<Map<String, dynamic>> createLeave(
    Map<String, dynamic> body,
  ) async {
    try {
      final headers = await _headers();
      Map<String, dynamic>? lastResult;

      for (final endpoint in _leaveCreateEndpoints) {
        final url = '$_base/$endpoint';
        final bodyEncoded = jsonEncode(body);
        print('DEBUG: Request URL: $url');
        print('DEBUG: Request Headers: $headers');
        print('DEBUG: Request Body: $bodyEncoded');
        
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: bodyEncoded,
        );
        print('DEBUG: Response Status: ${response.statusCode}');
        print('DEBUG: Response Body: ${response.body}');
        
        final result = _handle(response);
        lastResult = result;

        if (result['success'] == true) {
          return result;
        }

        if (!_shouldTryNextEndpoint(result)) {
          return result;
        }
      }

      return lastResult ??
          {'success': false, 'message': 'Failed to submit leave request'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static bool _isInvalidAccountType(Map<String, dynamic> result) {
    final message = result['message']?.toString().toLowerCase() ?? '';
    return message.contains('invalid account type');
  }

  static bool _isEndpointNotFound(Map<String, dynamic> result) {
    final message = result['message']?.toString().toLowerCase() ?? '';
    final statusCode = result['status_code'];
    return statusCode == 404 ||
        message.contains('endpoint not found') ||
        message.contains('not found');
  }

  static bool _shouldTryNextEndpoint(Map<String, dynamic> result) {
    return _isInvalidAccountType(result) || _isEndpointNotFound(result);
  }

  static Map<String, dynamic> _handle(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body.containsKey('success')) {
        return {
          ...body,
          'status_code': response.statusCode,
        };
      }
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'status_code': response.statusCode,
        ...body,
      };
    } catch (_) {
      return {
        'success': false,
        'status_code': response.statusCode,
        'message': 'Invalid server response (${response.statusCode})',
      };
    }
  }
}
