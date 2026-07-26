import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../session/session_expiry.dart';
import '../storage/token_storage.dart';

/// Marks a request as public so the interceptor neither attaches a token nor
/// treats a 401 as an expired session (login with bad credentials is a 401).
const Map<String, dynamic> publicRequest = {'requiresAuth': false};

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

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
