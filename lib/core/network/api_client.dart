import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/token_storage.dart';
import 'api_result.dart';

class ApiClient {
  final String baseUrl;
  final Duration timeout;

  const ApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 15),
  });

  Future<Map<String, String>> _headers({
    Map<String, String>? extra,
  }) async {
    final token = await TokenStorage.readToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?extra,
    };
  }

  Uri _uri(
    String path, {
    Map<String, String?>? queryParameters,
  }) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final query = <String, String>{};
    queryParameters?.forEach((key, value) {
      if (value != null && value.isNotEmpty) {
        query[key] = value;
      }
    });
    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: query.isEmpty ? null : query,
    );
  }

  Future<ApiResult<dynamic>> get(
    String path, {
    Map<String, String?>? queryParameters,
  }) async {
    try {
      final response = await http
          .get(_uri(path, queryParameters: queryParameters), headers: await _headers())
          .timeout(timeout);
      return _decode(response);
    } catch (e) {
      return ApiResult.fail(message: 'Connection error: $e');
    }
  }

  Future<ApiResult<dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http
          .post(
            _uri(path),
            headers: await _headers(),
            body: jsonEncode(body ?? {}),
          )
          .timeout(timeout);
      return _decode(response);
    } catch (e) {
      return ApiResult.fail(message: 'Connection error: $e');
    }
  }

  Future<ApiResult<dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http
          .put(
            _uri(path),
            headers: await _headers(),
            body: jsonEncode(body ?? {}),
          )
          .timeout(timeout);
      return _decode(response);
    } catch (e) {
      return ApiResult.fail(message: 'Connection error: $e');
    }
  }

  Future<ApiResult<dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http
          .delete(
            _uri(path),
            headers: await _headers(),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(timeout);
      return _decode(response);
    } catch (e) {
      return ApiResult.fail(message: 'Connection error: $e');
    }
  }

  ApiResult<dynamic> _decode(http.Response response) {
    final statusCode = response.statusCode;
    if (response.body.isEmpty) {
      return ApiResult.ok(
        statusCode: statusCode,
        message: statusCode >= 200 && statusCode < 300 ? 'Success' : 'Empty response',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final success = decoded['success'] is bool
            ? decoded['success'] as bool
            : statusCode >= 200 && statusCode < 300;
        return success
            ? ApiResult.ok(
                data: decoded['data'] ?? decoded,
                message: decoded['message']?.toString(),
                statusCode: statusCode,
                raw: decoded,
              )
            : ApiResult.fail(
                data: decoded['data'],
                message: decoded['message']?.toString() ?? 'Request failed',
                statusCode: statusCode,
                raw: decoded,
              );
      }
      return ApiResult.ok(
        data: decoded,
        statusCode: statusCode,
      );
    } catch (_) {
      return statusCode >= 200 && statusCode < 300
          ? ApiResult.ok(
              data: response.body,
              statusCode: statusCode,
            )
          : ApiResult.fail(
              message: 'Invalid server response ($statusCode)',
              statusCode: statusCode,
            );
    }
  }
}
