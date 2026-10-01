/// Modelos da assinatura, cartões e endereços.
/// Espelham os DTOs de `internal/dto/billing_dto.go`.
library;

/// Um plano do catálogo (`GET /plans`). Preço sempre em centavos.
class Plan {
  final String id;
  final String name;
  final String slug;
  final String description;
  final int priceCents;
  final int periodMonths;
  final String badge;
  final String highlight;
  final bool isPopular;
  final List<String> features;

  const Plan({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.priceCents = 0,
    this.periodMonths = 1,
    this.badge = '',
    this.highlight = '',
    this.isPopular = false,
    this.features = const [],
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    id: (json['id'] as String?) ?? '',
    name: (json['name'] as String?) ?? '',
    slug: (json['slug'] as String?) ?? '',
    description: (json['description'] as String?) ?? '',
    priceCents: (json['price_cents'] as num?)?.toInt() ?? 0,
    periodMonths: (json['period_months'] as num?)?.toInt() ?? 1,
    badge: (json['badge'] as String?) ?? '',
    highlight: (json['highlight'] as String?) ?? '',
    isPopular: (json['is_popular'] as bool?) ?? false,
    features: [
      for (final f in (json['features'] as List? ?? const [])) '$f',
    ],
  );

  /// Preço em reais, já no formato brasileiro (2990 -> "29,90").
  String get priceLabel => 'R\$ ${(priceCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  String get periodLabel {
    if (periodMonths == 1) return 'mensal';
    if (periodMonths == 12) return 'anual';
    return 'a cada $periodMonths meses';
  }
}

/// A assinatura ativa do usuário (`GET /users/me/subscription`).
class Subscription {
  final String id;
  final String status;
  final DateTime? startedAt;
  final DateTime? renewsAt;
  final DateTime? canceledAt;
  final bool isCurrent;
  final Plan plan;

  const Subscription({
    required this.id,
    required this.status,
    this.startedAt,
    this.renewsAt,
    this.canceledAt,
    this.isCurrent = false,
    required this.plan,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    id: (json['id'] as String?) ?? '',
    status: (json['status'] as String?) ?? 'active',
    startedAt: DateTime.tryParse(json['started_at'] as String? ?? ''),
    renewsAt: DateTime.tryParse(json['renews_at'] as String? ?? ''),
    canceledAt: DateTime.tryParse(json['canceled_at'] as String? ?? ''),
    // O Go manda is_current (o plano ainda vale). Se o campo não vier —
    // resposta antiga — recalculamos pela mesma regra em vez de assumir que
    // está ativo.
    isCurrent:
        (json['is_current'] as bool?) ??
        (json['status'] == 'active' ||
            ((json['status'] == 'canceled') &&
                DateTime.tryParse(json['renews_at'] as String? ?? '')
                        ?.isAfter(DateTime.now()) ==
                    true)),
    plan: Plan.fromJson(
      Map<String, dynamic>.from((json['plan'] as Map?) ?? const {}),
    ),
  );

  /// O plano está valendo agora (badge "PRO", card de plano ativo).
  bool get isActive => isCurrent;

  /// Cancelada mas ainda dentro do período pago.
  bool get isCanceledButActive =>
      status == 'canceled' && isCurrent && renewsAt != null;

  /// Terminou de vez: cancelada e o período já passou.
  bool get isExpired => status == 'canceled' && !isCurrent;
}

/// Cartão salvo. O backend nunca devolve o número completo.
class PaymentMethod {
  final String id;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final String holderName;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    this.holderName = '',
    this.isDefault = false,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
    id: (json['id'] as String?) ?? '',
    brand: (json['brand'] as String?) ?? '',
    last4: (json['last4'] as String?) ?? '',
    expMonth: (json['exp_month'] as num?)?.toInt() ?? 0,
    expYear: (json['exp_year'] as num?)?.toInt() ?? 0,
    holderName: (json['holder_name'] as String?) ?? '',
    isDefault: (json['is_default'] as bool?) ?? false,
  );

  String get brandLabel {
    switch (brand) {
      case 'visa':
        return 'Visa';
      case 'mastercard':
        return 'Mastercard';
      case 'elo':
        return 'Elo';
      case 'amex':
        return 'American Express';
      default:
        return 'Cartão';
    }
  }

  String get maskedNumber => '•••• $last4';

  String get expiryLabel =>
      '${expMonth.toString().padLeft(2, '0')}/${(expYear % 100).toString().padLeft(2, '0')}';

  bool isExpired(DateTime now) =>
      expYear < now.year || (expYear == now.year && expMonth < now.month);
}

/// Endereço de entrega salvo.
class Address {
  final String id;
  final String label;
  final String recipient;
  final String street;
  final String number;
  final String complement;
  final String zipCode;
  final String city;
  final String state;
  final bool isDefault;

  const Address({
    required this.id,
    this.label = '',
    required this.recipient,
    required this.street,
    required this.number,
    this.complement = '',
    required this.zipCode,
    required this.city,
    required this.state,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: (json['id'] as String?) ?? '',
    label: (json['label'] as String?) ?? '',
    recipient: (json['recipient'] as String?) ?? '',
    street: (json['street'] as String?) ?? '',
    number: (json['number'] as String?) ?? '',
    complement: (json['complement'] as String?) ?? '',
    zipCode: (json['zip_code'] as String?) ?? '',
    city: (json['city'] as String?) ?? '',
    state: (json['state'] as String?) ?? '',
    isDefault: (json['is_default'] as bool?) ?? false,
  );

  /// Linha 1: rua + número (+ complemento).
  String get line1 {
    final base = '$street, $number';
    return complement.isEmpty ? base : '$base - $complement';
  }

  /// Linha 2: CEP, cidade e UF.
  String get line2 {
    final cep = zipCode.length == 8
        ? '${zipCode.substring(0, 5)}-${zipCode.substring(5)}'
        : zipCode;
    return '$cep - $city/$state';
  }
}
