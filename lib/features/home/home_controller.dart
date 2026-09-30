import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../diet_path/daily_progress_controller.dart';
import '../diet_path/data/trails_api_service.dart';
import '../profile/data/user_api_service.dart';
import 'domain/trail_entry.dart';

/// Estado da Home alimentado pela API:
/// - GET /trails/me?type=workout   -> coluna EXERCÍCIOS (cards por trilha)
/// - GET /trails/me?type=nutrition -> coluna ALIMENTAÇÃO (cards por trilha)
/// - GET /users/me                 -> streak do cabeçalho
///
/// Cada item da trilha já vem com a flag `completed`, e o payload traz
/// `today_completed` para a Home travar o limite diário (1 por dia por tipo).
final homeProvider =
    AsyncNotifierProvider<HomeNotifier, FitnessState>(HomeNotifier.new);

class HomeNotifier extends AsyncNotifier<FitnessState> {
  @override
  Future<FitnessState> build() async {
    return _load();
  }

  Future<FitnessState> _load() async {
    final trails = ref.read(trailsApiServiceProvider);
    final user = ref.read(userApiServiceProvider);

    final results = await Future.wait([
      trails.getMyTrails('workout'),
      trails.getMyTrails('nutrition'),
      user.getProfile(),
    ]);

    return FitnessState(
      workoutTrails: _parseTrails(results[0].data),
      dietTrails: _parseTrails(results[1].data),
      workoutDoneToday: _todayDone(results[0].data, 'workout'),
      nutritionDoneToday: _todayDone(results[1].data, 'nutrition'),
      streakCount: ((results[2].data as Map)['streak'] as num?)?.toInt() ?? 0,
    );
  }

  /// Recarrega sem emitir loading (evita piscar a tela).
  Future<void> reload() async {
    try {
      state = AsyncData(await _load());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Conclui um item de treino (POST /trails/items/:id/complete).
  Future<void> completeWorkout(String itemId) async {
    await ref.read(trailsApiServiceProvider).completeTrailItem(itemId);
    await reload();
  }

  /// Marca/desmarca uma refeição do dia (PATCH /trails/items/:id/meals).
  ///
  /// [mealIndex] é a posição da refeição dentro do dia; as demais do mesmo dia
  /// continuam liberadas (o limite de 1/dia vale para trocar de DIA).
  Future<void> toggleMeal(
    String itemId, {
    required int mealIndex,
    required bool checked,
  }) async {
    await ref
        .read(trailsApiServiceProvider)
        .toggleMealCheck(itemId, mealIndex: mealIndex, checked: checked);
    await reload();
  }

  /// Extrai a lista de trilhas de { trails: [{ trail, progress }] }.
  List<TrailEntry> _parseTrails(dynamic data) {
    if (data is! Map) return const [];
    final list = data['trails'];
    if (list is! List) return const [];
    return [
      for (final entry in list)
        if (entry is Map) _parseTrailEntry(Map<String, dynamic>.from(entry)),
    ];
  }

  TrailEntry _parseTrailEntry(Map<String, dynamic> entry) {
    final trail = entry['trail'];
    final progress = entry['progress'];
    if (trail is! Map || progress is! Map) {
      return const TrailEntry(
        id: '',
        title: '',
        description: '',
        level: '',
        type: '',
        items: [],
        completedItems: 0,
        totalItems: 0,
        percent: 0,
      );
    }
    return TrailEntry.fromJson(
      Map<String, dynamic>.from(trail),
      Map<String, dynamic>.from(progress),
    );
  }

  /// Lê { today_completed: { workout: bool, nutrition: bool } }.
  bool _todayDone(dynamic data, String type) {
    if (data is! Map) return false;
    final today = data['today_completed'];
    if (today is! Map) return false;
    return today[type] as bool? ?? false;
  }
}