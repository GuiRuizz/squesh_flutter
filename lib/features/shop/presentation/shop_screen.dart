import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/presentation/plan_widgets.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../data/shop_api_service.dart';
import '../domain/shop_models.dart';
import 'inventory_screen.dart';
import 'order_screen.dart';
import 'shop_items_tab.dart';
import 'shop_providers.dart';

/// A Loja tem duas abas: os ITENS que se compram e os PLANOS de assinatura.
///
/// Os planos vêm do mesmo catálogo e da mesma assinatura que a tela de
/// Configurações usa — é o [PlansShowcase] compartilhado, para não haver duas
/// verdades sobre "qual é o meu plano".
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  void _addToCart(ShopItem item) {
    ref.read(cartProvider.notifier).add(item);
    showSettingsSnack(context, '${item.name} adicionado ao carrinho!');
  }

  Future<void> _openCart() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      showSettingsSnack(context, 'Seu carrinho está vazio.');
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: SettingsColors.surface,
      shape: RoundedRectangleBorder(borderRadius: settingsSheetRadius),
      builder: (_) => const _CartSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = ref.watch(cartProvider).fold<int>(
      0,
      (sum, line) => sum + line.quantity,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: SettingsColors.background,
        appBar: AppBar(
          backgroundColor: SettingsColors.surface,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'LOJA',
            style: TextStyle(
              color: SettingsColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.5,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Meus itens',
              icon: const Icon(
                Icons.inventory_2_outlined,
                color: SettingsColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InventoryScreen()),
              ),
            ),
            IconButton(
              tooltip: 'Meus pedidos',
              icon: const Icon(
                Icons.receipt_long_outlined,
                color: SettingsColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              ),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    color: SettingsColors.textPrimary,
                  ),
                  onPressed: _openCart,
                ),
                if (totalItems > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: SettingsColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$totalItems',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          bottom: const TabBar(
            indicatorColor: SettingsColors.accent,
            labelColor: SettingsColors.textPrimary,
            unselectedLabelColor: SettingsColors.textFaint,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'ITENS'),
              Tab(text: 'PLANOS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ShopItemsTab(onAddToCart: _addToCart),
            // Mesmo widget da tela de Assinatura: a vitrine já tem o próprio
            // RefreshIndicator, então puxar para baixo recarrega os planos.
            const PlansShowcase(header: 'ESCOLHA O TEU PLANO'),
          ],
        ),
      ),
    );
  }
}

/// Folha do carrinho: o que vai ser comprado e o botão de fechar o pedido.
class _CartSheet extends ConsumerStatefulWidget {
  const _CartSheet();

  @override
  ConsumerState<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends ConsumerState<_CartSheet> {
  bool _busy = false;

  Future<void> _checkout() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty || _busy) return;

    setState(() => _busy = true);
    try {
      final order = await ref.read(shopApiServiceProvider).createOrder([
        for (final line in cart)
          (itemId: line.item.id, quantity: line.quantity),
      ]);

      ref.read(cartProvider.notifier).clear();
      ref.invalidate(myOrdersProvider);
      ref.invalidate(inventoryProvider);
      if (!mounted) return;

      final navigator = Navigator.of(context);
      Navigator.of(context).pop();
      await navigator.push(
        MaterialPageRoute(builder: (_) => OrderScreen(orderId: order.id)),
      );
    } catch (e) {
      if (mounted) showSettingsSnack(context, describeError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SettingsColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Meu Carrinho',
                  style: TextStyle(
                    color: SettingsColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                if (cart.isNotEmpty)
                  TextButton(
                    onPressed: notifier.clear,
                    child: const Text(
                      'Limpar',
                      style: TextStyle(color: SettingsColors.accent),
                    ),
                  ),
              ],
            ),
            const Divider(color: SettingsColors.divider),
            if (cart.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Seu carrinho está vazio',
                  style: TextStyle(color: SettingsColors.textFaint),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cart.length,
                  itemBuilder: (context, index) {
                    final line = cart[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ShopItemImage(
                          url: line.item.imageUrl,
                          width: 48,
                          height: 48,
                        ),
                      ),
                      title: Text(
                        line.item.name,
                        style: const TextStyle(
                          color: SettingsColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        formatBRL(line.totalCents),
                        style: const TextStyle(
                          color: SettingsColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: SettingsColors.textPrimary,
                            ),
                            onPressed: () =>
                                notifier.changeQuantity(line.item.id, -1),
                          ),
                          Text(
                            '${line.quantity}',
                            style: const TextStyle(
                              color: SettingsColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: SettingsColors.textPrimary,
                            ),
                            onPressed: () =>
                                notifier.changeQuantity(line.item.id, 1),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const Divider(color: SettingsColors.divider),
            if (cart.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      color: SettingsColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    formatBRL(notifier.totalCents),
                    style: const TextStyle(
                      color: SettingsColors.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'O total é confirmado pelo servidor no momento do pedido.',
                style: TextStyle(color: SettingsColors.textFaint, fontSize: 11),
              ),
              const SizedBox(height: 16),
              SettingsPrimaryButton(
                label: 'FINALIZAR COMPRA',
                busy: _busy,
                onPressed: _checkout,
              ),
            ],
          ],
        ),
      ),
    );
  }
}