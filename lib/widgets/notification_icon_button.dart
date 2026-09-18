import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:squesh_flutter/features/notification/domain/notifications_controller.dart';
import '../app/theme/app_theme.dart';

class NotificationIconButton extends ConsumerWidget {
  const NotificationIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Escuta o estado assíncrono das notificações
    final asyncNotifications = ref.watch(notificationProvider);

    // 2. Extrai a quantidade não lida de forma segura
    final unreadCount = asyncNotifications.maybeWhen(
      data: (list) => list.where((n) => !n.isRead).length,
      orElse: () => 0,
    );

    // 3. Formatação da label: '9+' para 10 ou mais
    final badgeText = unreadCount >= 10 ? '9+' : '$unreadCount';

    return Badge(
      isLabelVisible: unreadCount > 0,
      label: Text(
        badgeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppTheme.crimsonRed,
      offset: const Offset(-4, 4),
      child: IconButton(
        icon: const Icon(
          Icons.notifications_outlined,
          color: AppTheme.textMain,
          size: 24,
        ),
        onPressed: () {
          context.push('/notifications');
        },
      ),
    );
  }
}
