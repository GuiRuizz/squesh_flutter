/// Modelos do feed social espelhando o JSON da API:
/// Post  -> { id, user_id, user, image_url, caption, comments[], created_at,
///           updated_at, likes_count, liked_by_me }
/// Comment -> { id, post_id, user_id, user, text, created_at }
library;

class SocialUser {
  final String id;
  final String name;
  final String avatarUrl;

  const SocialUser({
    required this.id,
    required this.name,
    this.avatarUrl = '',
  });

  factory SocialUser.fromJson(Map<String, dynamic> json) => SocialUser(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        avatarUrl: (json['avatar_url'] as String?) ?? '',
      );
}

class SocialComment {
  final String id;
  final String text;
  final DateTime createdAt;
  final SocialUser user;

  const SocialComment({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.user,
  });

  factory SocialComment.fromJson(Map<String, dynamic> json) => SocialComment(
        id: (json['id'] as String?) ?? '',
        text: (json['text'] as String?) ?? '',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        user: SocialUser.fromJson(
          Map<String, dynamic>.from((json['user'] as Map?) ?? const {}),
        ),
      );

  String get timeAgo => _timeAgo(createdAt);
}

class SocialPost {
  final String id;
  final String userId;
  final SocialUser user;
  final String imageUrl;
  final String caption;
  final DateTime createdAt;
  final int likesCount;
  final bool likedByMe;
  final List<SocialComment> comments;

  const SocialPost({
    required this.id,
    required this.userId,
    required this.user,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
    required this.likesCount,
    required this.likedByMe,
    required this.comments,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) => SocialPost(
        id: (json['id'] as String?) ?? '',
        userId: (json['user_id'] as String?) ?? '',
        user: SocialUser.fromJson(
          Map<String, dynamic>.from((json['user'] as Map?) ?? const {}),
        ),
        imageUrl: (json['image_url'] as String?) ?? '',
        caption: (json['caption'] as String?) ?? '',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
        likedByMe: (json['liked_by_me'] as bool?) ?? false,
        comments: [
          for (final c in (json['comments'] as List? ?? const []))
            SocialComment.fromJson(Map<String, dynamic>.from(c as Map)),
        ],
      );

  SocialPost copyWith({
    int? likesCount,
    bool? likedByMe,
    List<SocialComment>? comments,
  }) {
    return SocialPost(
      id: id,
      userId: userId,
      user: user,
      imageUrl: imageUrl,
      caption: caption,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      likedByMe: likedByMe ?? this.likedByMe,
      comments: comments ?? this.comments,
    );
  }

  String get timeAgo => _timeAgo(createdAt);
}

String _timeAgo(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'agora mesmo';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  if (diff.inDays < 7) return 'há ${diff.inDays} d';
  return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
}