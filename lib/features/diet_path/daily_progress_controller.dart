import '../home/domain/trail_entry.dart';

/// Estado da Home alimentado pela API (GET /trails/me?type=...):
///
/// - `workoutTrails` / `dietTrails`: TODAS as trilhas do tipo, cada uma com
///   suas etapas (itens) e o progresso individual — a Home renderiza um
///   card/botão por trilha com as etapas dentro.
/// - `workoutDoneToday` / `nutritionDoneToday`: se o limite diário (1 por dia
///   por tipo) já foi atingido — trava as etapas restantes do tipo no app.
/// - `streakCount`: sequência de dias vinda de GET /users/me.
class FitnessState {
  final List<TrailEntry> workoutTrails;
  final List<TrailEntry> dietTrails;
  final bool workoutDoneToday;
  final bool nutritionDoneToday;
  final int streakCount;

  const FitnessState({
    this.workoutTrails = const [],
    this.dietTrails = const [],
    this.workoutDoneToday = false,
    this.nutritionDoneToday = false,
    this.streakCount = 0,
  });

  // Streak de hoje: os dois tipos (treino + alimentação) foram concluídos hoje.
  bool get isTodayStreakAchieved => workoutDoneToday && nutritionDoneToday;

  FitnessState copyWith({
    List<TrailEntry>? workoutTrails,
    List<TrailEntry>? dietTrails,
    bool? workoutDoneToday,
    bool? nutritionDoneToday,
    int? streakCount,
  }) {
    return FitnessState(
      workoutTrails: workoutTrails ?? this.workoutTrails,
      dietTrails: dietTrails ?? this.dietTrails,
      workoutDoneToday: workoutDoneToday ?? this.workoutDoneToday,
      nutritionDoneToday: nutritionDoneToday ?? this.nutritionDoneToday,
      streakCount: streakCount ?? this.streakCount,
    );
  }
}

// O legacy FitnessNotifier (mocks) foi removido — o estado agora vem 100% da
// API através do HomeNotifier em features/home/home_controller.dart.