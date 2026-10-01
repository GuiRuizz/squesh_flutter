import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_api_service.dart';
import '../domain/billing_models.dart';
import 'settings_providers.dart';
import 'settings_widgets.dart';

/// vitrine de planos + assinatura atual. É a tela que substitui o tile
/// fictício "Plano Pro Ativo".
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String? _busyPlanId;

  Future<void> _subscribe(Plan plan) async {
    setState(() => _busyPlanId = plan.id);
    try {
      await ref.read(settingsApiServiceProvider).subscribe(plan.id);
      ref.invalidate(subscriptionProvider);
      if (mounted) {
        showSettingsSnack(context, 'Plano ${plan.name} ativado! 🎉');
      }
    } catch (e) {
      if (mounted) showSettingsSnack(context, describeError(e), error: true);
    } finally {
      if (mounted) setState(() => _busyPlanId = null);
    }
  }

  Future<void> _cancel(Subscription sub) async {
    final confirmed = await confirmSettingsAction(
      context,
      title: 'Cancelar assinatura',
      message:
          'Você continua com o plano ${sub.plan.name} até '
          '${formatDate(sub.renewsAt)} (o período já está pago). '
          'Depois disso volta a ser gratuito e não renova.',
      confirmLabel: 'CANCELAR',
      cancelLabel: 'CONTINUAR PRO',
    );
    if (!confirmed) return;

    try {
      await ref.read(settingsApiServiceProvider).cancelSubscription();
      ref.invalidate(subscriptionProvider);
      if (mounted) {
        showSettingsSnack(
          context,
          'Assinatura cancelada. Você continua Pro até '
          '${formatDate(sub.renewsAt)}.',
        );
      }
    } catch (e) {
      if (mounted) showSettingsSnack(context, describeError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);
    final subAsync = ref.watch(subscriptionProvider);
    final current = subAsync.value;
    final currentPlanId = current?.isActive == true ? current!.plan.id : null;

    return Scaffold(
      backgroundColor: SettingsColors.background,
      appBar: const SettingsAppBar('ASSINATURA E PLANOS'),
      body: RefreshIndicator(
        color: SettingsColors.accent,
        backgroundColor: SettingsColors.surface,
        onRefresh: () async {
          ref.invalidate(plansProvider);
          ref.invalidate(subscriptionProvider);
        },
        child: plansAsync.when(
          loading: () => const SettingsLoading(),
          error: (error, _) => SettingsErrorView(
            message: describeError(error),
            onRetry: () => ref.invalidate(plansProvider),
          ),
          data: (plans) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _CurrentPlanCard(
                subscription: current,
                onCancel: current == null ? null : () => _cancel(current),
              ),
              const SizedBox(height: 20),
              const SettingsSectionHeader('PLANOS DISPONÍVEIS'),
              for (final plan in plans)
                _PlanCard(
                  plan: plan,
                  isCurrent: plan.id == currentPlanId,
                  busy: _busyPlanId == plan.id,
                  onSelect: () => _subscribe(plan),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  final Subscription? subscription;
  final VoidCallback? onCancel;

  const _CurrentPlanCard({required this.subscription, this.onCancel});

  @override
  Widget build(BuildContext context) {
    if (subscription == null || subscription!.isActive == false) {
      return SettingsCard(
        child: Row(
          children: [
            const Icon(
              Icons.lock_open_rounded,
              color: SettingsColors.textFaint,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Você está no plano gratuito.',
                style: TextStyle(
                  color: SettingsColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final sub = subscription!;
    return SettingsCard(
      borderColor: SettingsColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: SettingsColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: SettingsColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                sub.plan.name,
                style: const TextStyle(
                  color: SettingsColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sub.isCanceledButActive
                // Cancelada: o período já está pago, então não renova mais —
                // dizer "renova em" seria mentira.
                ? 'Cancelada • vale até ${formatDate(sub.renewsAt)} • '
                      '${sub.plan.priceLabel} ${sub.plan.periodLabel}'
                : 'Renova em ${formatDate(sub.renewsAt)} • '
                      '${sub.plan.priceLabel} ${sub.plan.periodLabel}',
            style: const TextStyle(
              color: SettingsColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              // Cancelar de novo não faz sentido.
              onPressed: sub.isCanceledButActive ? null : onCancel,
              icon: const Icon(
                Icons.cancel_outlined,
                size: 16,
                color: SettingsColors.textMuted,
              ),
              label: Text(
                sub.isCanceledButActive
                    ? 'Assinatura cancelada'
                    : 'Cancelar assinatura',
                style: TextStyle(
                  color: sub.isCanceledButActive
                      ? SettingsColors.textFaint
                      : SettingsColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final bool isCurrent;
  final bool busy;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.busy,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderColor: isCurrent
          ? SettingsColors.accent
          : SettingsColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    color: SettingsColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (plan.badge.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: SettingsColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: SettingsColors.divider),
                  ),
                  child: Text(
                    plan.badge,
                    style: const TextStyle(
                      color: SettingsColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            plan.description,
            style: const TextStyle(
              color: SettingsColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                plan.priceLabel,
                style: const TextStyle(
                  color: SettingsColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/${plan.periodLabel}',
                style: const TextStyle(
                  color: SettingsColors.textFaint,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final feature in plan.features)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: SettingsColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          color: SettingsColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (plan.highlight.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              plan.highlight,
              style: const TextStyle(
                color: SettingsColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SettingsPrimaryButton(
            label: isCurrent
                ? 'SEU PLANO ATUAL'
                : (busy ? 'AGUARDE...' : 'ASSINAR ${plan.name.toUpperCase()}'),
            busy: busy,
            onPressed: isCurrent ? null : onSelect,
          ),
        ],
      ),
    );
  }
}
