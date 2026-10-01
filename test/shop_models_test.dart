// Testes de unidade do parsing dos modelos da loja.
// (A UI e as chamadas HTTP não são exercitadas aqui — sem rede.)
//
// Os JSONs abaixo são as respostas REAIS do backend, copiadas field por field.
// A reason de existirem: campo nomeado diferente no Go não dá erro no
// analyze — vira 0, string vazia e uma tela quebrada em silêncio.

import 'package:flutter_test/flutter_test.dart';

import 'package:squesh_flutter/features/shop/domain/shop_models.dart';

void main() {
  group('ShopItem.fromJson', () {
    test('mapeia um item do GET /shop', () {
      final item = ShopItem.fromJson(const {
        'id': '73791696-445a-4792-9ce2-acfdc25a6d6b',
        'name': 'Strap de Puxada de Couro',
        'description': 'Alça de couro com gancho metálico para puxada e costas.',
        'price_cents': 4500,
        'image_url':
            'https://images.unsplash.com/photo-1517838277536?q=80&w=600',
        'category': 'Acessórios',
        'rating': 4.9,
      });

      expect(item.id, '73791696-445a-4792-9ce2-acfdc25a6d6b');
      expect(item.name, 'Strap de Puxada de Couro');
      expect(item.priceCents, 4500);
      expect(item.category, 'Acessórios');
      expect(item.rating, 4.9);
      expect(item.priceLabel, 'R\$ 45,00');
      expect(item.ratingLabel, '4,9');
    });

    test('rating 0 vira rótulo vazio (a tela esconde as estrelas)', () {
      final item = ShopItem.fromJson(const {
        'id': 'x',
        'name': 'Item sem avaliação',
        'price_cents': 100,
        'rating': 0,
      });

      expect(item.ratingLabel, '');
      expect(item.category, '');
      expect(item.imageUrl, '');
    });
  });

  group('formatBRL', () {
    test('formata centavos no padrão brasileiro', () {
      expect(formatBRL(0), 'R\$ 0,00');
      expect(formatBRL(4500), 'R\$ 45,00');
      expect(formatBRL(11990), 'R\$ 119,90');
      expect(formatBRL(25990), 'R\$ 259,90');
    });
  });

  group('ShopOrder.fromJson', () {
    // Resposta real de POST /shop/orders com 2 unidades.
    const pending = {
      'id': '6d4f5d89-9ae0-4c16-aa72-289d40702869',
      'status': 'pending',
      'total_cents': 9000,
      'checkout_url': '',
      'paid_at': null,
      'canceled_at': null,
      'items': [
        {
          'id': 'ad5dc2e7-63cf-4857-b84b-ed581455a70f',
          'item_id': '73791696-445a-4792-9ce2-acfdc25a6d6b',
          'name': 'Strap de Puxada de Couro',
          'unit_price_cents': 4500,
          'quantity': 2,
          'line_total_cents': 9000,
        },
      ],
      'created_at': '2026-10-01T11:10:53.8934616-03:00',
    };

    test('lê pedido pendente com as linhas', () {
      final order = ShopOrder.fromJson(pending);

      expect(order.id, '6d4f5d89-9ae0-4c16-aa72-289d40702869');
      expect(order.status, 'pending');
      expect(order.isPending, isTrue);
      expect(order.isPaid, isFalse);
      expect(order.totalCents, 9000);
      expect(order.totalLabel, 'R\$ 90,00');
      expect(order.totalQuantity, 2);
      expect(order.statusLabel, 'Aguardando pagamento');
      expect(order.items, hasLength(1));
      expect(order.items.first.name, 'Strap de Puxada de Couro');
      expect(order.items.first.quantity, 2);
      expect(order.items.first.lineTotalLabel, 'R\$ 90,00');
      expect(order.paidAt, isNull);
      expect(order.createdAt, isNotNull);
    });

    test('checkout_url vazia = ainda não há onde pagar', () {
      // while o Stripe não estiver integrado, o app precisa saber que não
      // existe link para abrir — senão mostra um botão que não faz nada.
      expect(ShopOrder.fromJson(pending).hasCheckout, isFalse);
      expect(
        ShopOrder.fromJson({...pending, 'checkout_url': 'https://pay.test/1'})
            .hasCheckout,
        isTrue,
      );
    });

    test('pedido pago e cancelado', () {
      final paid = ShopOrder.fromJson({
        ...pending,
        'status': 'paid',
        'paid_at': '2026-10-01T11:15:00-03:00',
      });
      expect(paid.isPaid, isTrue);
      expect(paid.canBeCanceled, isFalse);
      expect(paid.statusLabel, 'Pago');
      expect(paid.paidAt, isNotNull);

      final canceled = ShopOrder.fromJson({
        ...pending,
        'status': 'canceled',
        'canceled_at': '2026-10-01T11:20:00-03:00',
      });
      expect(canceled.isCanceled, isTrue);
      expect(canceled.canBeCanceled, isFalse);
      expect(canceled.statusLabel, 'Cancelado');
    });

    test('não quebra com JSON incompleto', () {
      final order = ShopOrder.fromJson(const {'id': 'o1'});

      expect(order.id, 'o1');
      expect(order.status, 'pending');
      expect(order.totalCents, 0);
      expect(order.items, isEmpty);
      expect(order.totalQuantity, 0);
    });
  });

  group('InventoryItem.fromJson', () {
    test('mapeia uma linha do GET /shop/inventory', () {
      final item = InventoryItem.fromJson(const {
        'id': 'i1',
        'item_id': 'it1',
        'name': 'Whey Protein Concentrado 1kg',
        'image_url': 'https://example.com/whey.jpg',
        'price_cents': 11990,
        'category': 'Suplementos',
        'rating': 4.9,
        'acquired_at': '2026-10-01T11:15:00-03:00',
      });

      expect(item.itemId, 'it1');
      expect(item.name, 'Whey Protein Concentrado 1kg');
      expect(item.priceCents, 11990);
      expect(item.category, 'Suplementos');
      expect(item.acquiredAt, isNotNull);
    });
  });
}