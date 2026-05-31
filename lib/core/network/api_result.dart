class ApiResult<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? raw;

  const ApiResult({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.raw,
  });

  factory ApiResult.ok({
    T? data,
    String? message,
    int? statusCode,
    Map<String, dynamic>? raw,
  }) {
    return ApiResult<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
      raw: raw,
    );
  }

  factory ApiResult.fail({
    String? message,
    int? statusCode,
    Map<String, dynamic>? raw,
    T? data,
  }) {
    return ApiResult<T>(
      success: false,
      data: data,
      message: message,
      statusCode: statusCode,
      raw: raw,
    );
  }
}
