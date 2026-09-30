import 'package:flutter/material.dart';
import '../app/theme/app_theme.dart';

/// Modal de detalhe de uma etapa de TREINO — mesmo padrão visual do
/// DietChecklistModal: mostra o conteúdo da etapa e a ação de concluir.
class WorkoutDetailModal extends StatelessWidget {
  final String title;
  final String description;
  final String value;
  final bool isCompleted;
  final bool dailyLimitReached;
  final Future<void> Function() onComplete;

  const WorkoutDetailModal({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.isCompleted,
    required this.dailyLimitReached,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppTheme.crimsonRed, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                    ),
                  ),
                ),
                const Icon(Icons.fitness_center, color: AppTheme.crimsonRed),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Execute o treino abaixo e conclua a etapa:',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            // Card com a meta/valor do treino
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2D2D2D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (value.isNotEmpty) ...[
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.crimsonAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    description.isEmpty ? 'Sem descrição adicional.' : description,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (isCompleted)
              _StatusChip(
                icon: Icons.check_circle_rounded,
                label: 'Etapa já concluída!',
                color: AppTheme.crimsonAccent,
              )
            else if (dailyLimitReached)
              const _StatusChip(
                icon: Icons.lock_clock,
                label: 'Limite diário: 1 treino por dia. Volte amanhã!',
                color: AppTheme.textMuted,
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.crimsonRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onComplete,
                  child: const Text(
                    'Concluir treino',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}