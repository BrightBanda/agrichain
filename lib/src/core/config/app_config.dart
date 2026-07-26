import 'package:flutter/foundation.dart';

/// Environment configuration for the app.
///
/// The API host can be overridden at build time, which is how you point a
/// physical device at a machine on your LAN:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
/// ```
class AppConfig {
  const AppConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Base URL of the FastAPI backend, including the `/api/v1` prefix.
  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    return '$_defaultHost/api/v1';
  }

  /// The Android emulator reaches the host machine through 10.0.2.2 rather
  /// than localhost, which belongs to the emulated device itself.
  static String get _defaultHost {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
