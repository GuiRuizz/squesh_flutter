import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:squesh_flutter/features/notification/domain/notifications_controller.dart';

class MainNavigationShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({super.key, required this.navigationShell});

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    // 1. Limpa a notificação da aba assim que o usuário clica nela
    ref.read(bottomNavNotificationsProvider.notifier).clearNotification(index);

    // 2. Navega para a aba correspondente no GoRouter
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuta o estado reativo das notificações
    final notifications = ref.watch(bottomNavNotificationsProvider);

    return SafeArea(
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: Container(
          height: 75,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            border: Border(top: BorderSide(color: Color(0xFF262626), width: 2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _IconNavItem(
                icon: Icons.home_rounded,
                color: const Color(0xFFFF1E40),
                isSelected: navigationShell.currentIndex == 0,
                hasNotification: notifications[0] ?? false,
                onTap: () => _onTap(context, ref, 0),
              ),
              _IconNavItem(
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFFFFC107),
                isSelected: navigationShell.currentIndex == 1,
                hasNotification: notifications[1] ?? false,
                onTap: () => _onTap(context, ref, 1),
              ),
              _IconNavItem(
                icon: Icons.camera_alt_rounded,
                color: const Color(0xFF00E5FF),
                isSelected: navigationShell.currentIndex == 2,
                hasNotification: notifications[2] ?? false,
                onTap: () => _onTap(context, ref, 2),
              ),
              _IconNavItem(
                icon: Icons.shopping_bag_rounded,
                color: const Color(0xFFA855F7),
                isSelected: navigationShell.currentIndex == 3,
                hasNotification: notifications[3] ?? false,
                onTap: () => _onTap(context, ref, 3),
              ),
              _IconNavItem(
                icon: Icons.settings_rounded,
                color: const Color(0xFF9CA3AF),
                isSelected: navigationShell.currentIndex == 4,
                hasNotification: notifications[4] ?? false,
                onTap: () => _onTap(context, ref, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconNavItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool hasNotification;
  final VoidCallback onTap;

  const _IconNavItem({
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.hasNotification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            if (hasNotification)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1E40),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF141414),
                      width: 2,
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
