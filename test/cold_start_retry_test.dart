import 'dart:typed_data';

import 'package:agri/src/core/config/app_config.dart';
import 'package:agri/src/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fails the first [failures] calls the way a sleeping host does, then succeeds.
class _SleepingHostAdapter implements HttpClientAdapter {
  final int failures;
  final DioExceptionType failureType;
  int calls = 0;

  _SleepingHostAdapter({
    required this.failures,
    this.failureType = DioExceptionType.connectionTimeout,
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (calls <= failures) {
      throw DioException(requestOptions: options, type: failureType);
    }
    return ResponseBody.fromString(
      '{"ok":true}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(_SleepingHostAdapter adapter, {int maxRetries = 2}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
  dio.httpClientAdapter = adapter;
  dio.interceptors.add(
    ColdStartRetryInterceptor(
      dio,
      // No real waiting in tests.
      retryDelay: Duration.zero,
      maxRetries: maxRetries,
    ),
  );
  return dio;
}

void main() {
  group('cold start retry', () {
    test('a GET that times out once then succeeds is retried', () async {
      final adapter = _SleepingHostAdapter(failures: 1);
      final dio = _dioWith(adapter);

      final response = await dio.get('/products');

      expect(response.statusCode, 200);
      // Original attempt plus one retry.
      expect(adapter.calls, 2);
    });

    test('retries stop at the configured limit', () async {
      // Never recovers, so every retry is used and the error still surfaces.
      final adapter = _SleepingHostAdapter(failures: 99);
      final dio = _dioWith(adapter, maxRetries: 2);

      await expectLater(
        dio.get('/products'),
        throwsA(isA<DioException>()),
      );
      // 1 original + 2 retries.
      expect(adapter.calls, 3);
    });

    test('a connection error is retried, not just a timeout', () async {
      final adapter = _SleepingHostAdapter(
        failures: 1,
        failureType: DioExceptionType.connectionError,
      );
      final dio = _dioWith(adapter);

      final response = await dio.get('/products');
      expect(response.statusCode, 200);
      expect(adapter.calls, 2);
    });

    test('a POST is never retried, so a write cannot be duplicated', () async {
      final adapter = _SleepingHostAdapter(failures: 1);
      final dio = _dioWith(adapter);

      await expectLater(
        dio.post('/loans/l1/repayments', data: {'amount': 50000}),
        throwsA(isA<DioException>()),
      );
      // Exactly one attempt: replaying it could record the payment twice.
      expect(adapter.calls, 1);
    });

    test('a bad response is not retried', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
      var calls = 0;
      dio.httpClientAdapter = _StatusAdapter(401, onCall: () => calls++);
      dio.interceptors.add(
        ColdStartRetryInterceptor(dio, retryDelay: Duration.zero),
      );

      await expectLater(dio.get('/products'), throwsA(isA<DioException>()));
      // A 401 is an answer, not a sleeping host.
      expect(calls, 1);
    });
  });

  group('timeout configuration', () {
    test('defaults are long enough to survive a cold start', () {
      // Free hosting cold starts routinely take 30-60s.
      expect(AppConfig.connectTimeout.inSeconds, greaterThanOrEqualTo(60));
      expect(AppConfig.receiveTimeout.inSeconds, greaterThanOrEqualTo(60));
      expect(AppConfig.sendTimeout.inSeconds, greaterThanOrEqualTo(60));
    });

    test('retries are configured but bounded', () {
      expect(AppConfig.coldStartRetries, greaterThan(0));
      expect(AppConfig.coldStartRetries, lessThanOrEqualTo(3));
    });

    test('a debug build points at a local backend', () {
      // Tests run in debug, so this is the branch a developer gets.
      expect(AppConfig.apiBaseUrl, contains('/api/v1'));
      expect(AppConfig.apiBaseUrl, startsWith('http://'));
      expect(AppConfig.usesHostedApi, isFalse);
    });

    test('the hosted host is https and carries no path', () {
      // Release builds append /api/v1 to this, so a trailing path would break.
      expect(AppConfig.hostedApiHost, startsWith('https://'));
      expect(AppConfig.hostedApiHost, isNot(endsWith('/')));
      expect(AppConfig.hostedApiHost, isNot(contains('/api')));
    });
  });
}

class _StatusAdapter implements HttpClientAdapter {
  final int status;
  final void Function() onCall;

  _StatusAdapter(this.status, {required this.onCall});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onCall();
    return ResponseBody.fromString(
      '{"detail":"nope"}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
