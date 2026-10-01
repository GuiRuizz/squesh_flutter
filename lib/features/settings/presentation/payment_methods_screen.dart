import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_api_service.dart';
import '../domain/billing_models.dart';
import 'settings_providers.dart';
import 'settings_widgets.dart';

/// Lista de cartões salvos + adicionar/editar/apagar. Substitui o tile
/// fictício "Formas de Pagamento" da configuração antiga.
class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  Future<void> _delete(PaymentMethod method) async {
    final confirmed = await confirmSettingsAction(
      context,
      title: 'Apagar cartão',
      message:
          'O cartão ${method.brandLabel} terminado em ${method.last4} será '
          'removido da sua conta. Não dá para desfazer.',
      confirmLabel: 'APAGAR',
    );
    if (!confirmed) return;

    try {
      await ref.read(settingsApiServiceProvider).deletePaymentMethod(method.id);
      ref.invalidate(paymentMethodsProvider);
      if (mounted) showSettingsSnack(context, 'Cartão apagado.');
    } catch (e) {
      if (mounted) showSettingsSnack(context, describeError(e), error: true);
    }
  }

  Future<void> _makeDefault(PaymentMethod method) async {
    try {
      await ref
          .read(settingsApiServiceProvider)
          .updatePaymentMethod(method.id, isDefault: true);
      ref.invalidate(paymentMethodsProvider);
      if (mounted) showSettingsSnack(context, 'Cartão padrão atualizado.');
    } catch (e) {
      if (mounted) showSettingsSnack(context, describeError(e), error: true);
    }
  }

  Future<void> _openForm({PaymentMethod? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SettingsColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: settingsSheetRadius),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: _PaymentMethodForm(
          existing: existing,
          onSubmit: (values) async {
            try {
              final api = ref.read(settingsApiServiceProvider);
              if (existing == null) {
                await api.addPaymentMethod(
                  cardNumber: values.cardNumber,
                  expMonth: values.expMonth,
                  expYear: values.expYear,
                  holderName: values.holderName,
                  isDefault: values.isDefault,
                );
              } else {
                // O número do cartão nunca volta da API, então a edição só
                // permite mexer em validade, titular e "principal".
                await api.updatePaymentMethod(
                  existing.id,
                  expMonth: values.expMonth,
                  expYear: values.expYear,
                  holderName: values.holderName,
                  isDefault: values.isDefault ? true : null,
                );
              }
              ref.invalidate(paymentMethodsProvider);
              if (!mounted) return false;
              showSettingsSnack(
                context,
                existing == null ? 'Cartão salvo!' : 'Cartão atualizado!',
              );
              return true;
            } catch (e) {
              if (!mounted) return false;
              showSettingsSnack(context, describeError(e), error: true);
              return false;
            }
          },
        ),
      ),
    );
    if (saved == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor: SettingsColors.background,
      appBar: const SettingsAppBar('FORMAS DE PAGAMENTO'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: SettingsColors.accent,
        foregroundColor: SettingsColors.textPrimary,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('NOVO CARTÃO'),
      ),
      body: RefreshIndicator(
        color: SettingsColors.accent,
        backgroundColor: SettingsColors.surface,
        onRefresh: () async => ref.invalidate(paymentMethodsProvider),
        child: methodsAsync.when(
          loading: () => const SettingsLoading(),
          error: (error, _) => SettingsErrorView(
            message: describeError(error),
            onRetry: () => ref.invalidate(paymentMethodsProvider),
          ),
          data: (methods) {
            if (methods.isEmpty) {
              return SettingsEmptyView(
                icon: Icons.credit_card_rounded,
                title: 'Nenhum cartão salvo',
                message:
                    'Cadastre um cartão para assinar os planos Pro mais '
                    'depois. Guardamos só a bandeira e os 4 últimos dígitos.',
                actionLabel: 'ADICIONAR CARTÃO',
                onAction: () => _openForm(),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const SettingsSectionHeader('MEUS CARTÕES'),
                for (final method in methods)
                  _PaymentMethodCard(
                    method: method,
                    onEdit: () => _openForm(existing: method),
                    onDelete: () => _delete(method),
                    onMakeDefault: method.isDefault
                        ? null
                        : () => _makeDefault(method),
                  ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: SettingsColors.textFaint,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Número completo nunca é salvo — só a bandeira e '
                        'os 4 últimos dígitos.',
                        style: TextStyle(
                          color: SettingsColors.textFaint,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethod method;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMakeDefault;

  const _PaymentMethodCard({
    required this.method,
    required this.onEdit,
    required this.onDelete,
    this.onMakeDefault,
  });

  @override
  Widget build(BuildContext context) {
    final expired = method.isExpired(DateTime.now());

    return SettingsCard(
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: method.isDefault
          ? SettingsColors.accent
          : SettingsColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _brandIcon(method.brand),
                color: SettingsColors.textPrimary,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${method.brandLabel} ${method.maskedNumber}',
                      style: const TextStyle(
                        color: SettingsColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Validade ${method.expiryLabel}'
                      '${method.holderName.isEmpty ? '' : ' • ${method.holderName}'}',
                      style: TextStyle(
                        color: expired
                            ? SettingsColors.accent
                            : SettingsColors.textFaint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (method.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: SettingsColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRINCIPAL',
                    style: TextStyle(
                      color: SettingsColors.textPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onMakeDefault != null)
                TextButton(
                  onPressed: onMakeDefault,
                  child: const Text(
                    'Tornar principal',
                    style: TextStyle(
                      color: SettingsColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: SettingsColors.textMuted,
                ),
                tooltip: 'Editar',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: SettingsColors.accent,
                ),
                tooltip: 'Apagar',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _brandIcon(String brand) {
    switch (brand) {
      case 'mastercard':
        return Icons.circle;
      case 'amex':
        return Icons.credit_score_rounded;
      case 'elo':
        return Icons.account_balance_rounded;
      default:
        return Icons.credit_card_rounded;
    }
  }
}

/// Valores que o formulário de cartão devolve.
class _CardValues {
  final String cardNumber;
  final int expMonth;
  final int expYear;
  final String holderName;
  final bool isDefault;

  const _CardValues({
    required this.cardNumber,
    required this.expMonth,
    required this.expYear,
    required this.holderName,
    required this.isDefault,
  });
}

class _PaymentMethodForm extends StatefulWidget {
  final PaymentMethod? existing;
  final Future<bool> Function(_CardValues values) onSubmit;

  const _PaymentMethodForm({
    required this.existing,
    required this.onSubmit,
  });

  @override
  State<_PaymentMethodForm> createState() => _PaymentMethodFormState();
}

class _PaymentMethodFormState extends State<_PaymentMethodForm> {
  late final TextEditingController _number;
  late final TextEditingController _month;
  late final TextEditingController _year;
  late final TextEditingController _holder;
  late bool _isDefault;

  // O busy mora aqui, e não no State da tela: a folha inferior não
  // reconstrói quando o pai faz setState, então o botão ficaria clicável
  // durante o envio e um toque duplo criaria dois cartões.
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final card = widget.existing;
    _number = TextEditingController();
    _month = TextEditingController(
      text: card == null ? '' : card.expMonth.toString().padLeft(2, '0'),
    );
    _year = TextEditingController(
      text: card == null ? '' : (card.expYear % 100).toString().padLeft(2, '0'),
    );
    _holder = TextEditingController(text: card?.holderName ?? '');
    _isDefault = card?.isDefault ?? false;
  }

  @override
  void dispose() {
    _number.dispose();
    _month.dispose();
    _year.dispose();
    _holder.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final editing = widget.existing != null;
    if (_busy) return;

    final digits = _number.text.replaceAll(RegExp(r'\D'), '');
    final month = int.tryParse(_month.text.trim());
    final year = int.tryParse(_year.text.trim());

    // Na edição o número não é exigido: o backend nunca devolve, então o campo
    // nem aparece e o que vale é a validade.
    if (!editing && (digits.length < 13 || digits.length > 19)) {
      setState(() => _error = 'Número de cartão incompleto.');
      return;
    }
    if (month == null || month < 1 || month > 12) {
      setState(() => _error = 'Mês de validade inválido (01 a 12).');
      return;
    }
    if (year == null || year < 0 || year > 99) {
      setState(() => _error = 'Ano de validade inválido.');
      return;
    }

    final fullYear = year < 100 ? 2000 + year : year;
    final now = DateTime.now();
    if (fullYear < now.year ||
        (fullYear == now.year && month < now.month)) {
      setState(() => _error = 'Esse cartão já venceu.');
      return;
    }

    setState(() {
      _error = null;
      _busy = true;
    });

    final ok = await widget.onSubmit(
      _CardValues(
        cardNumber: digits,
        expMonth: month,
        expYear: fullYear,
        holderName: _holder.text.trim(),
        isDefault: _isDefault,
      ),
    );

    // onSubmit pode ter devolvido false porque a tela foi desmontada; nesse
    // caso não há mais nada a fazer aqui.
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            editing ? 'EDITAR CARTÃO' : 'NOVO CARTÃO',
            style: const TextStyle(
              color: SettingsColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 17,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          if (!editing) ...[
            SettingsTextField(
              controller: _number,
              label: 'Número do cartão',
              hint: '4111 1111 1111 1111',
              keyboardType: TextInputType.number,
              maxLength: 19,
              helperText: 'Visa, Mastercard, Elo ou American Express',
            ),
            const SizedBox(height: 12),
          ] else ...[
            SettingsCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.credit_card_rounded,
                    color: SettingsColors.textPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${widget.existing!.brandLabel} '
                      '${widget.existing!.maskedNumber}',
                      style: const TextStyle(
                        color: SettingsColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Para trocar o cartão, apague este e cadastre o novo.',
              style: TextStyle(color: SettingsColors.textFaint, fontSize: 11),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: SettingsTextField(
                  controller: _month,
                  label: 'Mês',
                  hint: '12',
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SettingsTextField(
                  controller: _year,
                  label: 'Ano',
                  hint: '30',
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SettingsTextField(
            controller: _holder,
            label: 'Nome impresso no cartão',
            hint: 'Como está no cartão',
          ),
          SwitchListTile(
            value: _isDefault,
            onChanged: (value) => setState(() => _isDefault = value),
            activeThumbColor: SettingsColors.accent,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Usar como cartão principal',
              style: TextStyle(color: SettingsColors.textPrimary, fontSize: 14),
            ),
          ),
          if (_error != null) SettingsErrorText(_error!),
          const SizedBox(height: 16),
          SettingsPrimaryButton(
            label: editing ? 'SALVAR' : 'ADICIONAR CARTÃO',
            busy: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}