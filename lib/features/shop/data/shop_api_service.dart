import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../domain/shop_models.dart';

final shopApiServiceProvider = Provider<ShopApiService>((ref) {
  return ShopApiService(ref.watch(dioProvider));
});

/// Acesso ao catálogo e aos pedidos da loja.
///
/// Os preços nunca saem daqui: o app manda só `item_id` e `quantity` e quem
/// calcula o total é o Go. Mandar o preço do cliente permitiria comprar qualquer
/// coisa por R$ 0,01.
class ShopApiService {
  final Dio _dio;

  ShopApiService(this._dio);

  /// `GET /api/v1/shop` — o catálogo. Paginado no Go, mas a loja é pequena o
  /// bastante para uma página só (limite máximo de 100 por chamada).
  Future<List<ShopItem>> getItems({String search = ''}) async {
    final response = await _dio.get(
      ApiEndpoints.shop,
      queryParameters: {
        'limit': 100,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final data = response.data;
    if (data is! Map) return const [];
    final list = data['data'];
    if (list is! List) return const [];
    return [
      for (final item in list)
        ShopItem.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  /// `GET /api/v1/shop/:id` — detalhe de um item.
  Future<ShopItem> getItemById(String id) async {
    final response = await _dio.get(ApiEndpoints.shopItemById(id));
    return ShopItem.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// `POST /api/v1/shop/orders` — fecha o carrinho.
  ///
  /// Devolve o pedido já com o total calculado pelo servidor. Ele nasce
  /// "pending": os itens só entram no inventário quando o pagamento for
  /// confirmado.
  Future<ShopOrder> createOrder(List<({String itemId, int quantity})> lines) async {
    final response = await _dio.post(
      ApiEndpoints.shopOrders,
      data: {
        'items': [
          for (final line in lines)
            {'item_id': line.itemId, 'quantity': line.quantity},
        ],
      },
    );
    return ShopOrder.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// `GET /api/v1/shop/orders` — histórico, do mais novo para o mais antigo.
  Future<List<ShopOrder>> getMyOrders() async {
    final response = await _dio.get(ApiEndpoints.shopOrders);
    final list = response.data;
    if (list is! List) return const [];
    return [
      for (final order in list)
        ShopOrder.fromJson(Map<String, dynamic>.from(order as Map)),
    ];
  }

  /// `GET /api/v1/shop/orders/:id` — detalhe do pedido.
  Future<ShopOrder> getOrder(String id) async {
    final response = await _dio.get(ApiEndpoints.shopOrder(id));
    return ShopOrder.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// `POST /api/v1/shop/orders/:id/cancel` — descarta um pedido que ainda não
  /// foi pago.
  Future<ShopOrder> cancelOrder(String id) async {
    final response = await _dio.post(ApiEndpoints.shopOrderCancel(id));
    return ShopOrder.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// `GET /api/v1/shop/inventory` — o que o usuário já possui.
  Future<List<InventoryItem>> getInventory() async {
    final response = await _dio.get(ApiEndpoints.shopInventory);
    final data = response.data;
    if (data is! Map) return const [];
    final list = data['data'];
    if (list is! List) return const [];
    return [
      for (final item in list)
        InventoryItem.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }
}