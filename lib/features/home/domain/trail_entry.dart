/// Uma refeição dentro de um DIA de alimentação.
///
/// Em trilhas de NUTRIÇÃO cada item da trilha é um dia e traz a lista das
/// refeições desse dia, cada uma com a hora em que é liberada no App.
class MealEntry {
  final String slot; // "cafe_manha" | "almoco" | "cafe_tarde" | "jantar"
  final String title; // "Café da Manhã"
  final String description; // "3 ovos mexidos + café sem açúcar"
  final String value;
  final int requiredHour; // hora mínima para marcar (6, 12, 15, 20)
  final bool consumed; // o usuário já marcou esta refeição

  const MealEntry({
    required this.slot,
    required this.title,
    required this.description,
    required this.value,
    required this.requiredHour,
    required this.consumed,
  });

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      slot: json['slot'] as String? ?? '',
      title: json['title'] as String? ?? 'Refeição',
      description: json['description'] as String? ?? '',
      value: json['value'] as String? ?? '',
      requiredHour: (json['required_hour'] as num?)?.toInt() ?? 0,
      consumed: json['consumed'] as bool? ?? false,
    );
  }
}

/// Etapa/item de uma trilha como retornado por GET /trails/me.
///
/// O backend já preenche a flag `completed` com o progresso do usuário,
/// então o App renderiza o check sem precisar de outra chamada.
class TrailItemEntry {
  final String id;
  final String title;
  final String description;
  final String value;
  final int order;
  final bool completed;

  /// Refeições do dia (vazio em itens de TREINO, que não têm refeições).
  final List<MealEntry> meals;

  const TrailItemEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.value,
    required this.order,
    required this.completed,
    this.meals = const [],
  });

  /// Quantas refeições do dia já foram marcadas.
  int get mealsDone => meals.where((m) => m.consumed).length;

  /// O dia só está completo quando todas as refeições foram marcadas.
  bool get isDayComplete => meals.isNotEmpty && mealsDone == meals.length;

  factory TrailItemEntry.fromJson(Map<String, dynamic> json) {
    final mealsJson = json['meals'];
    return TrailItemEntry(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Etapa',
      description: json['description'] as String? ?? '',
      value: json['value'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      meals: [
        if (mealsJson is List)
          for (final m in mealsJson)
            if (m is Map) MealEntry.fromJson(Map<String, dynamic>.from(m)),
      ],
    );
  }
}

/// Uma trilha com o resumo do progresso do usuário nela.
///
/// Cada elemento do array `trails` retornado por GET /trails/me tem a forma
/// `{ "trail": {...}, "progress": { completed_items, total_items, percent } }`.
class TrailEntry {
  final String id;
  final String title;
  final String description;
  final String level;
  final String type;
  final List<TrailItemEntry> items;
  final int completedItems;
  final int totalItems;
  final int percent;

  const TrailEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.type,
    required this.items,
    required this.completedItems,
    required this.totalItems,
    required this.percent,
  });

  bool get isFullyCompleted => totalItems > 0 && completedItems >= totalItems;

  factory TrailEntry.fromJson(
    Map<String, dynamic> trailJson,
    Map<String, dynamic> progressJson,
  ) {
    final itemsJson = trailJson['items'];
    return TrailEntry(
      id: trailJson['id'] as String,
      title: trailJson['title'] as String? ?? 'Trilha',
      description: trailJson['description'] as String? ?? '',
      level: trailJson['level'] as String? ?? '',
      type: trailJson['type'] as String? ?? '',
      items: [
        if (itemsJson is List)
          for (final it in itemsJson)
            if (it is Map) TrailItemEntry.fromJson(Map<String, dynamic>.from(it)),
      ],
      completedItems: progressJson['completed_items'] as int? ?? 0,
      totalItems: progressJson['total_items'] as int? ?? 0,
      percent: progressJson['percent'] as int? ?? 0,
    );
  }
}