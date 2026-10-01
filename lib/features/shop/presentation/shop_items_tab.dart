import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/shop_models.dart';
import '../../settings/presentation/settings_widgets.dart';
import 'shop_providers.dart';

/// Aba "ITENS": o catálogo que vem do Go, com os chips de categoria derivados
/// dos próprios itens.
class ShopItemsTab extends ConsumerStatefulWidget {
  const ShopItemsTab({super.key, required this.onAddToCart});

  /// Chamado quando o item entra no carrinho, para a Loja abrir o aviso.
  final void Function(ShopItem item) onAddToCart;

  @override
  ConsumerState<ShopItemsTab> createState() => _ShopItemsTabState();
}

class _ShopItemsTabState extends ConsumerState<ShopItemsTab> {
  String _category = 'Todos';

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(shopItemsProvider);
    final categories = ref.watch(shopCategoriesProvider);

    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == _category;
              return GestureDetector(
                onTap: () => setState(() => _category = category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? SettingsColors.accent
                        : SettingsColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? SettingsColors.accent
                          : SettingsColors.divider,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : SettingsColors.textMuted,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: itemsAsync.when(
            loading: () => const SettingsLoading(),
            error: (error, _) => SettingsErrorView(
              message: describeError(error),
              onRetry: () => ref.invalidate(shopItemsProvider),
            ),
            data: (items) {
              final filtered = _category == 'Todos'
                  ? items
                  : items
                        .where((item) => item.category == _category)
                        .toList();

              if (filtered.isEmpty) {
                return SettingsEmptyView(
                  icon: Icons.inventory_2_outlined,
                  title: 'Nada por aqui',
                  message: _category == 'Todos'
                      ? 'A loja está vazia no momento.'
                      : 'Nenhum item em "$_category".',
                  actionLabel: 'Ver tudo',
                  onAction: () => setState(() => _category = 'Todos'),
                );
              }

              return RefreshIndicator(
                color: SettingsColors.accent,
                backgroundColor: SettingsColors.surface,
                onRefresh: () async => ref.invalidate(shopItemsProvider),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _ProductCard(item: filtered[index], onAdd: widget.onAddToCart),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ShopItem item;
  final void Function(ShopItem item) onAdd;

  const _ProductCard({required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showProductSheet(context, item),
      child: Container(
        decoration: BoxDecoration(
          color: SettingsColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SettingsColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: ShopItemImage(url: item.imageUrl, width: double.infinity),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SettingsColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.priceLabel,
                        style: const TextStyle(
                          color: SettingsColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      RatingStars(label: item.ratingLabel),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SettingsColors.surfaceAlt,
                        foregroundColor: SettingsColors.textPrimary,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => onAdd(item),
                      child: const Text(
                        'ADICIONAR',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Folha de detalhe do item, com seletor de quantidade.
void showProductSheet(BuildContext context, ShopItem item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: SettingsColors.surface,
    shape: RoundedRectangleBorder(borderRadius: settingsSheetRadius),
    builder: (sheetContext) => _ProductSheet(item: item),
  );
}

class _ProductSheet extends ConsumerStatefulWidget {
  final ShopItem item;

  const _ProductSheet({required this.item});

  @override
  ConsumerState<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends ConsumerState<_ProductSheet> {
  int _quantity = 1;

  void _addToCart() {
    final cart = ref.read(cartProvider.notifier);
    for (var i = 0; i < _quantity; i++) {
      cart.add(widget.item);
    }
    Navigator.pop(context);
    showSettingsSnack(
      context,
      _quantity > 1
          ? '${_quantity}x ${widget.item.name} no carrinho'
          : '${widget.item.name} no carrinho',
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SettingsColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ShopItemImage(url: item.imageUrl, height: 180),
            ),
            const SizedBox(height: 16),
            Text(
              item.name,
              style: const TextStyle(
                color: SettingsColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  item.priceLabel,
                  style: const TextStyle(
                    color: SettingsColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(width: 10),
                RatingStars(label: item.ratingLabel),
                if (item.category.isNotEmpty) ...[
                  const SizedBox(width: 10),
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
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                item.description,
                style: const TextStyle(
                  color: SettingsColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quantidade',
                  style: TextStyle(
                    color: SettingsColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                Row(
                  children: [
                    _QuantityButton(
                      icon: Icons.remove_circle_outline,
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: SettingsColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.add_circle_outline,
                      onPressed: _quantity < 99
                          ? () => setState(() => _quantity++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsPrimaryButton(
              label:
                  'ADICIONAR — ${formatBRL(item.priceCents * _quantity)}',
              onPressed: _addToCart,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: onPressed == null
            ? SettingsColors.textFaint
            : SettingsColors.textPrimary,
      ),
      onPressed: onPressed,
    );
  }
}

/// Imagem do item com fallback: URL vazia ou quebrada não pode virar ícone
/// cinza no meio do grid.
class ShopItemImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;

  const ShopItemImage({super.key, required this.url, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return _placeholder();

    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _placeholder(spinner: true);
      },
    );
  }

  Widget _placeholder({bool spinner = false}) {
    return Container(
      width: width,
      height: height,
      color: SettingsColors.surfaceAlt,
      alignment: Alignment.center,
      child: spinner
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(
              Icons.image_not_supported_outlined,
              color: SettingsColors.textFaint,
              size: 22,
            ),
    );
  }
}

/// Estrelas da avaliação. Rótulo vazio = item sem avaliação, e aí não mostra
/// nada em vez de "0,0 estrelas".
class RatingStars extends StatelessWidget {
  final String label;

  const RatingStars({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
        Text(
          label,
          style: const TextStyle(color: SettingsColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}