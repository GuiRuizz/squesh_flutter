import 'package:flutter/material.dart';
import '../app/theme/app_theme.dart';

class PathConnectorPainter extends CustomPainter {
  final int nodeCount;
  final List<bool> completedStates; // Estado de conclusão de cada nó

  PathConnectorPainter({
    required this.nodeCount,
    required this.completedStates,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeCount <= 1) return;

    // Altura aproximada de cada nó + espaçamento vertical
    const double itemHeight = 104.0;
    const double nodeRadius = 36.0;

    for (int i = 0; i < nodeCount - 1; i++) {
      final isCompleted = i < completedStates.length && completedStates[i];

      // Definição das tintas (Linha principal e Brilho Neon)
      final paintLine = Paint()
        ..color = isCompleted ? AppTheme.crimsonRed : const Color(0xFF2A2A2A)
        ..strokeWidth = 6.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final paintGlow = Paint()
        ..color = isCompleted
            ? AppTheme.crimsonAccent.withValues(alpha: 0.4)
            : Colors.transparent
        ..strokeWidth = 12.0
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      // Posição Y dos nós consecutivos
      final startY = (i * itemHeight) + nodeRadius + 12;
      final endY = ((i + 1) * itemHeight) + nodeRadius + 12;

      // Deslocamento X alternado (efeito zig-zag estilo Duolingo)
      final startX = size.width / 2 + (i % 2 == 0 ? -18 : 18);
      final endX = size.width / 2 + ((i + 1) % 2 == 0 ? -18 : 18);

      final path = Path();
      path.moveTo(startX, startY);

      // Curva suave de Bézier conectando os nós
      final controlY1 = startY + (itemHeight / 2);
      final controlY2 = startY + (itemHeight / 2);
      path.cubicTo(startX, controlY1, endX, controlY2, endX, endY);

      // Desenha o brilho e a linha
      if (isCompleted) {
        canvas.drawPath(path, paintGlow);
      }
      canvas.drawPath(path, paintLine);
    }
  }

  @override
  bool shouldRepaint(covariant PathConnectorPainter oldDelegate) {
    return oldDelegate.completedStates != completedStates ||
        oldDelegate.nodeCount != nodeCount;
  }
}
