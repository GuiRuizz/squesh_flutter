import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBackground = Color(0xFF0D0D0D); // Black Piano
  static const Color cardSurface = Color(0xFF1A1A1A); // Superfície dos cards
  static const Color crimsonRed = Color(0xFFE50914); // Vermelho Adrenalina
  static const Color crimsonAccent = Color(0xFFFF2E3B); // Destaque brilhante
  static const Color textMain = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8C8C8C);

  static ThemeData get theme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: crimsonRed,
        secondary: crimsonAccent,
        surface: cardSurface,
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
      ),
      // Rede de segurança para qualquer SnackBar que sobre sem passar por
      // `showAppSnack`: pelo menos já sai flutuante. O visual "liquid neon"
      // completo está em lib/core/widgets/app_snackbar.dart.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
