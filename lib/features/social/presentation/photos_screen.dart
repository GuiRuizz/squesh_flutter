import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';

// Modelo de Comentário
class Comment {
  final String id;
  final String userName;
  final String userAvatar;
  final String text;
  final String timeAgo;

  const Comment({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.text,
    required this.timeAgo,
  });
}

// Modelo do Post
class Post {
  final String id;
  final String userName;
  final String userAvatar;
  final String imageUrl;
  final bool isLocalFile;
  final String caption;
  final String timeAgo;
  final int likes;
  final bool isLiked;
  final List<Comment> comments;

  const Post({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.imageUrl,
    this.isLocalFile = false,
    required this.caption,
    required this.timeAgo,
    required this.likes,
    this.isLiked = false,
    required this.comments,
  });

  Post copyWith({
    String? id,
    String? userName,
    String? userAvatar,
    String? imageUrl,
    bool? isLocalFile,
    String? caption,
    String? timeAgo,
    int? likes,
    bool? isLiked,
    List<Comment>? comments,
  }) {
    return Post(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      imageUrl: imageUrl ?? this.imageUrl,
      isLocalFile: isLocalFile ?? this.isLocalFile,
      caption: caption ?? this.caption,
      timeAgo: timeAgo ?? this.timeAgo,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      comments: comments ?? this.comments,
    );
  }
}

// StateNotifier para gerenciar o Feed
class FeedNotifier extends StateNotifier<List<Post>> {
  FeedNotifier()
    : super([
        Post(
          id: '1',
          userName: 'Beatriz Silva',
          userAvatar: 'https://i.pravatar.cc/150?img=5',
          imageUrl:
              'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=800&auto=format&fit=crop',
          caption: 'Treino pago de hoje! Mantendo o foco na meta 💪🔥',
          timeAgo: 'Há 15 min',
          likes: 24,
          isLiked: false,
          comments: [
            const Comment(
              id: 'c1',
              userName: 'Lucas "Blade"',
              userAvatar: 'https://i.pravatar.cc/150?img=11',
              text: 'Aí sim! Foco total!',
              timeAgo: '10 min',
            ),
          ],
        ),
        Post(
          id: '2',
          userName: 'Guilherme Sassi',
          userAvatar: 'https://i.pravatar.cc/150?img=12',
          imageUrl:
              'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?q=80&w=800&auto=format&fit=crop',
          caption: 'Mais um dia batendo o recorde pessoal de pontos na semana!',
          timeAgo: 'Há 2 horas',
          likes: 42,
          isLiked: true,
          comments: [],
        ),
      ]);

  void toggleLike(String postId) {
    state = [
      for (final post in state)
        if (post.id == postId)
          post.copyWith(
            isLiked: !post.isLiked,
            likes: post.isLiked ? post.likes - 1 : post.likes + 1,
          )
        else
          post,
    ];
  }

  void addComment(String postId, String commentText) {
    if (commentText.trim().isEmpty) return;

    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: 'Você',
      userAvatar: 'https://i.pravatar.cc/150?img=68',
      text: commentText.trim(),
      timeAgo: 'Agora',
    );

    state = [
      for (final post in state)
        if (post.id == postId)
          post.copyWith(comments: [...post.comments, newComment])
        else
          post,
    ];
  }

  void addPost({required String imagePath, required String caption}) {
    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: 'Você',
      userAvatar: 'https://i.pravatar.cc/150?img=68',
      imageUrl: imagePath,
      isLocalFile: true,
      caption: caption.trim(),
      timeAgo: 'Agora',
      likes: 0,
      comments: [],
    );

    state = [newPost, ...state];
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, List<Post>>((ref) {
  return FeedNotifier();
});

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
      builder: (context) {
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
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
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
                onPressed: () {
                  ref
                      .read(feedProvider.notifier)
                      .addPost(
                        imagePath: imageFile.path,
                        caption: captionController.text,
                      );
                  Navigator.pop(context);
                },
                child: const Text(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(feedProvider);

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
      body: CustomScrollView(
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
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?img=68',
                      ),
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
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final post = posts[index];
              return _PostCard(key: ValueKey(post.id), postId: post.id);
            }, childCount: posts.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
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
      builder: (context) {
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
                    final comments = ref.watch(
                      feedProvider.select(
                        (posts) =>
                            posts.firstWhere((p) => p.id == postId).comments,
                      ),
                    );

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
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(comment.userAvatar),
                          ),
                          title: Row(
                            children: [
                              Text(
                                comment.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
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
                    onPressed: () {
                      ref
                          .read(feedProvider.notifier)
                          .addComment(postId, commentController.text);
                      commentController.clear();
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
    final post = ref.watch(
      feedProvider.select((posts) => posts.firstWhere((p) => p.id == postId)),
    );

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
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(post.userAvatar),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
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
          ClipRRect(
            child: post.isLocalFile
                ? Image.file(
                    File(post.imageUrl),
                    width: double.infinity,
                    height: 260,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    post.imageUrl,
                    width: double.infinity,
                    height: 260,
                    fit: BoxFit.cover,
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
                    post.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    color: post.isLiked
                        ? const Color(0xFFFF1E40)
                        : const Color(0xFF888888),
                  ),
                  onPressed: () {
                    ref.read(feedProvider.notifier).toggleLike(post.id);
                  },
                ),
                Text(
                  '${post.likes}',
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
