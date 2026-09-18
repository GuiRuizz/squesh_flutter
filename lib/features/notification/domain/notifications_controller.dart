import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'notification_model.dart';

// Notifier para gerenciar a lista de notificações
class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  NotificationNotifier() : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = const AsyncValue.loading();
    try {
      // TODO: Substituir pela chamada real HTTP / Repository
      await Future.delayed(const Duration(milliseconds: 600));
      final mockData = [
        NotificationModel(
          id: '1',
          userId: 'user-123',
          title: 'Item Comprado!',
          message: 'Você adquiriu o item Creatina Turbo na loja.',
          type: 'SHOP',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        NotificationModel(
          id: '2',
          userId: 'user-123',
          title: 'Novo Streak Alcançado!',
          message: 'Você completou 7 dias seguidos de treino 🔥',
          type: 'SYSTEM',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        NotificationModel(
          id: '3',
          userId: 'user-123',
          title: 'Treino Concluído',
          message: 'Seu treino de Peito e Tríceps foi registrado.',
          type: 'WORKOUT',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
      state = AsyncValue.data(mockData);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleReadStatus(String id) async {
    final currentList = state.value ?? [];
    state = AsyncValue.data(
      currentList.map((notif) {
        if (notif.id == id) {
          return notif.copyWith(isRead: !notif.isRead);
        }
        return notif;
      }).toList(),
    );

    // TODO: Chamar PATCH /api/v1/notifications/$id/read ou /unread no backend
  }

  Future<void> markAllAsRead() async {
    final currentList = state.value ?? [];
    state = AsyncValue.data(
      currentList.map((notif) => notif.copyWith(isRead: true)).toList(),
    );

    // TODO: Chamar PATCH /api/v1/notifications/read-all no backend
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>(
  (ref) => NotificationNotifier(),
);