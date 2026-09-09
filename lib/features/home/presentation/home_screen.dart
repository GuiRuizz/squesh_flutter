import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../../widgets/diet_checklist_modal.dart';
import '../../../widgets/path_connector_painter.dart';
import '../../../widgets/path_node_widget.dart';
import '../../diet_path/daily_progress_controller.dart';
import '../../diet_path/domain/diet_node.dart';
import '../../workout_path/domain/workout_node.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fitnessState = ref.watch(fitnessProvider);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF141414), // Dark Glossy Header
              border: Border(bottom: BorderSide(color: Color(0xFF222222))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SQUESH',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppTheme.crimsonRed,
                  ),
                ),
                // Contador de Streak Diário
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: fitnessState.isTodayStreakAchieved
                        ? AppTheme.crimsonRed.withValues(alpha: 0.2)
                        : const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: fitnessState.isTodayStreakAchieved
                          ? AppTheme.crimsonRed
                          : const Color(0xFF333333),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: fitnessState.isTodayStreakAchieved
                            ? AppTheme.crimsonAccent
                            : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${fitnessState.streakCount} DIAS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: fitnessState.isTodayStreakAchieved
                              ? AppTheme.textMain
                              : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COLUNA 1: Trilha de Exercícios (Com Linhas Conectoras)
            Expanded(
              child: Column(
                children: [
                  const _ColumnHeader(
                    title: 'EXERCÍCIOS',
                    icon: Icons.fitness_center,
                  ),
                  const SizedBox(height: 30),
                  _WorkoutPathWidget(
                    nodes: fitnessState.workoutNodes,
                    onNodeTap: (node) {
                      ref
                          .read(fitnessProvider.notifier)
                          .completeWorkout(node.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppTheme.crimsonRed,
                          content: Text('Treino concluído! 🔥'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // COLUNA 2: Trilha de Alimentação (Com Linhas Conectoras)
            Expanded(
              child: Column(
                children: [
                  const _ColumnHeader(
                    title: 'ALIMENTAÇÃO',
                    icon: Icons.restaurant,
                  ),
                  const SizedBox(height: 30),
                  _DietPathWidget(
                    nodes: fitnessState.dietNodes,
                    onNodeTap: (node) {
                      _showDietModal(context, ref, node);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDietModal(BuildContext context, WidgetRef ref, DietNode node) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, refConsumer, _) {
            final currentDietNode = refConsumer
                .watch(fitnessProvider)
                .dietNodes
                .firstWhere((element) => element.id == node.id);

            return DietChecklistModal(
              dietNode: currentDietNode,
              onMealToggled: (mealIndex, isConsumed) {
                refConsumer
                    .read(fitnessProvider.notifier)
                    .toggleMeal(node.id, mealIndex, isConsumed);
              },
            );
          },
        );
      },
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ColumnHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.crimsonRed, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textMain,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutPathWidget extends StatelessWidget {
  final List<WorkoutNode> nodes;
  final Function(WorkoutNode node) onNodeTap;

  const _WorkoutPathWidget({required this.nodes, required this.onNodeTap});

  @override
  Widget build(BuildContext context) {
    final completedStates = nodes.map((n) => n.isCompleted).toList();

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: PathConnectorPainter(
              nodeCount: nodes.length,
              completedStates: completedStates,
            ),
          ),
        ),
        Column(
          children: List.generate(nodes.length, (index) {
            final node = nodes[index];
            final double alignX = (index % 2 == 0) ? -0.3 : 0.3;

            return Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Align(
                alignment: Alignment(alignX, 0),
                child: PathNodeWidget(
                  label: node.title,
                  icon: Icons.play_arrow_rounded,
                  isCompleted: node.isCompleted,
                  isLocked: node.isLocked,
                  onTap: () => onNodeTap(node),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DietPathWidget extends StatelessWidget {
  final List<DietNode> nodes;
  final Function(DietNode node) onNodeTap;

  const _DietPathWidget({required this.nodes, required this.onNodeTap});

  @override
  Widget build(BuildContext context) {
    final completedStates = nodes.map((n) => n.isCompleted).toList();

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: PathConnectorPainter(
              nodeCount: nodes.length,
              completedStates: completedStates,
            ),
          ),
        ),
        Column(
          children: List.generate(nodes.length, (index) {
            final node = nodes[index];
            final double alignX = (index % 2 == 0) ? -0.3 : 0.3;

            return Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Align(
                alignment: Alignment(alignX, 0),
                child: PathNodeWidget(
                  label: node.dayTitle,
                  icon: Icons.restaurant_menu,
                  isCompleted: node.isCompleted,
                  isLocked: node.isLocked,
                  onTap: () => onNodeTap(node),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
