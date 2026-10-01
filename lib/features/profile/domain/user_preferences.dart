/// Preferências de notificação do usuário logado.
///
/// Vem sempre com o padrão já aplicado pelo backend (o que nunca foi
/// configurado chega como `true`), então aqui é só um espelho do JSON.
class UserPreferences {
  final bool pushEnabled;
  final bool workoutReminders;
  final bool shopNews;
  final bool socialAlerts;

  const UserPreferences({
    this.pushEnabled = true,
    this.workoutReminders = true,
    this.shopNews = true,
    this.socialAlerts = true,
  });

  factory UserPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserPreferences();
    bool read(String key, bool fallback) {
      final value = json[key];
      return value is bool ? value : fallback;
    }

    return UserPreferences(
      pushEnabled: read('push_enabled', true),
      workoutReminders: read('workout_reminders', true),
      shopNews: read('shop_news', true),
      socialAlerts: read('social_alerts', true),
    );
  }

  /// Manda os quatro campos (o objeto inteiro já é o estado desejado).
  ///
  /// O backend faz atualização parcial e o Go é quem mescla com o que está no
  /// banco, então mandar o estado completo é seguro: o resultado é o mesmo.
  Map<String, dynamic> toPatch() => {
    'push_enabled': pushEnabled,
    'workout_reminders': workoutReminders,
    'shop_news': shopNews,
    'social_alerts': socialAlerts,
  };

  UserPreferences copyWith({
    bool? pushEnabled,
    bool? workoutReminders,
    bool? shopNews,
    bool? socialAlerts,
  }) => UserPreferences(
    pushEnabled: pushEnabled ?? this.pushEnabled,
    workoutReminders: workoutReminders ?? this.workoutReminders,
    shopNews: shopNews ?? this.shopNews,
    socialAlerts: socialAlerts ?? this.socialAlerts,
  );
}
