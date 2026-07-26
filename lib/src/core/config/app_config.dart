import 'package:flutter/foundation.dart';

/// Environment configuration for the app.
///
/// ## Which API a build talks to
///
/// * `--dart-define=API_BASE_URL=...` wins, always.
/// * Otherwise a **release** build uses the hosted API. This matters: a release
///   APK that fell back to localhost would point at the emulator's loopback
///   address and fail on every real phone, which is easy to ship by accident.
/// * Otherwise a **debug** build uses a local server, so `flutter run` needs no
///   extra flags.
///
/// ```
/// # Point a debug build at a machine on your LAN
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
///
/// # Release build against the hosted API (the default)
/// flutter build apk --release
/// ```
class AppConfig {
  const AppConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// The deployed backend.
  ///
  /// Note the `-l8op` suffix: onrender.com subdomains are globally unique, so
  /// Render appends one when a service name is already taken. `agrichain-api`
  /// without the suffix belongs to somebody else entirely — pointing at it sends
  /// sign-up and login requests to a stranger's server.
  ///
  /// Mobile builds cannot read render.yaml, so this constant is the mobile
  /// default. Override per build with:
  ///   flutter build apk --release --dart-define=API_HOST=https://other.host
  static const String hostedApiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'https://agrichain-api-l8op.onrender.com',
  );

  /// Base URL of the FastAPI backend, including the `/api/v1` prefix.
  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (kReleaseMode) return '$hostedApiHost/api/v1';
    return '$_debugHost/api/v1';
  }

  /// True when this build talks to the deployed backend rather than a local one.
  static bool get usesHostedApi =>
      apiBaseUrl.startsWith('https://') || _override.startsWith('https://');

  /// Where a debug build looks for a local backend.
  ///
  /// The Android emulator reaches the host machine through 10.0.2.2; localhost
  /// there belongs to the emulated device itself.
  static String get _debugHost {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  // Timeouts are generous by default because free hosting tiers suspend an idle
  // container: the first request has to wait for a cold start, which regularly
  // takes 30-60 seconds. A short timeout there looks like an outage to the user.
  // Tune per environment with --dart-define if the backend is always warm.
  static const int _connectSeconds = int.fromEnvironment(
    'API_CONNECT_TIMEOUT_SECONDS',
    defaultValue: 60,
  );
  static const int _receiveSeconds = int.fromEnvironment(
    'API_RECEIVE_TIMEOUT_SECONDS',
    defaultValue: 60,
  );

  static const Duration connectTimeout = Duration(seconds: _connectSeconds);
  static const Duration receiveTimeout = Duration(seconds: _receiveSeconds);
  static const Duration sendTimeout = Duration(seconds: _connectSeconds);

  /// How many times a *safe* request is retried when the host looks asleep.
  ///
  /// Only idempotent methods are retried; replaying a POST could duplicate a
  /// repayment or a loan application.
  static const int coldStartRetries = int.fromEnvironment(
    'API_COLD_START_RETRIES',
    defaultValue: 2,
  );

  /// Pause between those retries, giving the container time to finish booting.
  static const Duration retryDelay = Duration(seconds: 3);
}
