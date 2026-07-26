import 'package:dio/dio.dart';

/// A transport-agnostic failure surfaced by the repository layer.
///
/// View models never see a [DioException]; they see this, so the presentation
/// layer has no dependency on the HTTP client.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          'The server took too long to respond. Please try again.',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiException(
          'Cannot reach the AgriChain server. Check your connection and '
          'confirm the backend is running.',
        );
      case DioExceptionType.cancel:
        return const ApiException('The request was cancelled.');
      case DioExceptionType.badCertificate:
        return const ApiException('The server certificate is not trusted.');
      case DioExceptionType.badResponse:
        final response = error.response;
        return ApiException(
          _messageFromBody(response?.data) ??
              _messageForStatus(response?.statusCode),
          statusCode: response?.statusCode,
        );
    }
  }

  /// FastAPI reports failures under `detail`, which is a string for
  /// [HTTPException] and a list of error objects for 422 validation errors.
  static String? _messageFromBody(dynamic data) {
    if (data is! Map) return null;
    final detail = data['detail'];

    if (detail is String && detail.isNotEmpty) return detail;

    if (detail is List && detail.isNotEmpty) {
      final messages = detail
          .whereType<Map>()
          .map((entry) {
            final field = (entry['loc'] as List?)?.lastOrNull;
            final message = entry['msg'] ?? 'is invalid';
            return field == null ? '$message' : '$field: $message';
          })
          .toList();
      if (messages.isNotEmpty) return messages.join('\n');
    }

    return null;
  }

  static String _messageForStatus(int? status) {
    return switch (status) {
      400 => 'The request could not be processed.',
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You do not have permission to perform this action.',
      404 => 'The requested resource was not found.',
      422 => 'Some of the details provided are invalid.',
      final int code when code >= 500 =>
        'The AgriChain server encountered an error. Please try again later.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  @override
  String toString() => message;
}
