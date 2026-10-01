import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/presentation/settings_widgets.dart';
import '../../social/data/social_api_service.dart';
import '../../social/domain/social_models.dart';
import '../data/user_api_service.dart';

/// Posts do usuário logado.
///
/// A tela usava uma lista hardcoded (picsum.photos, curtidas e comentários
/// inventados) e as ações só mexiam no texto do mock — nada chegava ao
/// backend. Agora os dados vêm de `GET /users/me/posts` e editar/apagar vão
/// para a API de verdade.
class MyPostsScreen extends ConsumerStatefulWidget {
  const MyPostsScreen({super.key});

  @override
  ConsumerState<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends ConsumerState<MyPostsScreen> {
  bool _loading = true;
  String? _error;
  List<SocialPost> _posts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final posts = await ref.read(userApiServiceProvider).getMyPosts();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = describeError(e);
        _loading = false;
      });
    }
  }

  Future<void> _editCaption(SocialPost post) async {
    final controller = TextEditingController(text: post.caption);
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SettingsColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: settingsSheetRadius),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'EDITAR LEGENDA',
              style: TextStyle(
                color: SettingsColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            SettingsTextField(
              controller: controller,
              label: 'Legenda',
              maxLength: 2200,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            SettingsPrimaryButton(
              label: 'SALVAR',
              onPressed: () => Navigator.pop(sheetContext, controller.text),
            ),
          ],
        ),
      ),
    );

    final caption = saved?.trim();
    if (caption == null || caption == post.caption) return;

    try {
      await ref.read(socialApiServiceProvider).updatePostCaption(
        post.id,
        caption,
      );
      if (!mounted) return;
      setState(() {
        _posts = [
          for (final p in _posts)
            if (p.id == post.id) p.copyWith(caption: caption) else p,
        ];
      });
      showSettingsSnack(context, 'Legenda atualizada.');
    } catch (e) {
      if (mounted) showSettingsSnack(context, describeError(e), error: true);
    }
  }

  Future<void> _deletePost(SocialPost post) async {
    final confirmed = await confirmSettingsAction(
      context,
      title: 'Apagar publicação',
      message:
          'A foto, a legenda e todos os comentários dessa publicação serão '
          'removidos. Não dá para desfazer.',
      confirmLabel: 'APAGAR',
    );
    if (!confirmed) return;

    try {
      await ref.read(socialApiServiceProvider).deletePost(post.id);
      if (!mounted) return;
      setState(() {
        _posts = _posts.where((p) => p.id != post.id).toList();
      });
      showSettingsSnack(context, 'Publicação apagada.');
    } catch (e) {
      if (mounted) showSettingsSnack(context, describeError(e), error: true);
    }
  }

  Future<void> _deleteComment(SocialPost post, SocialComment comment) async {
    final confirmed = await confirmSettingsAction(
      context,
      title: 'Apagar comentário',
      message: '"${_snippet(comment.text)}" será removido. Não dá para desfazer.',
      confirmLabel: 'APAGAR',
    );
    if (!confirmed) return;

    try {
      await ref
          .read(socialApiServiceProvider)
          .deleteComment(post.id, comment.id);
      if (!mounted) return;
      setState(() {
        _posts = [
          for (final p in _posts)
            if (p.id == post.id)
              p.copyWith(
                comments: p.comments
                    .where((c) => c.id != comment.id)
                    .toList(),
              )
            else
              p,
        ];
      });
      showSettingsSnack(context, 'Comentário apagado.');
    } catch (e) {
      if (mounted) showSettingsSnack(context, describeError(e), error: true);
    }
  }

  Future<void> _openComments(String postId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SettingsColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: settingsSheetRadius),
      // watchedPost: a folha precisa ver a lista mudando. Passar o post
      // inteiro travava o valor no momento em que a folha abriu, e o
      // comentário apagado continuaria aparecendo até fechar.
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final post = _posts.where((p) => p.id == postId).firstOrNull;
          if (post == null) return const SizedBox.shrink();

          return _CommentsSheet(
            post: post,
            onDelete: (comment) => _deleteComment(post, comment),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsColors.background,
      appBar: const SettingsAppBar('MEUS POSTS'),
      body: RefreshIndicator(
        color: SettingsColors.accent,
        backgroundColor: SettingsColors.surface,
        onRefresh: _load,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const SettingsLoading();

    if (_error != null) {
      return SettingsErrorView(message: _error!, onRetry: _load);
    }

    if (_posts.isEmpty) {
      return SettingsEmptyView(
        icon: Icons.photo_camera_back_outlined,
        title: 'Você ainda não publicou nada',
        message:
            'As fotos que você postar no feed aparecem aqui, com opção de '
            'editar a legenda, apagar a publicação e apagar seus comentários.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _MyPostCard(
          post: post,
          onEditCaption: () => _editCaption(post),
          onDelete: () => _deletePost(post),
          onOpenComments: () => _openComments(post.id),
        );
      },
    );
  }

  static String _snippet(String text) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.length <= 60 ? clean : '${clean.substring(0, 60)}...';
  }
}

