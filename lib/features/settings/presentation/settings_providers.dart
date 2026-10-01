import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_api_service.dart';
import '../domain/billing_models.dart';

/// Cada tela de Configurações tem seu provider: a tela principal só lê as
/// contagens, e quem altera (assinar, apagar cartão) invalida o seu para
/// voltar a buscar da API.

final plansProvider = FutureProvider<List<Plan>>((ref) {
  return ref.read(settingsApiServiceProvider).getPlans();
});

final subscriptionProvider = FutureProvider<Subscription?>((ref) {
  return ref.read(settingsApiServiceProvider).getSubscription();
});

final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) {
  return ref.read(settingsApiServiceProvider).getPaymentMethods();
});

final addressesProvider = FutureProvider<List<Address>>((ref) {
  return ref.read(settingsApiServiceProvider).getAddresses();
});
