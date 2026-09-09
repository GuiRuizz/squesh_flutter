class MealItem {
  final String title; // Ex: "Café da Manhã"
  final String
  description; // Ex: "3 ovos mexidos + 1 xícara de aveia + café preto"
  final bool isConsumed;

  const MealItem({
    required this.title,
    required this.description,
    this.isConsumed = false,
  });

  MealItem copyWith({bool? isConsumed}) {
    return MealItem(
      title: title,
      description: description,
      isConsumed: isConsumed ?? this.isConsumed,
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
