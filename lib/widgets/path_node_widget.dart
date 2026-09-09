import 'package:flutter/material.dart';

import '../app/theme/app_theme.dart';

class PathNodeWidget extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isCompleted;
  final bool isLocked;
  final VoidCallback onTap;

  const PathNodeWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.isCompleted,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: isLocked ? null : onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Efeito Black Piano com gradiente
              gradient: isCompleted
                  ? const LinearGradient(
                      colors: [AppTheme.crimsonAccent, AppTheme.crimsonRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF2C2C2C), Color(0xFF141414)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: Border.all(
                color: isCompleted
                    ? AppTheme.crimsonAccent
                    : (isLocked
                          ? const Color(0xFF333333)
                          : AppTheme.crimsonRed),
                width: 2.5,
              ),
              boxShadow: [
                if (!isLocked)
                  BoxShadow(
                    color: AppTheme.crimsonRed.withValues(
                      alpha: isCompleted ? 0.6 : 0.25,
                    ),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Icon(
              isCompleted ? Icons.check : (isLocked ? Icons.lock : icon),
              color: isLocked ? Colors.white24 : Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isLocked ? AppTheme.textMuted : AppTheme.textMain,
          ),
        ),
      ],
    );
  }
}
