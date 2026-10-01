import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/presentation/settings_widgets.dart';
import '../data/shop_api_service.dart';
import '../domain/shop_models.dart';
import 'shop_providers.dart';

/// Um pedido específico (`GET /shop/orders/:id`).
final orderProvider = FutureProvider.family<ShopOrder, String>((ref, orderId) {
  return ref.read(shopApiServiceProvider).getOrder(orderId);
});

/// Detalhe de um pedido: o que foi comprado, quanto custa e como está o
/// pagamento.
class OrderScreen extends ConsumerWidget {
  final String orderId;

  const OrderScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderProvider(orderId));

    return Scaffold(
      backgroundColor: SettingsColors.background,
      appBar: const SettingsAppBar('SEU PEDIDO'),
      body: orderAsync.when(
        loading: () => const SettingsLoading(),
        error: (error, _) => SettingsErrorView(
          message: describeError(error),
          onRetry: () => ref.invalidate(orderProvider(orderId)),
        ),
        data: (order) => RefreshIndicator(
          color: SettingsColors.accent,
          backgroundColor: SettingsColors.surface,
          onRefresh: () async => ref.invalidate(orderProvider(orderId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusCard(order: order),
              const SizedBox(height: 16),
              if (order.isPending) ...[
                _PaymentCard(order: order),
                const SizedBox(height: 16),
              ],
              _LinesCard(order: order),
              const SizedBox(height: 16),
              if (order.isPending)
                OutlinedButton.icon(
                  onPressed: () => _cancel(context, ref, order),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('CANCELAR PEDIDO'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SettingsColors.textMuted,
                    side: const BorderSide(color: SettingsColors.divider),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    ShopOrder order,
  ) async {
    final confirmed = await confirmSettingsAction(
      context,
      title: 'Cancelar pedido',
      message:
          'Seu pedido de ${order.totalLabel} será descartado. '
          'Nada foi cobrado.',
      confirmLabel: 'CANCELAR PEDIDO',
      cancelLabel: 'VOLTAR',
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(shopApiServiceProvider).cancelOrder(order.id);
      ref.invalidate(orderProvider(order.id));
      ref.invalidate(myOrdersProvider);
      if (context.mounted) {
        showSettingsSnack(context, 'Pedido cancelado.');
      }
    } catch (e) {
      if (context.mounted) {
        showSettingsSnack(context, describeError(e), error: true);
      }
    }
  }
}

class _StatusCard extends StatelessWidget {
  final ShopOrder order;

  const _StatusCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (order.status) {
      'paid' => ('PAGO', SettingsColors.accent),
      'canceled' => ('CANCELADO', SettingsColors.textFaint),
      _ => ('AGUARDANDO PAGAMENTO', Colors.amber),
    };

    return SettingsCard(
      borderColor: order.isPaid ? SettingsColors.accent : SettingsColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${order.totalQuantity} ${order.totalQuantity == 1 ? 'item' : 'itens'}',
                style: const TextStyle(
                  color: SettingsColors.textFaint,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            order.totalLabel,
            style: const TextStyle(
              color: SettingsColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          if (order.paidAt != null)
            Text(
              'Pago em ${formatDate(order.paidAt)}',
              style: const TextStyle(
                color: SettingsColors.textMuted,
                fontSize: 12,
              ),
            )
          else if (order.createdAt != null)
            Text(
              'Feito em ${formatDate(order.createdAt)}',
              style: const TextStyle(
                color: SettingsColors.textMuted,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

/// Bloco de pagamento.
///
/// Hoje o Go devolve `checkout_url` vazio porque não há provedor de pagamento
/// integrado: o app diz isso em vez de oferecer um botão que não abre nada.
/// Quando o Stripe entrar, o Go passa a devolver a URL e aqui aparece o botão
/// "PAGAR" abrindo essa URL (precisa do pacote url_launcher).
class _PaymentCard extends StatelessWidget {
  final ShopOrder order;

  const _PaymentCard({required this.order});

  @override
  Widget build(BuildContext context) {
    if (order.hasCheckout) {
      return SettingsCard(
        borderColor: SettingsColors.accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PAGAR AGORA',
              style: TextStyle(
                color: SettingsColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Você é levado para o pagamento seguro. Os itens entram no seu '
              'inventário assim que o pagamento é confirmado.',
              style: TextStyle(
                color: SettingsColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            // TODO(stripe): abrir order.checkoutUrl com url_launcher.
            Text(
              order.checkoutUrl,
              style: const TextStyle(color: SettingsColors.textFaint, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return const SettingsCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_empty_rounded, color: Colors.amber, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'O pagamento online ainda não está liberado. Seu pedido fica '
              'guardado aqui e, assim que ficar, você paga por esta tela — os '
              'itens só entram no inventário depois do pagamento.',
              style: TextStyle(
                color: SettingsColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinesCard extends StatelessWidget {
  final ShopOrder order;

  const _LinesCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader('ITENS DO PEDIDO'),
          for (final line in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: SettingsColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${line.quantity}x',
                      style: const TextStyle(
                        color: SettingsColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.name,
                          style: const TextStyle(
                            color: SettingsColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${line.unitPriceLabel} cada',
                          style: const TextStyle(
                            color: SettingsColors.textFaint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    line.lineTotalLabel,
                    style: const TextStyle(
                      color: SettingsColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(color: SettingsColors.divider, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: SettingsColors.textSecondary, fontSize: 14),
              ),
              Text(
                order.totalLabel,
                style: const TextStyle(
                  color: SettingsColors.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Histórico de pedidos (`GET /shop/orders`).
///
/// Não é luxo: só existe um pedido aguardando pagamento por vez, então sem esta
/// tela um pedido esquecido no carrinho trancaria o checkout seguinte sem o
/// usuário ter como sair dele.
class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: SettingsColors.background,
      appBar: const SettingsAppBar('MEUS PEDIDOS'),
      body: ordersAsync.when(
        loading: () => const SettingsLoading(),
        error: (error, _) => SettingsErrorView(
          message: describeError(error),
          onRetry: () => ref.invalidate(myOrdersProvider),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const SettingsEmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'Nenhum pedido ainda',
              message: 'Quando você finalizar uma compra, ela aparece aqui.',
            );
          }

          return RefreshIndicator(
            color: SettingsColors.accent,
            backgroundColor: SettingsColors.surface,
            onRefresh: () async => ref.invalidate(myOrdersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SettingsCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderScreen(orderId: order.id),
                        ),
                      ),
                      leading: Icon(
                        order.isPaid
                            ? Icons.check_circle_outline
                            : (order.isCanceled
                                  ? Icons.cancel_outlined
                                  : Icons.hourglass_empty_rounded),
                        color: order.isPaid
                            ? SettingsColors.accent
                            : SettingsColors.textFaint,
                      ),
                      title: Text(
                        '${order.totalLabel} • ${order.totalQuantity} '
                        '${order.totalQuantity == 1 ? 'item' : 'itens'}',
                        style: const TextStyle(
                          color: SettingsColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${order.statusLabel} • ${formatDate(order.createdAt)}',
                        style: const TextStyle(
                          color: SettingsColors.textFaint,
                          fontSize: 11,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: SettingsColors.textFaint,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}