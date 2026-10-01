import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Paleta e estilos reaproveitados pelas telas de Configurações.
/// Antes cada tela repetia os mesmos literais; agora ficam num lugar só.
abstract final class SettingsColors {
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF141414);
  static const surfaceAlt = Color(0xFF1F1F1F);
  static const border = Color(0xFF222222);
  static const divider = Color(0xFF262626);
  static const accent = Color(0xFFFF1E40);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFCCCCCC);
  static const textMuted = Color(0xFF888888);
  static const textFaint = Color(0xFF666666);
}

/// Cabeçalho de seção ("PREFERÊNCIAS", "CONTA"...).
class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: SettingsColors.textFaint,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Card com borda usado por linhas, avisos e formulários.
class SettingsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color borderColor;

  const SettingsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderColor = SettingsColors.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: SettingsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

/// Linha de menu com ícone, título, subtítulo e chevron.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingText;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: SettingsColors.accent),
        title: Text(
          title,
          style: const TextStyle(
            color: SettingsColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: SettingsColors.textFaint,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SettingsColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trailingText!,
                  style: const TextStyle(
                    color: SettingsColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Icon(
              Icons.chevron_right_rounded,
              color: SettingsColors.textFaint,
            ),
          ],
        ),
      ),
    );
  }
}

/// Switch de preferência, com subtítulo e estado desabilitado.
class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: SettingsColors.accent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: TextStyle(
          color: enabled
              ? SettingsColors.textPrimary
              : SettingsColors.textFaint,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: SettingsColors.textFaint,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// AppBar padrão das sub-telas de Configurações.
class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const SettingsAppBar(this.title, {super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: SettingsColors.surface,
      elevation: 0,
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: SettingsColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 15,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Campo de texto escuro pronto para os formulários.
class SettingsTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int? maxLength;
  final int maxLines;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final String? helperText;
  final ValueChanged<String>? onChanged;

  const SettingsTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.sentences,
    this.obscureText = false,
    this.helperText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      onChanged: onChanged,
      style: const TextStyle(
        color: SettingsColors.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        helperStyle: const TextStyle(
          color: SettingsColors.textFaint,
          fontSize: 11,
        ),
        counterStyle: const TextStyle(
          color: SettingsColors.textFaint,
          fontSize: 11,
        ),
        labelStyle: const TextStyle(color: SettingsColors.textMuted),
        hintStyle: const TextStyle(color: SettingsColors.textFaint),
        filled: true,
        fillColor: SettingsColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SettingsColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: SettingsColors.accent),
        ),
      ),
    );
  }
}

/// Botão principal (usado nos formulários das sub-telas).
class SettingsPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  const SettingsPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: SettingsColors.accent,
          disabledBackgroundColor: SettingsColors.surfaceAlt,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SettingsColors.textPrimary,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: SettingsColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}

/// Aviso de erro dentro de um formulário (aparece abaixo do campo problemático).
class SettingsErrorText extends StatelessWidget {
  final String message;

  const SettingsErrorText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SettingsColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SettingsColors.accent.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: SettingsColors.accent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: SettingsColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Raio padrão das folhas inferiores de Configurações.
const BorderRadius settingsSheetRadius = BorderRadius.vertical(
  top: Radius.circular(20),
);

/// Mostra um SnackBar no tema escuro.
void showSettingsSnack(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? const Color(0xFF7A1024)
            : SettingsColors.surfaceAlt,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// Texto de erro legível para o usuário.
///
/// O Go responde `{"error": "mensagem em português"}` em praticamente todos os
/// handlers, então usamos essa mensagem quando existe (é específica: "Cartao
/// vencido", "Nome nao pode ficar vazio"). Só caímos nos genéricos quando a
/// resposta não tem `error` — normalmente é o túnel USB caiu, que nem chega
/// a ter status.
String describeError(Object error) {
  if (error is! DioException) {
    return 'Não foi possível concluir. Tente de novo.';
  }

  final status = error.response?.statusCode;
  final data = error.response?.data;

  if (data is Map && data['error'] is String) {
    final message = (data['error'] as String).trim();
    if (message.isNotEmpty) return message;
  }

  switch (status) {
    case 400:
      return 'Dados inválidos. Revise os campos.';
    case 401:
      return 'Sessão expirada. Entre de novo.';
    case 403:
      return 'Você não tem permissão para isso.';
    case 404:
      return 'Não encontramos o que você procurou.';
    case null:
      // Sem resposta: a rede ou o túnel USB caíram antes de chegar no Go.
      return 'Sem conexão com o servidor. O túnel USB caiu?';
    default:
      return 'Não foi possível concluir. Tente de novo.';
  }
}

/// Avatar circular: usa a foto quando existe, senão cai nas iniciais.
///
/// Sem foto nenhuma a tela mostrava um pravatar.cc fixo — era a imagem de
/// outra pessoa. Agora é sempre o usuário real ou as iniciais dele.
class ProfileAvatar extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl.trim();

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty ? _initials() : _image(url),
      ),
    );
  }

  Widget _initials() {
    final parts = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    final letters = parts.isEmpty
        ? '?'
        : (parts.length == 1
              ? parts.first.substring(0, 1)
              : '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}');

    return Container(
      color: SettingsColors.surfaceAlt,
      alignment: Alignment.center,
      child: Text(
        letters.toUpperCase(),
        style: TextStyle(
          color: SettingsColors.textSecondary,
          fontSize: size * 0.34,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _image(String url) {
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      // Avatar quebrado não pode virar ícone quebrado na tela de perfil.
      errorBuilder: (_, _, _) => _initials(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: SettingsColors.surfaceAlt,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}

/// Data no formato dd/MM/aaaa (ou "—" quando não há data).
///
/// O Go manda timestamp em UTC; sem o toLocal() uma renovação marcada para
/// 00:30 do dia 30 aparecia como dia 29 para quem está no Brasil.
String formatDate(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

/// Tela de carregamento padrão das sub-telas.
class SettingsLoading extends StatelessWidget {
  const SettingsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: SettingsColors.accent),
    );
  }
}

/// Erro de carregamento com botão de tentar de novo.
class SettingsErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SettingsErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        const Icon(
          Icons.cloud_off_rounded,
          size: 44,
          color: SettingsColors.textFaint,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SettingsColors.textMuted,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tentar de novo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: SettingsColors.accent,
              side: const BorderSide(color: SettingsColors.accent),
            ),
          ),
        ),
      ],
    );
  }
}

/// Estado vazio com texto e (opcionalmente) uma ação.
class SettingsEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SettingsEmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: SettingsColors.textFaint),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: SettingsColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SettingsColors.textFaint,
                fontSize: 12,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                child: SettingsPrimaryButton(
                  label: actionLabel!,
                  onPressed: onAction,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Diálogo de confirmação no tema escuro. Devolve true só quando o usuário
/// confirmar — usado em todas as ações destrutivas (apagar cartão, endereço,
/// cancelar assinatura, sair da conta).
Future<bool> confirmSettingsAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'VOLTAR',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: SettingsColors.surface,
      title: Text(
        title,
        style: const TextStyle(
          color: SettingsColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(
          color: SettingsColors.textSecondary,
          fontSize: 13,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(
            cancelLabel,
            style: const TextStyle(color: SettingsColors.textMuted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: destructive
                  ? SettingsColors.accent
                  : SettingsColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