class _MyPostCard extends StatelessWidget {
  final SocialPost post;
  final VoidCallback onEditCaption;
  final VoidCallback onDelete;
  final VoidCallback onOpenComments;

  const _MyPostCard({
    required this.post,
    required this.onEditCaption,
    required this.onDelete,
    required this.onOpenComments,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(11),
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: post.imageUrl.isEmpty
                  ? Container(color: SettingsColors.surfaceAlt)
                  : Image.network(
                      post.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: SettingsColors.surfaceAlt,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: SettingsColors.textFaint,
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
            child: Row(
              children: [
                Text(
                  post.timeAgo,
                  style: const TextStyle(
                    color: SettingsColors.textFaint,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onEditCaption,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: SettingsColors.textMuted,
                  ),
                  tooltip: 'Editar legenda',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: SettingsColors.accent,
                  ),
                  tooltip: 'Apagar publicação',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.caption.isEmpty ? 'Sem legenda' : post.caption,
                  style: TextStyle(
                    color: post.caption.isEmpty
                        ? SettingsColors.textFaint
                        : SettingsColors.textSecondary,
                    fontSize: 13,
                    fontStyle: post.caption.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 15,
                      color: SettingsColors.textFaint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount}',
                      style: const TextStyle(
                        color: SettingsColors.textFaint,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 14),
                    InkWell(
                      onTap: onOpenComments,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mode_comment_outlined,
                            size: 15,
                            color: SettingsColors.textFaint,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.comments.length}',
                            style: const TextStyle(
                              color: SettingsColors.textFaint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'ver',
                      style: TextStyle(
                        color: SettingsColors.textFaint,
                        fontSize: 11,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 15,
                      color: SettingsColors.textFaint,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentsSheet extends StatelessWidget {
  final SocialPost post;
  final void Function(SocialComment) onDelete;

  const _CommentsSheet({required this.post, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMENTÁRIOS (${post.comments.length})',
            style: const TextStyle(
              color: SettingsColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          if (post.comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Ninguém comentou ainda.',
                  style: TextStyle(
                    color: SettingsColors.textFaint,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: post.comments.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: SettingsColors.divider),
                itemBuilder: (context, index) {
                  final comment = post.comments[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ProfileAvatar(
                      avatarUrl: comment.user.avatarUrl,
                      name: comment.user.name,
                      size: 36,
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            comment.user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SettingsColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          comment.timeAgo,
                          style: const TextStyle(
                            color: SettingsColors.textFaint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      comment.text,
                      style: const TextStyle(
                        color: SettingsColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    trailing: IconButton(
                      onPressed: () => onDelete(comment),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: SettingsColors.accent,
                      ),
                      tooltip: 'Apagar comentário',
                    ),
                  );
                },
              ),
            ),
          if (post.comments.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Só é possível apagar os próprios comentários. Para apagar a '
              'publicação inteira, use a lixeira no card do post.',
              style: TextStyle(color: SettingsColors.textFaint, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}