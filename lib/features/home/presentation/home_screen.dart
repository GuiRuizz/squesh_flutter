import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squesh_flutter/widgets/home_header_widget.dart';
import '../../../app/theme/app_theme.dart';
import '../../../widgets/path_connector_painter.dart';
import '../../../widgets/path_node_widget.dart';
import '../../../widgets/trail_detail_modal.dart';
import '../../diet_path/daily_progress_controller.dart';
import '../domain/trail_entry.dart';
import '../home_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _errorMessage(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] is String) {
        return data['error'] as String;
      }
      return 'Não foi possível conectar ao servidor.';
    }
    return fallback;
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.crimsonRed,
        content: Text(message),
      ),
    );
  }

  /// Abre o modal de detalhe de uma ETAPA da trilha: uma SESSÃO de treino
  /// (com os exercícios) ou um DIA de alimentação (com as refeições liberadas
  /// pelo horário). Mesma mecânica nos dois tipos.
  Future<void> _openTrailDetail(
    BuildContext context,
    WidgetRef ref,
    TrailItemEntry item,
    String kind,
  ) async {
    final isNutrition = kind == 'nutrition';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TrailDetailModal(
          item: item,
          icon: isNutrition ? Icons.restaurant_menu : Icons.fitness_center,
          stepLabel: isNutrition ? 'o dia' : 'o treino',
          hint: isNutrition
              ? 'Consuma os alimentos e marque as refeições'
              : 'Execute os exercícios e marque conforme for fazendo',
          completeMessage: isNutrition
              ? 'Dia completo! Todas as refeições foram marcadas.'
              : 'Sessão completa! Todos os exercícios foram marcados.',
          onStepToggled: (stepIndex, isChecked) async {
            try {
              await ref
                  .read(homeProvider.notifier)
                  .toggleStep(
                    item.id,
                    stepIndex: stepIndex,
                    checked: isChecked,
                  );
            } catch (e) {
              if (context.mounted) {
                _showSnack(
                  context,
                  _errorMessage(e, 'Não foi possível marcar.'),
                );
              }
              rethrow;
            }
          },
          onComplete: () async {
            try {
              await ref.read(homeProvider.notifier).completeWorkout(item.id);
              if (context.mounted) {
                Navigator.pop(context);
                _showSnack(context, 'Treino concluído! 🔥');
              }
            } catch (e) {
              if (context.mounted) {
                _showSnack(
                  context,
                  _errorMessage(e, 'Não foi possível concluir o treino.'),
                );
              }
              rethrow;
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fitnessAsync = ref.watch(homeProvider);
    final fitnessState = fitnessAsync.value ?? const FitnessState();

    return Scaffold(
      appBar: HomeHeaderWidget(fitnessState: fitnessState),
      body: fitnessAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.crimsonRed),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: Color(0xFF555555),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Não foi possível carregar suas trilhas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF888888)),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.crimsonRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.crimsonRed,
                  ),
                  label: const Text(
                    'Tentar novamente',
                    style: TextStyle(
                      color: AppTheme.crimsonRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => ref.read(homeProvider.notifier).reload(),
                ),
              ],
            ),
          ),
        ),
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // COLUNA 1: Trilhas de Exercícios (um card/botão por trilha)
              Expanded(
                child: _TrailColumn(
                  title: 'EXERCÍCIOS',
                  icon: Icons.fitness_center,
                  kind: 'workout',
                  trails: fitnessState.workoutTrails,
                  doneToday: fitnessState.workoutDoneToday,
                  emptyMessage: 'Nenhum treino disponível.\nGere uma trilha!',
                  onStepTap: (item) =>
                      _openTrailDetail(context, ref, item, 'workout'),
                ),
              ),

              const SizedBox(width: 16),

              // COLUNA 2: Trilhas de Alimentação (um card/botão por trilha)
              Expanded(
                child: _TrailColumn(
                  title: 'ALIMENTAÇÃO',
                  icon: Icons.restaurant,
                  kind: 'nutrition',
                  trails: fitnessState.dietTrails,
                  doneToday: fitnessState.nutritionDoneToday,
                  emptyMessage: 'Nenhum plano alimentar disponível.',
                  onStepTap: (item) =>
                      _openTrailDetail(context, ref, item, 'nutrition'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coluna de um tipo: cabeçalho + banner do limite diário + cards de trilhas.
class _TrailColumn extends StatelessWidget {
  final String title;
  final IconData icon;
  final String kind; // "workout" | "nutrition"
  final List<TrailEntry> trails;
  final bool doneToday;
  final String emptyMessage;
  final void Function(TrailItemEntry item) onStepTap;

  const _TrailColumn({
    required this.title,
    required this.icon,
    required this.kind,
    required this.trails,
    required this.doneToday,
    required this.emptyMessage,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ColumnHeader(title: title, icon: icon),
        const SizedBox(height: 14),
        if (doneToday) ...[
          _DailyLimitBanner(kind: kind),
          const SizedBox(height: 10),
        ],
        if (trails.isEmpty)
          _EmptyColumnMessage(message: emptyMessage)
        else
          for (final trail in trails)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TrailCard(
                trail: trail,
                typeIcon: icon,
                doneToday: doneToday,
                onStepTap: onStepTap,
              ),
            ),
      ],
    );
  }
}

/// Card/botão de UMA trilha. As etapas ficam dentro (acordeão).
class _TrailCard extends StatefulWidget {
  final TrailEntry trail;
  final IconData typeIcon;
  final bool doneToday;
  final void Function(TrailItemEntry item) onStepTap;

  const _TrailCard({
    required this.trail,
    required this.typeIcon,
    required this.doneToday,
    required this.onStepTap,
  });

  @override
  State<_TrailCard> createState() => _TrailCardState();
}

class _TrailCardState extends State<_TrailCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final trail = widget.trail;
    final isDone = trail.isFullyCompleted;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? AppTheme.crimsonAccent : const Color(0xFF2C2C2C),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(widget.typeIcon, color: AppTheme.crimsonRed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trail.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMain,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trail.level.isEmpty
                              ? '${trail.completedItems}/${trail.totalItems} etapas'
                              : '${trail.level} • ${trail.completedItems}/${trail.totalItems}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isDone)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.crimsonAccent,
                      size: 20,
                    )
                  else
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textMuted,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
          // Barra de progresso da trilha
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: trail.totalItems == 0 ? 0 : trail.percent / 100,
                minHeight: 4,
                backgroundColor: const Color(0xFF232323),
                valueColor: const AlwaysStoppedAnimation(AppTheme.crimsonRed),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Etapas DENTRO do card (visíveis ao expandir)
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TrailSteps(
                items: trail.items,
                typeIcon: widget.typeIcon,
                doneToday: widget.doneToday,
                onStepTap: widget.onStepTap,
              ),
            ),
        ],
      ),
    );
  }
}

