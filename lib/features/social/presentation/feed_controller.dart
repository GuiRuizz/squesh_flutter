import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/social_api_service.dart';
import '../domain/social_models.dart';

/// De onde vêm os posts exibidos no feed.
enum FeedScope {
  /// Só quem o usuário segue (mais os próprios posts) — GET /posts/feed.
  following,

  /// Todos os posts públicos — GET /posts.
  everyone,
}

/// Estado do feed: os posts já carregados + de onde vieram.
class FeedState {
  final List<SocialPost> posts;
  final FeedScope scope;

  const FeedState({required this.posts, required this.scope});
}

final feedControllerProvider =
    AsyncNotifierProvider<FeedController, FeedState>(FeedController.new);

class FeedController extends AsyncNotifier<FeedState> {
  /// Escopo que o usuário escolheu na tela (null = ainda não escolheu).
  FeedScope? _scope;

  @override
  Future<FeedState> build() async {
    _scope = null;
    return _load(FeedScope.following);
  }

  /// Troca o escopo do feed (Seguindo / Todos).
  Future<void> setScope(FeedScope scope) async {
    if (state.value?.scope == scope) return;
    _scope = scope;
    state = await AsyncValue.guard(() => _load(scope));
  }

  Future<FeedState> _load(FeedScope scope) async {
    final service = ref.read(socialApiServiceProvider);
    final posts = scope == FeedScope.following
        ? await service.getFeed()
        : await service.getPublicFeed();

    // Feed "Seguindo" vazio (não segue ninguém e não tem posts ainda) não pode
    // deixar a tela morta: mostra o feed público e avisa que está em "Todos".
    if (posts.isEmpty && scope == FeedScope.following) {
      return FeedState(posts: await service.getPublicFeed(), scope: FeedScope.everyone);
    }

    return FeedState(posts: posts, scope: scope);
  }

  List<SocialPost> get _posts => state.value?.posts ?? const [];

  /// Post pelo id (usado pelos cards, que são stateless).
  SocialPost? postById(String id) {
    for (final post in _posts) {
      if (post.id == id) return post;
    }
    return null;
  }

  /// Like/deslike otimista: atualiza a UI na hora e reverte se a API falhar.
  Future<void> toggleLike(String postId) async {
    final current = state.value;
    if (current == null) return;

    final index = current.posts.indexWhere((p) => p.id == postId);
    if (index < 0) return;

    final post = current.posts[index];
    final willLike = !post.likedByMe;

    state = AsyncData(
      FeedState(
        posts: [
          for (var i = 0; i < current.posts.length; i++)
            if (i == index)
              post.copyWith(
                likedByMe: willLike,
                likesCount: post.likesCount + (willLike ? 1 : -1),
              )
            else
              current.posts[i],
        ],
        scope: current.scope,
      ),
    );

    try {
      final service = ref.read(socialApiServiceProvider);
      if (willLike) {
        await service.likePost(postId);
      } else {
        await service.unlikePost(postId);
      }
    } catch (_) {
      state = AsyncData(current); // reverte
      rethrow;
    }
  }

  Future<void> addComment(String postId, String text) async {
    final comment =
        await ref.read(socialApiServiceProvider).addComment(postId, text);
    _replacePost(
      postId,
      (p) => p.copyWith(comments: [...p.comments, comment]),
    );
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await ref.read(socialApiServiceProvider).deleteComment(postId, commentId);
    _replacePost(
      postId,
      (p) => p.copyWith(
        comments: p.comments.where((c) => c.id != commentId).toList(),
      ),
    );
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

    // O autor vem do token no backend, então o app não manda user_id.
    final presign = await service.presignUpload(
      filename: filename,
      contentType: contentType,
    );
    await service.uploadFile(
      uploadUrl: presign.uploadUrl,
      file: imageFile,
      contentType: contentType,
    );

    final post = await service.createPost(
      imageUrl: presign.imageUrl,
      caption: caption,
    );

    // Insere o post novo no topo do feed sem refazer o fetch inteiro.
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        FeedState(posts: [post, ...current.posts], scope: current.scope),
      );
    } else {
      await refresh();
    }
    return post;
  }

  /// Recarrega o feed do servidor (pull-to-refresh).
  Future<void> refresh() async {
    final scope = _scope ?? state.value?.scope ?? FeedScope.following;
    _scope = scope;
    state = await AsyncValue.guard(() => _load(scope));
  }

  void _replacePost(String postId, SocialPost Function(SocialPost) change) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      FeedState(
        posts: [
          for (final p in current.posts)
            if (p.id == postId) change(p) else p,
        ],
        scope: current.scope,
      ),
    );
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