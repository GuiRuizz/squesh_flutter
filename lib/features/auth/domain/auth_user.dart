// Usuário autenticado, usado pelo AuthController e pelas telas que precisam
// saber quem é o dono da sessão (ex.: publicar post, apagar comentário).
import '../../profile/domain/user_profile.dart';

class AuthUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String avatarUrl;
  final int streak;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.avatarUrl = '',
    this.streak = 0,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
        role: (json['role'] as String?) ?? 'user',
        avatarUrl: (json['avatar_url'] as String?) ?? '',
        streak: (json['streak'] as num?)?.toInt() ?? 0,
      );

  /// O perfil do `GET /users/me` é a mesma coisa com alguns campos a mais
  /// (bio, pontos, preferências), então a sessão se monta direto dele.
  factory AuthUser.fromProfile(UserProfile profile) => AuthUser(
        id: profile.id,
        name: profile.name,
        email: profile.email,
        role: profile.role,
        avatarUrl: profile.avatarUrl,
        streak: profile.streak,
      );
}