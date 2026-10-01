import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../domain/social_models.dart';

final socialApiServiceProvider = Provider<SocialApiService>((ref) {
  return SocialApiService(ref.watch(dioProvider));
});

class SocialApiService {
  final Dio _dio;

  SocialApiService(this._dio);

  /// GET /posts/feed — feed personalizado (posts de quem sigo + meus posts).
  Future<List<SocialPost>> getFeed() async {
    final response = await _dio.get(ApiEndpoints.postsFeed);
    return _parsePosts(response.data);
  }

  /// GET /posts — feed público (fallback).
  Future<List<SocialPost>> getPublicFeed() async {
    final response = await _dio.get(ApiEndpoints.posts);
    return _parsePosts(response.data);
  }

  /// POST /posts/:id/like (idempotente)
  Future<void> likePost(String postId) async {
    await _dio.post(ApiEndpoints.likePost(postId));
  }

  /// DELETE /posts/:id/like (idempotente) — mesma URL, verbo DELETE.
  Future<void> unlikePost(String postId) async {
    await _dio.delete(ApiEndpoints.likePost(postId));
  }

  Future<List<SocialComment>> getComments(String postId) async {
    final response = await _dio.get(ApiEndpoints.postComments(postId));
    final list = response.data as List;
    return [
      for (final item in list)
        SocialComment.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  /// POST /posts/:id/comments — o user_id vem do token no backend.
  Future<SocialComment> addComment(String postId, String text) async {
    final response = await _dio.post(
      ApiEndpoints.postComments(postId),
      data: {'text': text},
    );
    return SocialComment.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _dio.delete('${ApiEndpoints.postComments(postId)}/$commentId');
  }

  /// PUT /posts/:id — o backend só aceita mexer na legenda.
  Future<void> updatePostCaption(String postId, String caption) async {
    await _dio.put(
      ApiEndpoints.updatePost(postId),
      data: {'caption': caption},
    );
  }

  /// DELETE /posts/:id — só o dono apaga (o Go devolve 403 para os demais).
  Future<void> deletePost(String postId) async {
    await _dio.delete(ApiEndpoints.deletePost(postId));
  }

  /// POST /uploads/presign -> { upload_url, image_url, key }
  ///
  /// [folder] separa foto de post ("posts", o padrão) de foto de perfil
  /// ("avatars"). O backend só aceita esses dois valores.
  Future<PresignResult> presignUpload({
    required String filename,
    required String contentType,
    String folder = 'posts',
  }) async {
    final response = await _dio.post(
      ApiEndpoints.uploadsPresign,
      data: {
        'filename': filename,
        'content_type': contentType,
        'folder': folder,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return PresignResult(
      uploadUrl: (data['upload_url'] as String?) ?? '',
      imageUrl: (data['image_url'] as String?) ?? '',
      key: (data['key'] as String?) ?? '',
    );
  }

  /// PUT binário na URL assinada — o arquivo nunca passa pelo servidor.
  Future<void> uploadFile({
    required String uploadUrl,
    required File file,
    required String contentType,
  }) async {
    final bytes = await file.readAsBytes();
    await _dio.put<dynamic>(
      uploadUrl,
      data: bytes,
      options: Options(
        contentType: contentType,
        headers: {'Content-Length': bytes.length.toString()},
      ),
    );
  }

  /// POST /posts — cria o post com a URL pública retornada pelo presign.
  /// O autor vem do token: não mandamos user_id.
  Future<SocialPost> createPost({
    required String imageUrl,
    required String caption,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.posts,
      data: {'image_url': imageUrl, 'caption': caption},
    );
    return SocialPost.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  List<SocialPost> _parsePosts(dynamic data) {
    if (data is! List) return const [];
    return [
      for (final item in data)
        SocialPost.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }
}

class PresignResult {
  final String uploadUrl;
  final String imageUrl;
  final String key;

  const PresignResult({
    required this.uploadUrl,
    required this.imageUrl,
    required this.key,
  });
}