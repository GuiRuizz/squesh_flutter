import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squesh_flutter/features/notification/domain/notifications_controller.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/notification_model.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF141414), // Dark Glossy Header
              border: Border(bottom: BorderSide(color: Color(0xFF222222))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AppTheme.textMain,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'NOTIFICAÇÕES',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
                // Botão "Marcar todas como lidas"
                IconButton(
                  tooltip: 'Marcar todas como lidas',
                  icon: const Icon(
                    Icons.done_all_rounded,
                    color: AppTheme.crimsonRed,
                    size: 24,
                  ),
                  onPressed: () {
                    ref.read(notificationProvider.notifier).markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Color(0xFF222222),
                        content: Text(
                          'Todas as notificações foram lidas!',
                          style: TextStyle(color: AppTheme.textMain),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: notificationsState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.crimsonRed),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Erro ao carregar notificações',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const _EmptyNotificationState();
          }

          return RefreshIndicator(
            color: AppTheme.crimsonRed,
            backgroundColor: const Color(0xFF141414),
            onRefresh: () =>
                ref.read(notificationProvider.notifier).fetchNotifications(),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onTap: () {
                    ref
                        .read(notificationProvider.notifier)
                        .toggleReadStatus(notification.id);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'SHOP':
        return Icons.shopping_bag_outlined;
      case 'WORKOUT':
        return Icons.fitness_center;
      case 'POST':
        return Icons.chat_bubble_outline;
      case 'SYSTEM':
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return 'há ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'há ${diff.inHours}h';
    } else {
      return 'há ${diff.inDays}d';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFF1C1415) : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread
                ? AppTheme.crimsonRed.withValues(alpha: 0.5)
                : const Color(0xFF2C2C2C),
            width: isUnread ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone do Tipo de Notificação
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUnread
                    ? AppTheme.crimsonRed.withValues(alpha: 0.2)
                    : const Color(0xFF222222),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForType(notification.type),
                color: isUnread ? AppTheme.crimsonRed : AppTheme.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: AppTheme.textMain,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Indicador Ponto Vermelho para Não Lidos
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.crimsonRed,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF161616),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma notificação por aqui',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Avisaremos você assim que houver novidades.',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
