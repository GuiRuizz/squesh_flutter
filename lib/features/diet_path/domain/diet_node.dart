class MealItem {
  final String title; // Ex: "Café da Manhã"
  final String
  description; // Ex: "3 ovos mexidos + 1 xícara de aveia + café preto"
  final bool isConsumed;

  /// Hora mínima para liberar a marcação (vem do backend: 6, 12, 15, 20).
  /// Quando nulo, o modal usa a ordem padrão dos slots.
  final int? requiredHour;

  const MealItem({
    required this.title,
    required this.description,
    this.isConsumed = false,
    this.requiredHour,
  });

  MealItem copyWith({bool? isConsumed}) {
    return MealItem(
      title: title,
      description: description,
      isConsumed: isConsumed ?? this.isConsumed,
      requiredHour: requiredHour,
    );
  }
}

class DietNode {
  final String id;
  final String dayTitle; // Ex: "Dia 1 - Moderação"
  final List<MealItem> meals;
  final bool isLocked;

  const DietNode({
    required this.id,
    required this.dayTitle,
    required this.meals,
    this.isLocked = false,
  });

  bool get isCompleted => meals.isNotEmpty && meals.every((m) => m.isConsumed);
}
