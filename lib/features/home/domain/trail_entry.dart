/// Uma etapa interna de um item da trilha:
///   - em NUTRIÇÃO, o item é um DIA e as etapas são as refeições (Café da Manhã,
///     Almoço...), cada uma liberada pelo próprio horário;
///   - em TREINO, o item é uma SESSÃO e as etapas são os exercícios.
class StepEntry {
  final String slot; // "cafe_manha" | "supino_reto"
  final String title; // "Café da Manhã" | "Supino Reto com Barra"
  final String description;
  final String value; // ex.: "4 séries de 10 a 12"
  final int requiredHour; // hora mínima para marcar (0 = sem trava de horário)
  final bool done; // o usuário já marcou esta etapa

  const StepEntry({
    required this.slot,
    required this.title,
    required this.description,
    required this.value,
    required this.requiredHour,
    required this.done,
  });

  /// Texto de apoio exibido no modal: junta a meta (value) e a descrição.
  String get subtitle {
    if (value.isEmpty) return description;
    if (description.isEmpty) return value;
    return '$value • $description';
  }

  factory StepEntry.fromJson(Map<String, dynamic> json) {
    return StepEntry(
      slot: json['slot'] as String? ?? '',
      title: json['title'] as String? ?? 'Etapa',
      description: json['description'] as String? ?? '',
      value: json['value'] as String? ?? '',
      requiredHour: (json['required_hour'] as num?)?.toInt() ?? 0,
      done: json['done'] as bool? ?? false,
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

  /// Etapas internas do item (refeições do dia / exercícios da sessão).
  /// Vazio em itens antigos, que são concluídos com um check só.
  final List<StepEntry> steps;

  const TrailItemEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.value,
    required this.order,
    required this.completed,
    this.steps = const [],
  });

  /// Quantas etapas internas já foram marcadas (ex.: "2/5 exercícios").
  int get stepsDone => steps.where((s) => s.done).length;

  factory TrailItemEntry.fromJson(Map<String, dynamic> json) {
    final stepsJson = json['steps'];
    return TrailItemEntry(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Etapa',
      description: json['description'] as String? ?? '',
      value: json['value'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      steps: [
        if (stepsJson is List)
          for (final s in stepsJson)
            if (s is Map) StepEntry.fromJson(Map<String, dynamic>.from(s)),
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