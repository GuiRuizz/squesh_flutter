import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/presentation/settings_widgets.dart';
import '../domain/shop_models.dart';
import 'shop_items_tab.dart';
import 'shop_providers.dart';

/// O que o usuário já possui (`GET /shop/inventory`).
///
/// Uma linha por unidade entregue por pedido pago: comprar 3 do mesmo item
/// aparece 3 vezes, porque são 3 unidades no inventário.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: SettingsColors.background,
      appBar: const SettingsAppBar('MEUS ITENS'),
      body: inventoryAsync.when(
        loading: () => const SettingsLoading(),
        error: (error, _) => SettingsErrorView(
          message: describeError(error),
          onRetry: () => ref.invalidate(inventoryProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const SettingsEmptyView(
              icon: Icons.inventory_2_outlined,
              title: 'Inventário vazio',
              message:
                  'Os itens dos seus pedidos aparecem aqui assim que o '
                  'pagamento é confirmado.',
            );
          }

          return RefreshIndicator(
            color: SettingsColors.accent,
            backgroundColor: SettingsColors.surface,
            onRefresh: () async => ref.invalidate(inventoryProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _InventoryRow(item: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  final InventoryItem item;

  const _InventoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SettingsCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ShopItemImage(
                url: item.imageUrl,
                width: 56,
                height: 56,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SettingsColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        formatBRL(item.priceCents),
                        style: const TextStyle(
                          color: SettingsColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.category.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          item.category,
                          style: const TextStyle(
                            color: SettingsColors.textFaint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.acquiredAt != null)
                    Text(
                      'Adquirido em ${formatDate(item.acquiredAt)}',
                      style: const TextStyle(
                        color: SettingsColors.textFaint,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
            RatingStars(label: _ratingLabel(item.rating)),
          ],
        ),
      ),
    );
  }

  static String _ratingLabel(double rating) =>
      rating <= 0 ? '' : rating.toStringAsFixed(1).replaceAll('.', ',');
}