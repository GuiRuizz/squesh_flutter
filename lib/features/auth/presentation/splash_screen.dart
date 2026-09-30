import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// Tela exibida enquanto o AuthController restaura a sessão
/// (leitura do token + GET /users/me). O router a abandona sozinho
/// assim que o estado de autenticação resolve.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SQUESH',
              style: TextStyle(
                color: AppTheme.crimsonRed,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.crimsonAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}