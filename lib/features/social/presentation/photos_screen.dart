import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/presentation/auth_controller.dart';
import '../domain/social_models.dart';
import 'feed_controller.dart';

/// Tela Social — feed real ligado à API:
/// GET /posts/feed (personalizado), curtidas, comentários e publicação com
/// upload por URL assinada (presign).
class PhotosScreen extends ConsumerWidget {
  const PhotosScreen({super.key});

  Future<void> _pickAndPublishPhoto(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();

    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1080,
    );

    if (pickedFile == null || !context.mounted) return;

    _showPublishDialog(context, ref, File(pickedFile.path));
  }

  void _showPublishDialog(BuildContext context, WidgetRef ref, File imageFile) {
    final captionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            bool publishing = false;

            Future<void> publish() async {
              if (publishing) return;
              setSheetState(() => publishing = true);
              try {
                await ref.read(feedControllerProvider.notifier).publishPost(
                      imageFile: imageFile,
                      caption: captionController.text.trim(),
                    );
                if (context.mounted) {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Progresso publicado! 🎉')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  setSheetState(() => publishing = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_errorMessage(e, 'Erro ao publicar.'))),
                  );
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Novo Progresso',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      imageFile,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: captionController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Escreva uma legenda para o seu progresso...',
                      hintStyle: TextStyle(color: Color(0xFF666666), fontSize: 13),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF262626)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFF1E40)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF1E40),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: publishing ? null : publish,
                    child: publishing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'PUBLICAR NO FEED',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showImageSourceOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: Color(0xFFFF1E40),
                ),
                title: const Text(
                  'Tirar foto na hora',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndPublishPhoto(context, ref, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFFFF1E40),
                ),
                title: const Text(
                  'Escolher da galeria',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndPublishPhoto(context, ref, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _errorMessage(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is String) {
        return data['error'] as String;
      }
      return 'Não foi possível conectar ao servidor.';
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        title: const Text(
          'SOCIAL',
          style: TextStyle(
            color: Color(0xFFFF1E40),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_a_photo_rounded,
              color: Color(0xFFFF1E40),
            ),
            onPressed: () => _showImageSourceOptions(context, ref),
          ),
        ],
      ),
      body: feedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF1E40)),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: Color(0xFF555555),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Não foi possível carregar o feed.',
                  style: TextStyle(color: Color(0xFF888888)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF1E40)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFFFF1E40),
                  ),
                  label: const Text(
                    'Tentar novamente',
                    style: TextStyle(
                      color: Color(0xFFFF1E40),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () =>
                      ref.read(feedControllerProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
        data: (posts) => RefreshIndicator(
          color: const Color(0xFFFF1E40),
          onRefresh: () => ref.read(feedControllerProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () => _showImageSourceOptions(context, ref),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF262626)),
                    ),
                    child: Row(
                      children: [
                        _Avatar(
                          url: _avatarUrl(
                            ref.watch(authControllerProvider).value?.avatarUrl,
                            ref.watch(authControllerProvider).value?.id ?? '',
                          ),
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Compartilhe seu progresso de hoje...',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF1E40),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (posts.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      'Nenhum post por aqui ainda.\n'
                      'Comece a seguir pessoas e publique seu progresso!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final post = posts[index];
                    return _PostCard(
                      key: ValueKey(post.id),
                      postId: post.id,
                    );
                  }, childCount: posts.length),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final String postId;

  const _PostCard({super.key, required this.postId});

  void _showCommentsBottomSheet(BuildContext context, WidgetRef ref) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final myId = ref
            .watch(authControllerProvider)
            .value
            ?.id; // usado p/ apagar só os próprios comentários

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF333333),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Comentários',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: Consumer(
                  builder: (context, ref, child) {
                    final comments = _findComments(
                          ref.watch(feedControllerProvider).value,
                          postId,
                        ) ??
                        const <SocialComment>[];

                    if (comments.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Seja o primeiro a comentar!',
                          style: TextStyle(color: Color(0xFF666666)),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final isMine = comment.user.id == myId;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _Avatar(
                            url: _avatarUrl(
                              comment.user.avatarUrl,
                              comment.user.id,
                            ),
                            radius: 16,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  comment.user.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                comment.timeAgo,
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            comment.text,
                            style: const TextStyle(
                              color: Color(0xFFCCCCCC),
                              fontSize: 13,
                            ),
                          ),
                          trailing: isMine
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFF666666),
                                    size: 18,
                                  ),
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(feedControllerProvider.notifier)
                                          .deleteComment(postId, comment.id);
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Não foi possível apagar o comentário.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(color: Color(0xFF262626)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Adicione um comentário...',
                        hintStyle: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFFFF1E40),
                    ),
                    onPressed: () async {
                      final text = commentController.text.trim();
                      if (text.isEmpty) return;
                      commentController.clear();
                      try {
                        await ref
                            .read(feedControllerProvider.notifier)
                            .addComment(postId, text);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Não foi possível comentar.'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = _findPost(
      ref.watch(feedControllerProvider).value,
      postId,
    );
    if (post == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _Avatar(
                  url: _avatarUrl(post.user.avatarUrl, post.user.id),
                  radius: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.user.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        post.timeAgo,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (post.imageUrl.isNotEmpty)
            ClipRRect(
              child: Image.network(
                post.imageUrl,
                width: double.infinity,
                height: 260,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 260,
                  color: const Color(0xFF1A1A1A),
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFF444444),
                    size: 40,
                  ),
                ),
              ),
            ),
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                post.caption,
                style: const TextStyle(color: Color(0xFFDDDDDD), fontSize: 13),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    post.likedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    color: post.likedByMe
                        ? const Color(0xFFFF1E40)
                        : const Color(0xFF888888),
                  ),
                  onPressed: () async {
                    try {
                      await ref
                          .read(feedControllerProvider.notifier)
                          .toggleLike(post.id);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Não foi possível curtir.'),
                          ),
                        );
                      }
                    }
                  },
                ),
                Text(
                  '${post.likesCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF888888),
                  ),
                  onPressed: () => _showCommentsBottomSheet(context, ref),
                ),
                Text(
                  '${post.comments.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar com fallback: se o usuário não tem avatar_url cadastrado, gera um
/// avatar determinístico (pravatar) a partir do id.
class _Avatar extends StatelessWidget {
  final String url;
  final double radius;

  const _Avatar({required this.url, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF262626),
      backgroundImage: url.isEmpty ? null : NetworkImage(url),
      onBackgroundImageError: url.isEmpty ? null : (_, _) {},
    );
  }
}

String _avatarUrl(String? avatarUrl, String seed) {
  final url = (avatarUrl ?? '').trim();
  if (url.isNotEmpty) return url;
  final n = seed.hashCode.abs() % 70;
  return 'https://i.pravatar.cc/150?img=$n';
}

SocialPost? _findPost(List<SocialPost>? posts, String id) {
  if (posts == null) return null;
  for (final post in posts) {
    if (post.id == id) return post;
  }
  return null;
}

List<SocialComment>? _findComments(
  List<SocialPost>? posts,
  String postId,
) {
  final post = _findPost(posts, postId);
  return post?.comments;
}