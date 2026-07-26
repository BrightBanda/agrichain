import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/auth_session.dart';
import '../models/requests.dart';
import '../models/user.dart';

/// The Model half of MVVM for authentication: talks to `/auth/*` and returns
/// domain objects, never Dio types.
class AuthRepository {
  final Dio _dio;

  const AuthRepository(this._dio);

  /// `POST /auth/login`
  Future<AuthSession> login(LoginRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: request.toJson(),
        options: Options(extra: publicRequest),
      );
      return AuthSession.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      // A 401 here means bad credentials, not an expired session.
      if (error.response?.statusCode == 401) {
        throw const ApiException(
          'Invalid phone number or password.',
          statusCode: 401,
        );
      }
      throw ApiException.fromDio(error);
    }
  }

  /// `POST /auth/register/farmer`
  ///
  /// Returns the created user; the endpoint issues no token, so the caller
  /// still has to log in.
  Future<User> registerFarmer(FarmerRegisterRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.registerFarmer,
        data: request.toJson(),
        options: Options(extra: publicRequest),
      );
      return User.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);
