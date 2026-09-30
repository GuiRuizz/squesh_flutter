import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/social_api_service.dart';
import '../domain/social_models.dart';

/// Estado do feed. build() carrega o feed personalizado assim que o provider
/// é ouvido (a aba Fotos só existe com sessão ativa, então o token já está lá).
final feedControllerProvider = AsyncNotifierProvider<FeedController, List<SocialPost>>(
  FeedController.new,
);

class FeedController extends AsyncNotifier<List<SocialPost>> {
  @override
  Future<List<SocialPost>> build() async {
    return await ref.watch(socialApiServiceProvider).getFeed();
  }

  /// Like/deslike otimista: atualiza a UI na hora e reverte se a API falhar.
  Future<void> toggleLike(String postId) async {
    final posts = state.value ?? [];
    final index = posts.indexWhere((p) => p.id == postId);
    if (index < 0) return;

    final post = posts[index];
    final willLike = !post.likedByMe;

    state = AsyncData([
      for (var i = 0; i < posts.length; i++)
        if (i == index)
          post.copyWith(
            likedByMe: willLike,
            likesCount: post.likesCount + (willLike ? 1 : -1),
          )
        else
          posts[i],
    ]);

    try {
      final service = ref.read(socialApiServiceProvider);
      if (willLike) {
        await service.likePost(postId);
      } else {
        await service.unlikePost(postId);
      }
    } catch (_) {
      state = AsyncData(posts); // reverte
      rethrow;
    }
  }

  Future<void> addComment(String postId, String text) async {
    final comment =
        await ref.read(socialApiServiceProvider).addComment(postId, text);
    final posts = state.value ?? [];
    state = AsyncData([
      for (final p in posts)
        if (p.id == postId) p.copyWith(comments: [...p.comments, comment]) else p,
    ]);
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await ref.read(socialApiServiceProvider).deleteComment(postId, commentId);
    final posts = state.value ?? [];
    state = AsyncData([
      for (final p in posts)
        if (p.id == postId)
          p.copyWith(
            comments: p.comments.where((c) => c.id != commentId).toList(),
          )
        else
          p,
    ]);
  }

  /// Publica uma foto: presign -> PUT binário na URL assinada -> POST /posts.
  /// Retorna o post criado para a tela exibir feedback.
  Future<SocialPost> publishPost({
    required File imageFile,
    required String caption,
  }) async {
    final service = ref.read(socialApiServiceProvider);
    final filename = imageFile.path.split(RegExp(r'[\\/]')).last;
    final contentType = _contentTypeFor(filename);

    final presign = await service.presignUpload(
      filename: filename,
      contentType: contentType,
    );
    await service.uploadFile(
      uploadUrl: presign.uploadUrl,
      file: imageFile,
      contentType: contentType,
    );

    final me = await ref.read(authControllerProvider.future);
    final post = await service.createPost(
      userId: me!.id,
      imageUrl: presign.imageUrl,
      caption: caption,
    );

    // Insere o post novo no topo do feed sem refazer o fetch inteiro.
    state = AsyncData([post, ...?state.value]);
    return post;
  }

  /// Recarrega o feed do servidor (pull-to-refresh).
  Future<void> refresh() async {
    try {
      final posts = await ref.read(socialApiServiceProvider).getFeed();
      state = AsyncData(posts);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  String _contentTypeFor(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }
}