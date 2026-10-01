import 'user_preferences.dart';

/// Perfil do usuário logado — o que a tela de Configurações mostra e edita.
/// Espelha o `UserProfileResponseDTO` do Go.
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String role;
  final String avatarUrl;
  final String bio;
  final int streak;
  final int points;
  final UserPreferences preferences;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.avatarUrl = '',
    this.bio = '',
    this.streak = 0,
    this.points = 0,
    this.preferences = const UserPreferences(),
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: (json['id'] as String?) ?? '',
    name: (json['name'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    role: (json['role'] as String?) ?? 'user',
    avatarUrl: (json['avatar_url'] as String?) ?? '',
    bio: (json['bio'] as String?) ?? '',
    streak: (json['streak'] as num?)?.toInt() ?? 0,
    points: (json['points'] as num?)?.toInt() ?? 0,
    preferences: UserPreferences.fromJson(
      json['preferences'] is Map
          ? Map<String, dynamic>.from(json['preferences'] as Map)
          : null,
    ),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );

  bool get isAdmin => role == 'admin';

  /// Iniciais para o avatar quando não há foto.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return _firstLetter(parts.first);
    return '${_firstLetter(parts.first)}${_firstLetter(parts.last)}';
  }
}

String _firstLetter(String word) => word.substring(0, 1).toUpperCase();
