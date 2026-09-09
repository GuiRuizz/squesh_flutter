import 'package:flutter/material.dart';
import '../app/theme/app_theme.dart';
import '../features/diet_path/domain/diet_node.dart';

class DietChecklistModal extends StatelessWidget {
  final DietNode dietNode;
  final Function(int index, bool value) onMealToggled;

  const DietChecklistModal({
    super.key,
    required this.dietNode,
    required this.onMealToggled,
  });

  // Mapeia o índice do item para a hora mínima necessária
  int _getRequiredHourForMeal(int index) {
    switch (index) {
      case 0:
        return 6; // Café da Manhã: 06h
      case 1:
        return 12; // Almoço: 12h
      case 2:
        return 15; // Café da Tarde: 15h
      case 3:
        return 20; // Jantar: 20h
      default:
        return 0;
    }
  }

  // Verifica se o horário atual libera o tick
  bool _isMealUnlocked(int index) {
    final currentHour = DateTime.now().hour;
    final requiredHour = _getRequiredHourForMeal(index);
    return currentHour >= requiredHour;
  }

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
                Text(
                  dietNode.dayTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const Icon(Icons.restaurant_menu, color: AppTheme.crimsonRed),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Consuma os alimentos indicados e marque as etapas:',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...List.generate(dietNode.meals.length, (index) {
              final meal = dietNode.meals[index];
              final isUnlocked = _isMealUnlocked(index);
              final requiredHour = _getRequiredHourForMeal(index);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? const Color(0xFF111111)
                      : const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: meal.isConsumed
                        ? AppTheme.crimsonRed
                        : (isUnlocked
                              ? const Color(0xFF2D2D2D)
                              : const Color(0xFF1F1F1F)),
                  ),
                ),
                child: CheckboxListTile(
                  activeColor: AppTheme.crimsonRed,
                  checkColor: Colors.black,
                  value: meal.isConsumed,
                  // Exibe o ícone de cadeado se estiver bloqueado por horário
                  secondary: !isUnlocked
                      ? Tooltip(
                          message: 'Liberado a partir das ${requiredHour}h',
                          child: const Icon(
                            Icons.lock_clock,
                            color: AppTheme.crimsonRed,
                          ),
                        )
                      : null,
                  title: Text(
                    meal.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? AppTheme.textMain
                          : AppTheme.textMuted,
                    ),
                  ),
                  subtitle: Text(
                    isUnlocked
                        ? meal.description
                        : 'Liberado às ${requiredHour.toString().padLeft(2, '0')}:00h • ${meal.description}',
                    style: TextStyle(
                      color: isUnlocked
                          ? AppTheme.textMuted
                          : const Color(0xFF555555),
                      fontSize: 12,
                    ),
                  ),
                  // Se não estiver liberado, impede a interação
                  onChanged: isUnlocked
                      ? (val) {
                          onMealToggled(index, val ?? false);
                        }
                      : null,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
