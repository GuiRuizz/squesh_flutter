import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../domain/billing_models.dart';

final settingsApiServiceProvider = Provider<SettingsApiService>((ref) {
  return SettingsApiService(ref.watch(dioProvider));
});

/// Assinatura, cartões e endereços da tela de Configurações.
class SettingsApiService {
  final Dio _dio;

  SettingsApiService(this._dio);

  // ------------------------------------------------------------- planos

  /// GET /plans — catálogo público.
  Future<List<Plan>> getPlans() async {
    final response = await _dio.get(ApiEndpoints.plans);
    final data = response.data;
    if (data is! List) return const [];
    return [
      for (final item in data) Plan.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  // -------------------------------------------------------- assinatura

  /// GET /users/me/subscription — devolve null quando não há assinatura.
  Future<Subscription?> getSubscription() async {
    final response = await _dio.get(ApiEndpoints.userSubscription);
    final raw = (response.data as Map)['subscription'];
    if (raw is! Map) return null;
    return Subscription.fromJson(Map<String, dynamic>.from(raw));
  }

  /// POST /users/me/subscription — contrata o plano (ou troca o atual).
  Future<Subscription> subscribe(String planId) async {
    final response = await _dio.post(
      ApiEndpoints.userSubscription,
      data: {'plan_id': planId},
    );
    return Subscription.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// DELETE /users/me/subscription
  Future<void> cancelSubscription() async {
    await _dio.delete(ApiEndpoints.userSubscription);
  }

  // ------------------------------------------------- formas de pagamento

  Future<List<PaymentMethod>> getPaymentMethods() async {
    final response = await _dio.get(ApiEndpoints.userPaymentMethods);
    final data = response.data;
    if (data is! List) return const [];
    return [
      for (final item in data)
        PaymentMethod.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  /// POST /users/me/payment-methods. Só os 4 últimos dígitos ficam salvos.
  Future<PaymentMethod> addPaymentMethod({
    required String cardNumber,
    required int expMonth,
    required int expYear,
    String holderName = '',
    bool isDefault = false,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.userPaymentMethods,
      data: {
        'card_number': cardNumber,
        'exp_month': expMonth,
        'exp_year': expYear,
        'holder_name': holderName,
        'is_default': isDefault,
      },
    );
    return PaymentMethod.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// PUT /users/me/payment-methods/:id
  Future<PaymentMethod> updatePaymentMethod(
    String id, {
    int? expMonth,
    int? expYear,
    String? holderName,
    bool? isDefault,
  }) async {
    final body = <String, dynamic>{};
    if (expMonth != null) body['exp_month'] = expMonth;
    if (expYear != null) body['exp_year'] = expYear;
    if (holderName != null && holderName.isNotEmpty) {
      body['holder_name'] = holderName;
    }
    if (isDefault != null) body['is_default'] = isDefault;

    final response = await _dio.put(
      ApiEndpoints.userPaymentMethod(id),
      data: body,
    );
    return PaymentMethod.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> deletePaymentMethod(String id) async {
    await _dio.delete(ApiEndpoints.userPaymentMethod(id));
  }

  // --------------------------------------------------------- enderecos

  Future<List<Address>> getAddresses() async {
    final response = await _dio.get(ApiEndpoints.userAddresses);
    final data = response.data;
    if (data is! List) return const [];
    return [
      for (final item in data)
        Address.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  Future<Address> addAddress({
    required String recipient,
    required String street,
    required String number,
    String complement = '',
    required String zipCode,
    required String city,
    required String state,
    String label = '',
    bool isDefault = false,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.userAddresses,
      data: {
        'recipient': recipient,
        'street': street,
        'number': number,
        'complement': complement,
        'zip_code': zipCode,
        'city': city,
        'state': state,
        'label': label,
        'is_default': isDefault,
      },
    );
    return Address.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Address> updateAddress(
    String id, {
    String? label,
    String? recipient,
    String? street,
    String? number,
    String? complement,
    String? zipCode,
    String? city,
    String? state,
    bool? isDefault,
  }) async {
    final body = <String, dynamic>{};
    if (label != null) body['label'] = label;
    if (recipient != null) body['recipient'] = recipient;
    if (street != null) body['street'] = street;
    if (number != null) body['number'] = number;
    if (complement != null) body['complement'] = complement;
    if (zipCode != null) body['zip_code'] = zipCode;
    if (city != null) body['city'] = city;
    if (state != null) body['state'] = state;
    if (isDefault != null) body['is_default'] = isDefault;

    final response = await _dio.put(ApiEndpoints.userAddress(id), data: body);
    return Address.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteAddress(String id) async {
    await _dio.delete(ApiEndpoints.userAddress(id));
  }
}
