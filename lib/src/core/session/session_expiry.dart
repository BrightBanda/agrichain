import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A tick that increments whenever the backend rejects our token.
///
/// This exists so the Dio interceptor can report an expired session without
/// depending on the auth view model, which itself depends on Dio.
class SessionExpiryNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void markExpired() => state = state + 1;
}

final sessionExpiryProvider = NotifierProvider<SessionExpiryNotifier, int>(
  SessionExpiryNotifier.new,
);
