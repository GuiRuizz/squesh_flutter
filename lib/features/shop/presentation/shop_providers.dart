import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/shop_api_service.dart';
import '../domain/shop_models.dart';

/// Catálogo completo da loja. A tela monta os chips de categoria a partir
/// daqui, então uma categoria nova aparece sozinha quando o admin cadastra um
/// item nela.
final shopItemsProvider = FutureProvider<List<ShopItem>>((ref) {
  return ref.read(shopApiServiceProvider).getItems();
});

/// Categorias em ordem de_alpha, com "Todos" na frente.
final shopCategoriesProvider = Provider<List<String>>((ref) {
  final items = ref.watch(shopItemsProvider).value ?? const [];
  final seen = <String>{};
  for (final item in items) {
    final category = item.category.trim();
    if (category.isNotEmpty) seen.add(category);
  }
  final sorted = seen.toList()..sort(
    (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
  );
  return ['Todos', ...sorted];
});

/// Meus pedidos, do mais novo para o mais antigo.
final myOrdersProvider = FutureProvider<List<ShopOrder>>((ref) {
  return ref.read(shopApiServiceProvider).getMyOrders();
});

/// O que eu já possuo. Vazio enquanto não houver login — a tela só chama
/// quando está autenticado.
final inventoryProvider = FutureProvider<List<InventoryItem>>((ref) {
  return ref.read(shopApiServiceProvider).getInventory();
});

/// Linha do carrinho: o item do catálogo + a quantidade escolhida.
class CartLine {
  final ShopItem item;
  final int quantity;

  const CartLine({required this.item, this.quantity = 1});

  CartLine copyWith({int? quantity}) =>
      CartLine(item: item, quantity: quantity ?? this.quantity);

  int get totalCents => item.priceCents * quantity;
}

/// Carrinho só em memória: some quando o app fecha. O servidor nunca guarda
/// carrinho abandonedado — o que existe é o pedido, criado no checkout.
class CartNotifier extends StateNotifier<List<CartLine>> {
  CartNotifier() : super(const []);

  void add(ShopItem item) {
    final index = state.indexWhere((line) => line.item.id == item.id);
    if (index >= 0) {
      final updated = [...state];
      updated[index] = updated[index].copyWith(
        quantity: updated[index].quantity + 1,
      );
      state = updated;
    } else {
      state = [...state, CartLine(item: item)];
    }
  }

  void remove(String itemId) {
    state = state.where((line) => line.item.id != itemId).toList();
  }

  /// Delta negativo; ao chegar em zero a linha sai do carrinho.
  void changeQuantity(String itemId, int delta) {
    final updated = <CartLine>[];
    for (final line in state) {
      if (line.item.id != itemId) {
        updated.add(line);
        continue;
      }
      final quantity = line.quantity + delta;
      if (quantity > 0) updated.add(line.copyWith(quantity: quantity));
    }
    state = updated;
  }

  void clear() => state = const [];

  int get totalQuantity => state.fold(0, (sum, line) => sum + line.quantity);

  int get totalCents => state.fold(0, (sum, line) => sum + line.totalCents);

  bool get isEmpty => state.isEmpty;
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartLine>>(
  (ref) => CartNotifier(),
);