import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(ref.watch(dioProvider));
});

class AuthApiService {
  final Dio _dio;

  AuthApiService(this._dio);

  /// POST /auth/login -> { token, refresh_token, expires_in, token_type, user }
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// POST /auth/register -> { token, refresh_token, expires_in, token_type, user }
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {'name': name, 'email': email, 'password': password},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// POST /auth/logout (revoga o refresh_token no backend)
  Future<void> logout(String refreshToken) async {
    await _dio.post(
      ApiEndpoints.logout,
      data: {'refresh_token': refreshToken},
    );
  }
}