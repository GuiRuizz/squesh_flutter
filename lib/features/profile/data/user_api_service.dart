import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../social/domain/social_models.dart';
import '../domain/user_preferences.dart';
import '../domain/user_profile.dart';

final userApiServiceProvider = Provider<UserApiService>((ref) {
  return UserApiService(ref.watch(dioProvider));
});

class UserApiService {
  final Dio _dio;

  UserApiService(this._dio);

  // GET /api/v1/users/me
  Future<UserProfile> getProfile() async {
    final response = await _dio.get(ApiEndpoints.userMe);
    return UserProfile.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  // GET /api/v1/users/me/streak
  Future<Response> getStreak() async {
    return await _dio.get(ApiEndpoints.userStreak);
  }

  // GET /api/v1/users/ranking
  Future<Response> getRanking() async {
    return await _dio.get(ApiEndpoints.userRanking);
  }

  /// PUT /api/v1/users/me — atualização parcial: só os campos não nulos vão no
  /// corpo, então editar a bio não mexe no nome (e vice-versa).
  Future<UserProfile> updateProfile({
    String? name,
    String? bio,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (bio != null) body['bio'] = bio;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;

    final response = await _dio.put(ApiEndpoints.userMe, data: body);
    return UserProfile.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// PUT /api/v1/users/me/preferences
  Future<UserProfile> updatePreferences(UserPreferences preferences) async {
    final response = await _dio.put(
      ApiEndpoints.userPreferences,
      data: preferences.toPatch(),
    );
    return UserProfile.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  // PATCH /api/v1/users/me/password
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.patch(
      ApiEndpoints.updatePassword,
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  /// GET /api/v1/users/me/posts —posts do usuário logado (tela Meus Posts).
  /// O dono vem do token, então não é preciso mandar id.
  Future<List<SocialPost>> getMyPosts() async {
    final response = await _dio.get(ApiEndpoints.userMyPosts);
    final data = response.data;
    if (data is! List) return const [];
    return [
      for (final item in data)
        SocialPost.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }
}
