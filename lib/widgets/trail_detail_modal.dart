import 'package:flutter/material.dart';
import '../app/theme/app_theme.dart';
import '../features/home/domain/trail_entry.dart';

/// Modal de detalhe de uma ETAPA da trilha (um dia de alimentação ou uma sessão
/// de treino): abre com TODAS as etapas internas e deixa marcar uma a uma.
///
/// A trava de horário é opcional e vem do próprio dado ([StepEntry.requiredHour]):
/// na alimentação a refeição só libera na hora dela; no treino os exercícios já
/// nascem liberados. O check é otimista: marca na hora e desfaz se a API recusar.
class TrailDetailModal extends StatefulWidget {
  final TrailItemEntry item;
  final IconData icon;
  final String stepLabel; // "refeição" | "exercício"
  final String hint;
  final String completeMessage;

  /// Marca/desmarca uma etapa (índice dentro de [TrailItemEntry.steps]).
  final Future<void> Function(int index, bool value) onStepToggled;

  /// Usado só quando a etapa NÃO tem etapas internas (check único).
  final Future<void> Function() onComplete;

  const TrailDetailModal({
    super.key,
    required this.item,
    required this.icon,
    required this.stepLabel,
    required this.hint,
    required this.completeMessage,
    required this.onStepToggled,
    required this.onComplete,
  });

  @override
  State<TrailDetailModal> createState() => _TrailDetailModalState();
}

class _TrailDetailModalState extends State<TrailDetailModal> {
  late List<StepEntry> _steps;
  final Set<int> _saving = {};
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _steps = List.of(widget.item.steps);
  }

  // Sem trava de horário quando a etapa não define `required_hour`.
  bool _isUnlocked(StepEntry step) {
    if (step.requiredHour <= 0) return true;
    return DateTime.now().hour >= step.requiredHour;
  }

  Future<void> _toggle(int index, bool value) async {
    if (_saving.contains(index)) return;

    final previous = _steps[index];
    setState(() {
      _saving.add(index);
      _steps[index] = _copyWithDone(previous, value);
    });

    try {
      await widget.onStepToggled(index, value);
    } catch (_) {
      // A Home já mostra o erro (SnackBar); aqui só desfaz o check otimista.
      if (mounted) {
        setState(() => _steps[index] = previous);
      }
    } finally {
      if (mounted) {
        setState(() => _saving.remove(index));
      }
    }
  }

  Future<void> _completeWholeItem() async {
    if (_completing) return;
    setState(() => _completing = true);
    try {
      await widget.onComplete();
    } catch (_) {
      if (mounted) setState(() => _completing = false);
    }
  }

  StepEntry _copyWithDone(StepEntry step, bool done) => StepEntry(
    slot: step.slot,
    title: step.title,
    description: step.description,
    value: step.value,
    requiredHour: step.requiredHour,
    done: done,
  );

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final total = _steps.length;
    final done = _steps.where((s) => s.done).length;
    final isComplete = total > 0 && done >= total;

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
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                    ),
                  ),
                ),
                Icon(widget.icon, color: AppTheme.crimsonRed),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isComplete
                  ? widget.completeMessage
                  : '${widget.hint} (${done.toString().padLeft(2, '0')} de $total)',
              style: TextStyle(
                color: isComplete
                    ? AppTheme.crimsonRed
                    : AppTheme.textMuted,
                fontSize: 13,
                fontWeight: isComplete ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 16),

            // Card com a meta da etapa (ex.: "5 exercícios • ~50 min")
            if (item.value.isNotEmpty || item.description.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2D2D2D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.value.isNotEmpty) ...[
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.crimsonAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (item.description.isNotEmpty)
                      Text(
                        item.description,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Etapa sem etapas internas: um check só (comportamento antigo).
            if (total == 0)
              _CompleteButton(
                label: 'Concluir ${widget.stepLabel}',
                isCompleted: item.completed,
                isSaving: _completing,
                onPressed: _completeWholeItem,
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: total,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    final isUnlocked = _isUnlocked(step);
                    final isSaving = _saving.contains(index);

                    return Container(
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? const Color(0xFF111111)
                            : const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: step.done
                              ? AppTheme.crimsonRed
                              : (isUnlocked
                                  ? const Color(0xFF2D2D2D)
                                  : const Color(0xFF1F1F1F)),
                        ),
                      ),
                      child: CheckboxListTile(
                        activeColor: AppTheme.crimsonRed,
                        checkColor: Colors.black,
                        value: step.done,
                        // Cadeado quando ainda não liberou por horário.
                        secondary: !isUnlocked
                            ? Tooltip(
                                message:
                                    'Liberado a partir das ${step.requiredHour}h',
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
                          step.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked
                                ? AppTheme.textMain
                                : AppTheme.textMuted,
                          ),
                        ),
                        subtitle: Text(
                          isUnlocked
                              ? step.subtitle
                              : 'Liberado às ${step.requiredHour.toString().padLeft(2, '0')}:00h • ${step.subtitle}',
                          style: TextStyle(
                            color: isUnlocked
                                ? AppTheme.textMuted
                                : const Color(0xFF555555),
                            fontSize: 12,
                          ),
                        ),
                        // Bloqueado por horário ou salvando: sem interação.
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

/// Botão de conclusão única (etapas sem lista interna).
class _CompleteButton extends StatelessWidget {
  final String label;
  final bool isCompleted;
  final bool isSaving;
  final VoidCallback onPressed;

  const _CompleteButton({
    required this.label,
    required this.isCompleted,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.crimsonAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.crimsonAccent),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.crimsonAccent),
            SizedBox(width: 10),
            Text(
              'Etapa já concluída!',
              style: TextStyle(
                color: AppTheme.crimsonAccent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.crimsonRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isSaving ? null : onPressed,
        child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}
