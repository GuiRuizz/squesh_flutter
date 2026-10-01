import 'package:flutter/material.dart';

import 'plan_widgets.dart';
import 'settings_widgets.dart';

/// Vitrine de planos + assinatura atual. É a tela que substitui o tile
/// fictício "Plano Pro Ativo".
///
/// O conteúdo é o [PlansShowcase] compartilhado com a aba "Planos" da Loja —
/// aqui é só a casca com a AppBar.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: SettingsColors.background,
      appBar: SettingsAppBar('ASSINATURA E PLANOS'),
      body: PlansShowcase(),
    );
  }
}