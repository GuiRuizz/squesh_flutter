import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Tom do aviso flutuante. O formato (bolha flutuante com halo) é sempre o
/// mesmo; o que muda é o acento e o ícone.
enum AppSnackStyle { error, success, info }

/// Cor do texto do ícone, por tom.
Color _iconColor(AppSnackStyle style) => switch (style) {
  AppSnackStyle.error => AppTheme.crimsonAccent,
  AppSnackStyle.success => const Color(0xFF4ADE80),
  AppSnackStyle.info => AppTheme.textMain,
};

IconData _iconFor(AppSnackStyle style) => switch (style) {
  AppSnackStyle.error => Icons.error_outline_rounded,
  AppSnackStyle.success => Icons.check_circle_outline_rounded,
  AppSnackStyle.info => Icons.info_outline_rounded,
};

/// Aviso flutuante padrão do App: "liquid neon" vermelho.
///
/// Flutua acima de tudo (`SnackBarBehavior.floating`) e troca a cor de fundo
/// padrão por um balão escuro translúcido com gradiente carmim, borda acesa e
/// halo vermelho pulsando devagar (o "neon" líquido). Use sempre esta função
/// em vez de `ScaffoldMessenger.showSnackBar(SnackBar(...))` para o aviso
/// ficar igual em todas as telas.
void showAppSnack(
  BuildContext context,
  String message, {
  AppSnackStyle style = AppSnackStyle.error,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    // Fila de uma vez só: um aviso novo substitui o que ainda estava na tela.
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: _NeonSnackBody(
          message: message,
          style: style,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // O balão já tem margem desenhada no próprio corpo; aqui só o recuo
        // mínimo exigido pelo Material.
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        width: null,
        duration: duration,
        // Sem isso o Material desenha a sombra padrão em volta do SnackBar,
        // que brigaria com o halo do balão.
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
}

/// Corpo do aviso: bolha com gradiente, brilho interno e halo pulsante.
class _NeonSnackBody extends StatefulWidget {
  const _NeonSnackBody({
    required this.message,
    required this.style,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppSnackStyle style;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_NeonSnackBody> createState() => _NeonSnackBodyState();
}

class _NeonSnackBodyState extends State<_NeonSnackBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _iconColor(widget.style);
    // Halo: forte no meio da animação, quase apagado no fim, como um neon.
    final glow = 0.35 + 0.65 * _pulse.value;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final keyboardOpen = viewInsets.bottom > 0;

    return Padding(
      // Com o teclado aberto o Material já empurra o SnackBar para cima; o
      // recuo extra aqui só atrapalharia a leitura.
      padding: EdgeInsets.fromLTRB(16, 0, 16, keyboardOpen ? 0 : 18),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            // Fundo "líquido": quase preto no topo, carmim translúcido embaixo.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF16060A).withValues(alpha: 0.96),
                const Color(0xFF3A0A14).withValues(alpha: 0.94),
                const Color(0xFF5E0F1D).withValues(alpha: 0.92),
              ],
              stops: const [0, 0.55, 1],
            ),
            border: Border.all(
              color: AppTheme.crimsonAccent.withValues(alpha: 0.35 + 0.35 * glow),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.crimsonRed.withValues(alpha: 0.55 * glow),
                blurRadius: 26 * glow,
                spreadRadius: 1.5 * glow,
                offset: const Offset(0, 6),
              ),
              // Contorno escuro para o balão se destacar de qualquer fundo.
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                  border: Border.all(color: accent.withValues(alpha: 0.45)),
                ),
                child: Icon(_iconFor(widget.style), color: accent, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: AppTheme.textMain,
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (widget.actionLabel != null && widget.onAction != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: widget.onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.crimsonAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    widget.actionLabel!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
