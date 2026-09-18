import 'package:flutter_riverpod/legacy.dart';

// Notifier que gerencia as notificações das abas (index -> possuiNotificacao)
class BottomNavNotificationsNotifier extends StateNotifier<Map<int, bool>> {
  BottomNavNotificationsNotifier()
    : super({
        0: false, // Início
        1: false, // Ranking
        2: true, // Fotos (exemplo iniciado com notificação)
        3: false, // Loja
        4: false, // Configurações
      });

  /// Ativa a notificação em uma aba específica
  void showNotification(int tabIndex) {
    state = {...state, tabIndex: true};
  }

  /// Limpa/remove a notificação da aba ao clicar/visitar
  void clearNotification(int tabIndex) {
    if (state[tabIndex] == true) {
      state = {...state, tabIndex: false};
    }
  }

  /// Alterna o estado de notificação (toggle)
  void toggleNotification(int tabIndex) {
    state = {...state, tabIndex: !(state[tabIndex] ?? false)};
  }
}

// Provider global acessível em todo o app
final bottomNavNotificationsProvider =
    StateNotifierProvider<BottomNavNotificationsNotifier, Map<int, bool>>((
      ref,
    ) {
      return BottomNavNotificationsNotifier();
    });
