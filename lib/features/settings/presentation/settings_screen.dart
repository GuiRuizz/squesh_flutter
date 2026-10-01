import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../profile/domain/user_preferences.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/my_posts_screen.dart';
import '../../profile/presentation/profile_controller.dart';
import 'addresses_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'payment_methods_screen.dart';
import 'settings_providers.dart';
import 'settings_widgets.dart';
import 'subscription_screen.dart';

/// Configurações do usuário.
///
/// Antes esta tela era quase toda fictícia: nome "Guilherme Sassi", bio fixa,
/// avatar de pravatar.cc, "Plano Pro Ativo", "2 endereços" e um switch que só
/// vivia na memória. Agora tudo vem do `GET /users/me` e dos endpoints de
/// assinatura/cartão/endereço, e cada switch volta pro banco.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: SettingsColors.background,
      appBar: const SettingsAppBar('CONFIGURAÇÕES'),
      body: RefreshIndicator(
        color: SettingsColors.accent,
        backgroundColor: SettingsColors.surface,
        onRefresh: () async {
          ref.invalidate(profileControllerProvider);
          ref.invalidate(subscriptionProvider);
          ref.invalidate(paymentMethodsProvider);
          ref.invalidate(addressesProvider);
          await ref.read(profileControllerProvider.future);
        },
        child: profileAsync.when(
          loading: () => const SettingsLoading(),
          error: (error, _) => SettingsErrorView(
            message: describeError(error),
            onRetry: () => ref.invalidate(profileControllerProvider),
          ),
          data: (profile) => _SettingsBody(profile: profile),
        ),
      ),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  final UserProfile profile;

  const _SettingsBody({required this.profile});

  /// Abre uma sub-tela e, ao voltar, roda [onReturn] para invalidar os
  /// providers que ela altera — sem isso os números dos tiles ficariam
  /// velhos até o próximo pull-to-refresh.
  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    Widget screen,
    void Function(WidgetRef ref) onReturn,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
    onReturn(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = profile.preferences;
    final subAsync = ref.watch(subscriptionProvider);
    final methodsAsync = ref.watch(paymentMethodsProvider);
    final addressesAsync = ref.watch(addressesProvider);

    final subscription = subAsync.value;
    final cardCount = methodsAsync.value?.length;
    final addressCount = addressesAsync.value?.length;

    // Enquanto a assinatura não volta da API, não dá para dizer "plano
    // gratuito": esse estado também é o de quem realmente não tem assinatura.
    final subscriptionText = switch (subAsync) {
      AsyncData(:final value) => value == null
          ? 'Você está no plano gratuito'
          : (value.isCanceledButActive
                ? 'Plano ${value.plan.name} • cancelado, vale até '
                      '${formatDate(value.renewsAt)}'
                : (value.isActive
                      ? 'Plano ${value.plan.name} • renova em '
                            '${formatDate(value.renewsAt)}'
                      : 'Sua assinatura terminou')),
      _ => 'Consultando sua assinatura...',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _ProfileCard(profile: profile, isPro: subscription?.isActive ?? false),
        const SizedBox(height: 24),

        const SettingsSectionHeader('CONTEÚDO'),
        SettingsTile(
          icon: Icons.photo_library_outlined,
          title: 'Meus posts',
          subtitle: 'Veja, edite e apague suas publicações',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const MyPostsScreen()),
          ),
        ),

        const SizedBox(height: 16),
        const SettingsSectionHeader('PREFERÊNCIAS DE NOTIFICAÇÃO'),
        SettingsCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              SettingsSwitchTile(
                title: 'Notificações',
                subtitle: 'O botão geral. Desligue para não receber nada',
                value: preferences.pushEnabled,
                onChanged: (value) => _savePreferences(
                  context,
                  ref,
                  preferences.copyWith(pushEnabled: value),
                ),
              ),
              const Divider(height: 1, color: SettingsColors.divider),
              SettingsSwitchTile(
                title: 'Lembretes de treino',
                subtitle: 'Hora de treinar e sequência do dia',
                value: preferences.workoutReminders,
                // As categorias dependem do botão geral: com ele desligado,
                // os switches ficam visíveis mas travados.
                enabled: preferences.pushEnabled,
                onChanged: (value) => _savePreferences(
                  context,
                  ref,
                  preferences.copyWith(workoutReminders: value),
                ),
              ),
              const Divider(height: 1, color: SettingsColors.divider),
              SettingsSwitchTile(
                title: 'Novidades da loja',
                subtitle: 'Itens, skins e promoções',
                value: preferences.shopNews,
                enabled: preferences.pushEnabled,
                onChanged: (value) => _savePreferences(
                  context,
                  ref,
                  preferences.copyWith(shopNews: value),
                ),
              ),
              const Divider(height: 1, color: SettingsColors.divider),
              SettingsSwitchTile(
                title: 'Curtidas e comentários',
                subtitle: 'Quando alguém interage com seus posts',
                value: preferences.socialAlerts,
                enabled: preferences.pushEnabled,
                onChanged: (value) => _savePreferences(
                  context,
                  ref,
                  preferences.copyWith(socialAlerts: value),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const SettingsSectionHeader('ASSINATURA E PAGAMENTOS'),
        SettingsTile(
          icon: Icons.workspace_premium_outlined,
          title: 'Assinatura e planos',
          subtitle: subscriptionText,
          // Cancelada mas ainda dentro do período pago continua sendo PRO.
          trailingText: subscription?.isActive == true ? 'PRO' : null,
          onTap: () => _open(
            context,
            ref,
            const SubscriptionScreen(),
            (r) => r.invalidate(subscriptionProvider),
          ),
        ),
        SettingsTile(
          icon: Icons.credit_card_rounded,
          title: 'Formas de pagamento',
          subtitle: cardCount == null
              ? 'Cartões salvos'
              : (cardCount == 0
                    ? 'Nenhum cartão salvo'
                    : '$cardCount ${cardCount == 1 ? 'cartão salvo' : 'cartões salvos'}'),
          onTap: () => _open(
            context,
            ref,
            const PaymentMethodsScreen(),
            (r) => r.invalidate(paymentMethodsProvider),
          ),
        ),

        const SizedBox(height: 16),
        const SettingsSectionHeader('ENTREGAS'),
        SettingsTile(
          icon: Icons.location_on_outlined,
          title: 'Endereços de entrega',
          subtitle: addressCount == null
              ? 'Seus endereços'
              : (addressCount == 0
                    ? 'Nenhum endereço salvo'
                    : '$addressCount ${addressCount == 1 ? 'endereço salvo' : 'endereços salvos'}'),
          onTap: () => _open(
            context,
            ref,
            const AddressesScreen(),
            (r) => r.invalidate(addressesProvider),
          ),
        ),

        const SizedBox(height: 16),
        const SettingsSectionHeader('CONTA'),
        SettingsTile(
          icon: Icons.lock_outline_rounded,
          title: 'Alterar senha',
          subtitle: profile.email,
          onTap: () => _open(context, ref, const ChangePasswordScreen(), (_) {}),
        ),
        const SizedBox(height: 8),
        SettingsCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.logout_rounded,
              color: SettingsColors.accent,
            ),
            title: const Text(
              'Sair da conta',
              style: TextStyle(
                color: SettingsColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => _signOut(context, ref),
          ),
        ),

        const SizedBox(height: 24),
        Center(
          child: Text(
            'Conta criada em ${formatDate(profile.createdAt)}',
            style: const TextStyle(color: SettingsColors.textFaint, fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// Salva uma preferência e, se o servidor recusar, recarrega o perfil para a
  /// tela voltar a mostrar a verdade.
  Future<void> _savePreferences(
    BuildContext context,
    WidgetRef ref,
    UserPreferences preferences,
  ) async {
    try {
      await ref
          .read(profileControllerProvider.notifier)
          .savePreferences(preferences);
    } catch (e) {
      if (!context.mounted) return;
      showSettingsSnack(context, describeError(e), error: true);
      ref.invalidate(profileControllerProvider);
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmSettingsAction(
      context,
      title: 'Sair da conta',
      message: 'Você vai precisar entrar de novo com e-mail e senha.',
      confirmLabel: 'SAIR',
    );
    if (!confirmed) return;

    await ref.read(authControllerProvider.notifier).logout();
    if (context.mounted) {
      showSettingsSnack(context, 'Você saiu da conta.');
    }
  }
}

class _ProfileCard extends ConsumerWidget {
  final UserProfile profile;
  final bool isPro;

  const _ProfileCard({required this.profile, required this.isPro});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              ProfileAvatar(
                avatarUrl: profile.avatarUrl,
                name: profile.name,
                size: 72,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: SettingsColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (profile.isAdmin) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.shield_rounded,
                            size: 14,
                            color: SettingsColors.accent,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SettingsColors.textFaint,
                        fontSize: 12,
                      ),
                    ),
                    if (profile.bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        profile.bio,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SettingsColors.textMuted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => EditProfileScreen(profile: profile),
                  ),
                ),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: SettingsColors.textPrimary,
                ),
                tooltip: 'Editar perfil',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(
                icon: Icons.local_fire_department_rounded,
                value: '${profile.streak}',
                label: profile.streak == 1 ? 'dia' : 'dias',
                color: const Color(0xFFFF7043),
              ),
              const _StatDivider(),
              _Stat(
                icon: Icons.stars_rounded,
                value: '${profile.points}',
                label: 'pontos',
                color: const Color(0xFFFFCA28),
              ),
              const _StatDivider(),
              _Stat(
                icon: isPro
                    ? Icons.workspace_premium_rounded
                    : Icons.lock_outline_rounded,
                value: isPro ? 'PRO' : 'FREE',
                label: 'plano',
                color: isPro ? SettingsColors.accent : SettingsColors.textFaint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: SettingsColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: SettingsColors.textFaint,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: SettingsColors.divider,
    );
  }
}