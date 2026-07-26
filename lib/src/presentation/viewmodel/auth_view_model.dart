import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_expiry.dart';
import '../../core/storage/token_storage.dart';
import '../../data/models/auth_session.dart';
import '../../data/models/requests.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

/// Who the app currently considers to be signed in.
sealed class AuthState {
  const AuthState();
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

final class Authenticated extends AuthState {
  final User user;
  final String token;

  const Authenticated({required this.user, required this.token});
}

/// View model for sign-in, farmer registration and sign-out.
///
/// The state is an [AsyncValue] so views get loading and error handling for
/// free: `AsyncLoading` while a request is in flight, `AsyncError` carrying the
/// [ApiException] message when one fails.
class AuthViewModel extends AsyncNotifier<AuthState> {
  TokenStorage get _storage => ref.read(tokenStorageProvider);
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() async {
    // The Dio interceptor bumps this tick when the backend rejects our token.
    ref.listen(sessionExpiryProvider, (previous, next) {
      if (previous != null && next > previous) {
        state = const AsyncValue.data(Unauthenticated());
      }
    });

    return _restoreSession();
  }

  Future<AuthState> _restoreSession() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return const Unauthenticated();

    final cachedUser = await _storage.readUser();
    if (cachedUser == null) {
      // A token with no user is unusable until the backend exposes /auth/me.
      await _storage.clear();
      return const Unauthenticated();
    }

    return Authenticated(user: User.fromJson(cachedUser), token: token);
  }

  /// Returns true when the user ends up signed in.
  Future<bool> signIn({
    required String phoneNumber,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard<AuthState>(() async {
      final session = await _repository.login(
        LoginRequest(phoneNumber: phoneNumber, password: password),
      );
      return _persist(session);
    });
    state = result;
    return !result.hasError;
  }

  /// Registers a farmer and signs them straight in.
  ///
  /// `POST /auth/register/farmer` returns no token, so this follows up with a
  /// login using the same credentials.
  Future<bool> registerFarmer(FarmerRegisterRequest request) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard<AuthState>(() async {
      await _repository.registerFarmer(request);
      final session = await _repository.login(
        LoginRequest(
          phoneNumber: request.phoneNumber,
          password: request.password,
        ),
      );
      return _persist(session);
    });
    state = result;
    return !result.hasError;
  }

  Future<void> signOut() async {
    await _storage.clear();
    state = const AsyncValue.data(Unauthenticated());
  }

  /// Clears a failed attempt so the form stops showing a stale error.
  void clearError() {
    if (state.hasError) state = const AsyncValue.data(Unauthenticated());
  }

  Future<AuthState> _persist(AuthSession session) async {
    await _storage.writeToken(session.accessToken);
    await _storage.writeUser(session.user.toJson());
    return Authenticated(user: session.user, token: session.accessToken);
  }
}

final authViewModelProvider = AsyncNotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);

/// The signed-in user, or null while loading, failed or signed out.
final currentUserProvider = Provider<User?>((ref) {
  final auth = ref.watch(authViewModelProvider).value;
  return auth is Authenticated ? auth.user : null;
});