/// Caminho de etapas (Duolingo) renderizado dentro do card expandido.
class _TrailSteps extends StatelessWidget {
  final List<TrailItemEntry> items;
  final IconData typeIcon;
  final bool doneToday;
  final void Function(TrailItemEntry item) onStepTap;

  const _TrailSteps({
    required this.items,
    required this.typeIcon,
    required this.doneToday,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final completedStates = items.map((e) => e.completed).toList();

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: PathConnectorPainter(
              nodeCount: items.length,
              completedStates: completedStates,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                _buildStep(context, items[i], i),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(BuildContext context, TrailItemEntry item, int index) {
    final previousDone = index == 0 ||
        (items[index - 1].completed == true);
    final lockedByDailyLimit = doneToday && !item.completed;
    final isLocked = !previousDone || lockedByDailyLimit;
    final double alignX = (index % 2 == 0) ? -0.25 : 0.25;

    // Quando a etapa tem partes (dia de alimentação / sessão de treino) o nó
    // mostra o quanto já foi feito (ex.: "Sessão A  2/5"), para ficar claro
    // que está em andamento.
    final label = item.steps.isEmpty
        ? item.title
        : '${item.title}  ${item.stepsDone}/${item.steps.length}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Align(
        alignment: Alignment(alignX, 0),
        child: PathNodeWidget(
          label: label,
          icon: typeIcon,
          isCompleted: item.completed,
          isLocked: isLocked,
          onTap: () => onStepTap(item),
        ),
      ),
    );
  }
}

class _DailyLimitBanner extends StatelessWidget {
  final String kind; // "workout" | "nutrition"

  const _DailyLimitBanner({required this.kind});

  @override
  Widget build(BuildContext context) {
    final isNutrition = kind == 'nutrition';
    final message = isNutrition
        ? 'Dia de hoje concluído — limite: 1 dia por dia'
        : 'Treino de hoje concluído — limite: 1 por dia';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.crimsonRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.crimsonRed),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock, color: AppTheme.crimsonAccent, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.crimsonAccent,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyColumnMessage extends StatelessWidget {
  final String message;

  const _EmptyColumnMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
      ),
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