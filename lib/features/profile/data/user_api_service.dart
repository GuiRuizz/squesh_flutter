import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';

final userApiServiceProvider = Provider<UserApiService>((ref) {
  return UserApiService(ref.watch(dioProvider));
});

class UserApiService {
  final Dio _dio;

  UserApiService(this._dio);

  // GET /api/v1/users/me
  Future<Response> getProfile() async {
    return await _dio.get(ApiEndpoints.userMe);
  }

  // GET /api/v1/users/me/streak
  Future<Response> getStreak() async {
    return await _dio.get(ApiEndpoints.userStreak);
  }

  // GET /api/v1/users/ranking
  Future<Response> getRanking() async {
    return await _dio.get(ApiEndpoints.userRanking);
  }

  // PUT /api/v1/users/me
  Future<Response> updateProfile(Map<String, dynamic> data) async {
    return await _dio.put(ApiEndpoints.userMe, data: data);
  }

  // PATCH /api/v1/users/me/password
  Future<Response> updatePassword(Map<String, dynamic> data) async {
    return await _dio.patch(ApiEndpoints.updatePassword, data: data);
  }
}
