import 'package:flutter/material.dart';
import '../app/theme/app_theme.dart';
import '../features/diet_path/domain/diet_node.dart';

/// Modal do cardápio de UM DIA de alimentação.
///
/// Mostra todas as refeições do dia e libera cada uma pelo horário
/// (Café da Manhã 6h, Almoço 12h, Café da Tarde 15h, Jantar 20h).
/// O check é otimista: marca na hora e desfaz se a API recusar.
class DietChecklistModal extends StatefulWidget {
  final DietNode dietNode;
  final Function(int index, bool value) onMealToggled;

  const DietChecklistModal({
    super.key,
    required this.dietNode,
    required this.onMealToggled,
  });

  @override
  State<DietChecklistModal> createState() => _DietChecklistModalState();
}

class _DietChecklistModalState extends State<DietChecklistModal> {
  late List<MealItem> _meals;
  final Set<int> _saving = {};

  @override
  void initState() {
    super.initState();
    _meals = List.of(widget.dietNode.meals);
  }

  // Mapeia o índice do item para a hora mínima necessária.
  // Usado só como fallback quando a refeição não traz `required_hour`.
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
  bool _isMealUnlocked(int requiredHour) {
    return DateTime.now().hour >= requiredHour;
  }

  Future<void> _toggle(int index, bool value) async {
    if (_saving.contains(index)) return;

    final previous = _meals[index];
    setState(() {
      _saving.add(index);
      _meals[index] = previous.copyWith(isConsumed: value);
    });

    try {
      await widget.onMealToggled(index, value);
    } catch (_) {
      // A Home já mostra o erro (SnackBar); aqui só desfaz o check otimista.
      if (mounted) {
        setState(() => _meals[index] = previous);
      }
    } finally {
      if (mounted) {
        setState(() => _saving.remove(index));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _meals.length;
    final done = _meals.where((m) => m.isConsumed).length;
    final isDayComplete = total > 0 && done >= total;

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
                  widget.dietNode.dayTitle,
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
            Text(
              isDayComplete
                  ? 'Dia completo! Todas as refeições foram marcadas.'
                  : 'Consuma os alimentos indicados e marque as etapas '
                      '($done de $total marcadas).',
              style: TextStyle(
                color: isDayComplete ? AppTheme.crimsonRed : AppTheme.textMuted,
                fontSize: 13,
                fontWeight: isDayComplete
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _meals.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final meal = _meals[index];
                  // A hora de liberação vem da própria refeição (dado do dia);
                  // cai no padrão por índice só se o backend não informar.
                  final requiredHour =
                      meal.requiredHour ?? _getRequiredHourForMeal(index);
                  final isUnlocked = _isMealUnlocked(requiredHour);
                  final isSaving = _saving.contains(index);

                  return Container(
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
                              message:
                                  'Liberado a partir das ${requiredHour}h',
                              child: const Icon(
                                Icons.lock_clock,
                                color: AppTheme.crimsonRed,
                              ),
                            )
                          : (isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.crimsonRed,
                                    ),
                                  )
                                : null),
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
                      onChanged: (isUnlocked && !isSaving)
                          ? (val) => _toggle(index, val ?? false)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
