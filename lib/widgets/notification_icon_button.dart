import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Importe seu controller de notificações do header/app
// Por exemplo: import '../controllers/notifications_controller.dart';

class NotificationIconButton extends ConsumerWidget {
  /// Quantidade opcional de notificações para exibir no badge.
  /// Se passado como `null`, ele pode consumir de um Provider do Riverpod.
  final int? unreadCount;

  /// Categoria ou filtro opcional para a tela de notificações, se necessário
  final String? initialCategory;

  const NotificationIconButton({
    super.key,
    this.unreadCount,
    this.initialCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Caso não passe o 'unreadCount' por parâmetro, você pode pegar direto do Provider:
    // final count = unreadCount ?? ref.watch(unreadNotificationsCountProvider);
    final count = unreadCount ?? 0;

    return GestureDetector(
      onTap: () {
        // Navega para a NotificationScreen via GoRouter
        if (initialCategory != null) {
          context.push('/notifications?category=$initialCategory');
        } else {
          context.push('/notifications');
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF262626), width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 24,
            ),
            if (count > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1E40),
                    shape: count > 9 ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: count > 9 ? BorderRadius.circular(8) : null,
                    border: Border.all(
                      color: const Color(0xFF141414),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
