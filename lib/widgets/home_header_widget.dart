import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';
import '../features/diet_path/daily_progress_controller.dart';
import 'notification_icon_button.dart';

class HomeHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  const HomeHeaderWidget({super.key, required this.fitnessState});

  final FitnessState fitnessState;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFF141414), // Dark Glossy Header
          border: Border(bottom: BorderSide(color: Color(0xFF222222))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SQUESH',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppTheme.crimsonRed,
              ),
            ),
            Row(
              children: [
                // Contador de Streak Diário
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: fitnessState.isTodayStreakAchieved
                        ? AppTheme.crimsonRed.withValues(alpha: 0.2)
                        : const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: fitnessState.isTodayStreakAchieved
                          ? AppTheme.crimsonRed
                          : const Color(0xFF333333),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: fitnessState.isTodayStreakAchieved
                            ? AppTheme.crimsonAccent
                            : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${fitnessState.streakCount} DIAS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: fitnessState.isTodayStreakAchieved
                              ? AppTheme.textMain
                              : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Botão Reutilizável de Notificação
                const NotificationIconButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
