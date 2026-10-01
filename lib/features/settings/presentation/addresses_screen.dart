import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_api_service.dart';
import '../domain/billing_models.dart';
import 'settings_providers.dart';
import 'settings_widgets.dart';

/// Endereços de entrega: lista, adiciona, edita, apaga e marca o principal.
/// Substitui o tile fictício que mostrava "2 endereços" sem nada no banco.
class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  Future<void> _delete(Address address) async {
    final confirmed = await confirmSettingsAction(
      context,
      title: 'Apagar endereço',
      message:
          '"${address.line1}" será removido dos seus endereços. '
          'Não dá para desfazer.',
      confirmLabel: 'APAGAR',
    );
    if (!confirmed) return;

    try {
      await ref.read(settingsApiServiceProvider).deleteAddress(address.id);
      ref.invalidate(addressesProvider);
      if (mounted) showSettingsSnack(context, 'Endereço apagado.');
    } catch (e) {
      if (mounted) showSettingsSnack(context, describeError(e), error: true);
    }
  }

  Future<void> _makeDefault(Address address) async {
    try {
      await ref
          .read(settingsApiServiceProvider)
          .updateAddress(address.id, isDefault: true);
      ref.invalidate(addressesProvider);
      if (mounted) showSettingsSnack(context, 'Endereço principal atualizado.');
    } catch (e) {
      if (mounted) showSettingsSnack(context, describeError(e), error: true);
    }
  }

  Future<void> _openForm({Address? existing}) async {
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
        child: _AddressForm(
          existing: existing,
          onSubmit: (values) async {
            try {
              final api = ref.read(settingsApiServiceProvider);
              if (existing == null) {
                await api.addAddress(
                  recipient: values.recipient,
                  street: values.street,
                  number: values.number,
                  complement: values.complement,
                  zipCode: values.zipCode,
                  city: values.city,
                  state: values.state,
                  label: values.label,
                  isDefault: values.isDefault,
                );
              } else {
                await api.updateAddress(
                  existing.id,
                  label: values.label,
                  recipient: values.recipient,
                  street: values.street,
                  number: values.number,
                  complement: values.complement,
                  zipCode: values.zipCode,
                  city: values.city,
                  state: values.state,
                  isDefault: values.isDefault ? true : null,
                );
              }
              ref.invalidate(addressesProvider);
              if (!mounted) return false;
              showSettingsSnack(
                context,
                existing == null ? 'Endereço salvo!' : 'Endereço atualizado!',
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
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      backgroundColor: SettingsColors.background,
      appBar: const SettingsAppBar('ENDEREÇOS DE ENTREGA'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: SettingsColors.accent,
        foregroundColor: SettingsColors.textPrimary,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('NOVO ENDEREÇO'),
      ),
      body: RefreshIndicator(
        color: SettingsColors.accent,
        backgroundColor: SettingsColors.surface,
        onRefresh: () async => ref.invalidate(addressesProvider),
        child: addressesAsync.when(
          loading: () => const SettingsLoading(),
          error: (error, _) => SettingsErrorView(
            message: describeError(error),
            onRetry: () => ref.invalidate(addressesProvider),
          ),
          data: (addresses) {
            if (addresses.isEmpty) {
              return SettingsEmptyView(
                icon: Icons.location_on_outlined,
                title: 'Nenhum endereço salvo',
                message:
                    'Cadastre onde quer receber seus pedidos. O primeiro '
                    'vira o principal automaticamente.',
                actionLabel: 'ADICIONAR ENDEREÇO',
                onAction: () => _openForm(),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const SettingsSectionHeader('MEUS ENDEREÇOS'),
                for (final address in addresses)
                  _AddressCard(
                    address: address,
                    onEdit: () => _openForm(existing: address),
                    onDelete: () => _delete(address),
                    onMakeDefault: address.isDefault
                        ? null
                        : () => _makeDefault(address),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMakeDefault;

  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
    this.onMakeDefault,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: address.isDefault
          ? SettingsColors.accent
          : SettingsColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (address.label.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: SettingsColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: SettingsColors.divider),
                  ),
                  child: Text(
                    address.label,
                    style: const TextStyle(
                      color: SettingsColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  address.recipient,
                  style: const TextStyle(
                    color: SettingsColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (address.isDefault)
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
          Text(
            address.line1,
            style: const TextStyle(
              color: SettingsColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            address.line2,
            style: const TextStyle(
              color: SettingsColors.textFaint,
              fontSize: 12,
            ),
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
}

class _AddressValues {
  final String label;
  final String recipient;
  final String street;
  final String number;
  final String complement;
  final String zipCode;
  final String city;
  final String state;
  final bool isDefault;

  const _AddressValues({
    required this.label,
    required this.recipient,
    required this.street,
    required this.number,
    required this.complement,
    required this.zipCode,
    required this.city,
    required this.state,
    required this.isDefault,
  });
}

class _AddressForm extends StatefulWidget {
  final Address? existing;
  final Future<bool> Function(_AddressValues values) onSubmit;

  const _AddressForm({
    required this.existing,
    required this.onSubmit,
  });

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  late final TextEditingController _label;
  late final TextEditingController _recipient;
  late final TextEditingController _street;
  late final TextEditingController _number;
  late final TextEditingController _complement;
  late final TextEditingController _zip;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late bool _isDefault;

  // Ver comentário equivalente em payment_methods_screen.dart: o busy precisa
  // viver no formulário, senão o botão fica clicável durante o envio.
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final address = widget.existing;
    _label = TextEditingController(text: address?.label ?? '');
    _recipient = TextEditingController(text: address?.recipient ?? '');
    _street = TextEditingController(text: address?.street ?? '');
    _number = TextEditingController(text: address?.number ?? '');
    _complement = TextEditingController(text: address?.complement ?? '');
    // O backend guarda o CEP só com dígitos, então é isso que volta.
    _zip = TextEditingController(
      text: address == null || address.zipCode.length != 8
          ? address?.zipCode ?? ''
          : '${address.zipCode.substring(0, 5)}-${address.zipCode.substring(5)}',
    );
    _city = TextEditingController(text: address?.city ?? '');
    _state = TextEditingController(text: address?.state ?? '');
    _isDefault = address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _recipient.dispose();
    _street.dispose();
    _number.dispose();
    _complement.dispose();
    _zip.dispose();
    _city.dispose();
    _state.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;

    final state = _state.text.trim().toUpperCase();
    if (state.length != 2) {
      setState(() => _error = 'UF precisa ter 2 letras (ex.: SP).');
      return;
    }

    final required = <String, String>{
      'Nome de quem recebe': _recipient.text,
      'Rua': _street.text,
      'Número': _number.text,
      'Cidade': _city.text,
    };
    for (final entry in required.entries) {
      if (entry.value.trim().isEmpty) {
        setState(() => _error = '${entry.key} é obrigatório.');
        return;
      }
    }

    final zipDigits = _zip.text.replaceAll(RegExp(r'\D'), '');
    if (zipDigits.length != 8) {
      setState(() => _error = 'CEP incompleto (8 dígitos).');
      return;
    }

    setState(() {
      _error = null;
      _busy = true;
    });

    final ok = await widget.onSubmit(
      _AddressValues(
        label: _label.text.trim(),
        recipient: _recipient.text.trim(),
        street: _street.text.trim(),
        number: _number.text.trim(),
        complement: _complement.text.trim(),
        zipCode: zipDigits,
        city: _city.text.trim(),
        state: state,
        isDefault: _isDefault,
      ),
    );

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
            editing ? 'EDITAR ENDEREÇO' : 'NOVO ENDEREÇO',
            style: const TextStyle(
              color: SettingsColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 17,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          SettingsTextField(
            controller: _label,
            label: 'Apelido (opcional)',
            hint: 'Casa, Trabalho...',
            maxLength: 40,
          ),
          const SizedBox(height: 12),
          SettingsTextField(
            controller: _recipient,
            label: 'Nome de quem recebe',
            maxLength: 100,
          ),
          const SizedBox(height: 12),
          SettingsTextField(
            controller: _street,
            label: 'Rua / Logradouro',
            maxLength: 150,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SettingsTextField(
                  controller: _number,
                  label: 'Número',
                  maxLength: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: SettingsTextField(
                  controller: _complement,
                  label: 'Complemento',
                  hint: 'Apto, bloco...',
                  maxLength: 120,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SettingsTextField(
                  controller: _zip,
                  label: 'CEP',
                  hint: '01310-100',
                  keyboardType: TextInputType.number,
                  maxLength: 9,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 88,
                child: SettingsTextField(
                  controller: _state,
                  label: 'UF',
                  maxLength: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SettingsTextField(
            controller: _city,
            label: 'Cidade',
            maxLength: 80,
          ),
          SwitchListTile(
            value: _isDefault,
            onChanged: (value) => setState(() => _isDefault = value),
            activeThumbColor: SettingsColors.accent,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Usar como endereço principal',
              style: TextStyle(color: SettingsColors.textPrimary, fontSize: 14),
            ),
          ),
          if (_error != null) SettingsErrorText(_error!),
          const SizedBox(height: 16),
          SettingsPrimaryButton(
            label: editing ? 'SALVAR' : 'ADICIONAR ENDEREÇO',
            busy: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}