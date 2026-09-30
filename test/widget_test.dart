// Testes de unidade para o parsing dos modelos do feed social.
// (A UI e as chamadas HTTP não são exercitadas aqui — sem rede.)

import 'package:flutter_test/flutter_test.dart';

import 'package:squesh_flutter/features/social/domain/social_models.dart';

void main() {
  group('SocialPost.fromJson', () {
    test('mapeia um post completo vindo da API', () {
      final post = SocialPost.fromJson(const {
        'id': 'p1',
        'user_id': 'u1',
        'user': {'id': 'u1', 'name': 'Ana', 'avatar_url': ''},
        'image_url': 'http://localhost:8080/api/v1/files/posts/x.jpg',
        'caption': 'Treino de hoje!',
        'created_at': '2026-09-29T10:00:00Z',
        'likes_count': 3,
        'liked_by_me': true,
        'comments': [
          {
            'id': 'c1',
            'text': 'Mandou bem!',
            'created_at': '2026-09-29T10:05:00Z',
            'user': {'id': 'u2', 'name': 'Beto', 'avatar_url': ''},
          },
        ],
      });

      expect(post.id, 'p1');
      expect(post.likedByMe, isTrue);
      expect(post.likesCount, 3);
      expect(post.comments, hasLength(1));
      expect(post.comments.first.user.name, 'Beto');
      expect(post.timeAgo, isNotEmpty);
    });

    test('não quebra com JSON incompleto', () {
      final post = SocialPost.fromJson(const {});
      expect(post.id, '');
      expect(post.user.name, '');
      expect(post.likesCount, 0);
      expect(post.likedByMe, isFalse);
      expect(post.comments, isEmpty);
      expect(post.imageUrl, '');
    });

    test('copyWith altera apenas os campos pedidos', () {
      final post = SocialPost.fromJson(const {
        'id': 'p1',
        'user_id': 'u1',
        'user': {'id': 'u1', 'name': 'Ana'},
        'image_url': 'http://x.test/img.jpg',
        'caption': 'legenda',
        'created_at': '2026-09-29T10:00:00Z',
        'likes_count': 1,
        'liked_by_me': false,
        'comments': [],
      });

      final updated = post.copyWith(likedByMe: true, likesCount: 2);

      expect(updated.id, post.id);
      expect(updated.likedByMe, isTrue);
      expect(updated.likesCount, 2);
      expect(updated.caption, 'legenda');
      expect(updated.comments, isEmpty);
    });
  });
}