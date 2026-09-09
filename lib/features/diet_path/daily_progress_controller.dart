import 'package:flutter_riverpod/legacy.dart';
import 'package:squesh_flutter/features/workout_path/domain/workout_node.dart';
import 'domain/diet_node.dart';

class FitnessState {
  final List<WorkoutNode> workoutNodes;
  final List<DietNode> dietNodes;
  final int streakCount;

  const FitnessState({
    required this.workoutNodes,
    required this.dietNodes,
    this.streakCount = 0,
  });

  // O streak de hoje é atingido se o primeiro nó (ativo) de treino E alimentação forem concluídos
  bool get isTodayStreakAchieved {
    final todayWorkout =
        workoutNodes.isNotEmpty && workoutNodes.first.isCompleted;
    final todayDiet = dietNodes.isNotEmpty && dietNodes.first.isCompleted;
    return todayWorkout && todayDiet;
  }

  FitnessState copyWith({
    List<WorkoutNode>? workoutNodes,
    List<DietNode>? dietNodes,
    int? streakCount,
  }) {
    return FitnessState(
      workoutNodes: workoutNodes ?? this.workoutNodes,
      dietNodes: dietNodes ?? this.dietNodes,
      streakCount: streakCount ?? this.streakCount,
    );
  }
}

class FitnessNotifier extends StateNotifier<FitnessState> {
  FitnessNotifier()
    : super(
        FitnessState(
          workoutNodes: const [
            WorkoutNode(
              id: 'w1',
              title: 'Dia 1: Mobilidade',
              videoUrl: 'https://youtube.com/...',
              isCompleted: false,
              isLocked: false,
            ),
            WorkoutNode(
              id: 'w2',
              title: 'Dia 2: Hipertrofia A',
              videoUrl: 'https://youtube.com/...',
              isCompleted: false,
              isLocked: true,
            ),
          ],
          dietNodes: const [
            DietNode(
              id: 'd1',
              dayTitle: 'Dia 1: Reeducação',
              isLocked: false,
              meals: [
                MealItem(
                  title: 'Café da Manhã',
                  description:
                      '3 ovos mexidos + 1 xícara de aveia + café preto',
                ),
                MealItem(
                  title: 'Almoço',
                  description:
                      '150g de frango grelhado + 100g de arroz integral + salada',
                ),
                MealItem(
                  title: 'Café da Tarde',
                  description: '1 scoop de Whey ou 30g de castanhas + 1 maçã',
                ),
                MealItem(
                  title: 'Jantar',
                  description: '150g de patinho moído + legumes no vapor',
                ),
              ],
            ),
            DietNode(
              id: 'd2',
              dayTitle: 'Dia 2: Low Carb',
              isLocked: true,
              meals: [
                MealItem(
                  title: 'Café da Manhã',
                  description: 'Omelete de 3 ovos com espinafre e queijo minas',
                ),
                MealItem(
                  title: 'Almoço',
                  description: '200g de peixe assado + salada verde à vontade',
                ),
                MealItem(
                  title: 'Café da Tarde',
                  description: 'Iogurte natural sem açúcar + sementes de chia',
                ),
                MealItem(
                  title: 'Jantar',
                  description: 'Sopa de legumes com frango desfiado',
                ),
              ],
            ),
          ],
        ),
      );

  // Marcar/Desmarcar refeição no nó específico
  void toggleMeal(String dietNodeId, int mealIndex, bool isConsumed) {
    final updatedDietNodes = state.dietNodes.map((node) {
      if (node.id == dietNodeId) {
        final updatedMeals = List<MealItem>.from(node.meals);
        updatedMeals[mealIndex] = updatedMeals[mealIndex].copyWith(
          isConsumed: isConsumed,
        );
        return DietNode(
          id: node.id,
          dayTitle: node.dayTitle,
          isLocked: node.isLocked,
          meals: updatedMeals,
        );
      }
      return node;
    }).toList();

    state = state.copyWith(dietNodes: updatedDietNodes);
    _checkStreak();
  }

  // Marcar treino como concluído
  void completeWorkout(String workoutNodeId) {
    final updatedWorkoutNodes = state.workoutNodes.map((node) {
      if (node.id == workoutNodeId) {
        return node.copyWith(isCompleted: true);
      }
      return node;
    }).toList();

    state = state.copyWith(workoutNodes: updatedWorkoutNodes);
    _checkStreak();
  }

  void _checkStreak() {
    if (state.isTodayStreakAchieved && state.streakCount == 0) {
      state = state.copyWith(streakCount: state.streakCount + 1);
    }
  }
}

final fitnessProvider = StateNotifierProvider<FitnessNotifier, FitnessState>((
  ref,
) {
  return FitnessNotifier();
});
