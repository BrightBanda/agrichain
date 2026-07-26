import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../session/session_expiry.dart';
import '../storage/token_storage.dart';

/// Marks a request as public so the interceptor neither attaches a token nor
/// treats a 401 as an expired session (login with bad credentials is a 401).
const Map<String, dynamic> publicRequest = {'requiresAuth': false};

/// Retries a request when the host appears to be asleep.
///
/// Free hosting tiers suspend an idle container, so the first request after a
/// quiet spell can time out while it boots. Retrying turns that into a slow
/// load rather than a visible failure.
///
/// Only idempotent methods are retried. Replaying a POST could record a
/// repayment or a loan application twice, and a connection timeout gives no
/// guarantee the server never received the original.
class ColdStartRetryInterceptor extends Interceptor {
  static const _idempotentMethods = {'GET', 'HEAD', 'OPTIONS'};
  static const _attemptKey = 'coldStartAttempt';

  final Dio _dio;

  /// Injectable so tests do not have to wait out the real backoff.
  final Duration retryDelay;
  final int maxRetries;

  ColdStartRetryInterceptor(
    this._dio, {
    this.retryDelay = AppConfig.retryDelay,
    this.maxRetries = AppConfig.coldStartRetries,
  });

  bool _looksAsleep(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError => true,
    _ => false,
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final method = options.method.toUpperCase();
    final attempt = (options.extra[_attemptKey] as int?) ?? 0;

    final shouldRetry =
        _looksAsleep(err) &&
        _idempotentMethods.contains(method) &&
        attempt < maxRetries;

    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    await Future<void>.delayed(retryDelay);

    try {
      final response = await _dio.fetch<dynamic>(
        options..extra[_attemptKey] = attempt + 1,
      );
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      sendTimeout: AppConfig.sendTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(ColdStartRetryInterceptor(dio));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.extra['requiresAuth'] != false) {
          final token = await tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isAuthenticatedCall = error.requestOptions.extra['requiresAuth'] != false;
        if (error.response?.statusCode == 401 && isAuthenticatedCall) {
          await tokenStorage.clear();
          ref.read(sessionExpiryProvider.notifier).markExpired();
        }
        handler.next(error);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true, error: true),
    );
  }

  ref.onDispose(dio.close);
  return dio;
});
