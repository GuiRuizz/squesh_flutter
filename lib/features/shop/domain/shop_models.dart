/// Modelos da loja: catálogo, carrinho, pedido e inventário.
///
/// Espelham os DTOs de `internal/dto/shop_dto.go`. Preço sempre em centavos —
/// o Go manda centavos e o app só converte na hora de exibir.
library;

/// Preço em centavos no formato brasileiro (11990 -> "R$ 119,90").
String formatBRL(int cents) =>
    'R\$ ${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

/// Um item do catálogo (`GET /shop`).
class ShopItem {
  final String id;
  final String name;
  final String description;
  final int priceCents;
  final String imageUrl;
  final String category;
  final double rating;

  const ShopItem({
    required this.id,
    required this.name,
    this.description = '',
    this.priceCents = 0,
    this.imageUrl = '',
    this.category = '',
    this.rating = 0,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
    id: (json['id'] as String?) ?? '',
    name: (json['name'] as String?) ?? '',
    description: (json['description'] as String?) ?? '',
    priceCents: (json['price_cents'] as num?)?.toInt() ?? 0,
    imageUrl: (json['image_url'] as String?) ?? '',
    category: (json['category'] as String?) ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
  );

  String get priceLabel => formatBRL(priceCents);

  /// Vazio quando o item não tem avaliação — a tela esconde as estrelas em vez
  /// de mostrar "0,0".
  String get ratingLabel => rating <= 0
      ? ''
      : rating.toStringAsFixed(1).replaceAll('.', ',');
}

/// Uma linha do pedido. O preço é cópia do momento da compra, então continua
/// mostrando o que foi realmente cobrado mesmo depois de o admin mudar o preço.
class ShopOrderLine {
  final String id;
  final String itemId;
  final String name;
  final int unitPriceCents;
  final int quantity;
  final int lineTotalCents;

  const ShopOrderLine({
    required this.id,
    required this.itemId,
    required this.name,
    required this.unitPriceCents,
    required this.quantity,
    required this.lineTotalCents,
  });

  factory ShopOrderLine.fromJson(Map<String, dynamic> json) => ShopOrderLine(
    id: (json['id'] as String?) ?? '',
    itemId: (json['item_id'] as String?) ?? '',
    name: (json['name'] as String?) ?? '',
    unitPriceCents: (json['unit_price_cents'] as num?)?.toInt() ?? 0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    lineTotalCents: (json['line_total_cents'] as num?)?.toInt() ?? 0,
  );

  String get unitPriceLabel => formatBRL(unitPriceCents);
  String get lineTotalLabel => formatBRL(lineTotalCents);
}

/// O pedido do carrinho (`POST /shop/orders`, `GET /shop/orders/:id`).
class ShopOrder {
  final String id;
  final String status;
  final int totalCents;
  final String checkoutUrl;
  final DateTime? paidAt;
  final DateTime? canceledAt;
  final DateTime? createdAt;
  final List<ShopOrderLine> items;

  const ShopOrder({
    required this.id,
    required this.status,
    this.totalCents = 0,
    this.checkoutUrl = '',
    this.paidAt,
    this.canceledAt,
    this.createdAt,
    this.items = const [],
  });

  factory ShopOrder.fromJson(Map<String, dynamic> json) => ShopOrder(
    id: (json['id'] as String?) ?? '',
    status: (json['status'] as String?) ?? 'pending',
    totalCents: (json['total_cents'] as num?)?.toInt() ?? 0,
    checkoutUrl: (json['checkout_url'] as String?) ?? '',
    paidAt: DateTime.tryParse(json['paid_at'] as String? ?? ''),
    canceledAt: DateTime.tryParse(json['canceled_at'] as String? ?? ''),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    items: [
      for (final line in (json['items'] as List? ?? const []))
        ShopOrderLine.fromJson(Map<String, dynamic>.from(line as Map)),
    ],
  );

  bool get isPending => status == 'pending';
  bool get isPaid => status == 'paid';
  bool get isCanceled => status == 'canceled';

  /// Só existe um pedido aguardando pagamento por vez, então a partir do
  /// momento em que o usuário vê o pedido o carrinho já pode ser esvaziado.
  bool get canBeCanceled => isPending;

  /// Onde o app manda o usuário pagar. Vazio enquanto o provedor de pagamento
  /// não estiver integrado — a tela precisa saber que não há para onde abrir.
  bool get hasCheckout => checkoutUrl.trim().isNotEmpty;

  int get totalQuantity =>
      items.fold(0, (sum, line) => sum + line.quantity);

  String get totalLabel => formatBRL(totalCents);

  String get statusLabel {
    switch (status) {
      case 'paid':
        return 'Pago';
      case 'canceled':
        return 'Cancelado';
      default:
        return 'Aguardando pagamento';
    }
  }
}

/// Um item que o usuário já possui (`GET /shop/inventory`).
class InventoryItem {
  final String id;
  final String itemId;
  final String name;
  final String imageUrl;
  final int priceCents;
  final String category;
  final double rating;
  final DateTime? acquiredAt;

  const InventoryItem({
    required this.id,
    required this.itemId,
    required this.name,
    this.imageUrl = '',
    this.priceCents = 0,
    this.category = '',
    this.rating = 0,
    this.acquiredAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: (json['id'] as String?) ?? '',
    itemId: (json['item_id'] as String?) ?? '',
    name: (json['name'] as String?) ?? '',
    imageUrl: (json['image_url'] as String?) ?? '',
    priceCents: (json['price_cents'] as num?)?.toInt() ?? 0,
    category: (json['category'] as String?) ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    acquiredAt: DateTime.tryParse(json['acquired_at'] as String? ?? ''),
  );
}