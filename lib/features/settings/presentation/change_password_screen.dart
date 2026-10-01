import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/user_api_service.dart';
import 'settings_widgets.dart';

/// Troca de senha via PATCH /users/me/password (o Go exige a senha atual).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final next = _next.text;
    if (next.length < 6) {
      setState(() => _error = 'A nova senha precisa de pelo menos 6 caracteres.');
      return;
    }
    if (next != _confirm.text) {
      setState(() => _error = 'A confirmação não bate com a nova senha.');
      return;
    }
    if (next == _current.text) {
      setState(() => _error = 'A nova senha precisa ser diferente da atual.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(userApiServiceProvider).updatePassword(
        currentPassword: _current.text,
        newPassword: next,
      );
      if (!mounted) return;
      showSettingsSnack(context, 'Senha alterada! 🔒');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsColors.background,
      appBar: const SettingsAppBar('ALTERAR SENHA'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const SettingsCard(
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: SettingsColors.accent),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Precisamos da sua senha atual para confirmar que você é '
                    'mesmo quem está logado.',
                    style: TextStyle(
                      color: SettingsColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SettingsTextField(
            controller: _current,
            label: 'Senha atual',
            obscureText: _hide,
          ),
          const SizedBox(height: 12),
          SettingsTextField(
            controller: _next,
            label: 'Nova senha',
            obscureText: _hide,
            helperText: 'Mínimo de 6 caracteres',
          ),
          const SizedBox(height: 12),
          SettingsTextField(
            controller: _confirm,
            label: 'Confirmar nova senha',
            obscureText: _hide,
          ),
          SwitchListTile(
            value: !_hide,
            onChanged: (value) => setState(() => _hide = !value),
            activeThumbColor: SettingsColors.accent,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Mostrar senhas',
              style: TextStyle(color: SettingsColors.textPrimary, fontSize: 13),
            ),
          ),
          if (_error != null) SettingsErrorText(_error!),
          const SizedBox(height: 16),
          SettingsPrimaryButton(
            label: 'ALTERAR SENHA',
            busy: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}