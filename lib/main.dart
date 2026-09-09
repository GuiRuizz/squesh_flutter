import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'app/theme/app_theme.dart';

void main() async {
  // Garante a inicialização das bindings do Flutter antes do SystemChrome/MediaQuery
  WidgetsFlutterBinding.ensureInitialized();

  final view = MediaQueryData.fromView(
    WidgetsBinding.instance.platformDispatcher.views.first,
  );
  final isTablet = view.size.shortestSide >= 600;

  if (isTablet) {
    // Trava em Paisagem (Horizontal) se for Tablet
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } else {
    // Trava em Retrato (Vertical) se for Smartphone
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  runApp(const ProviderScope(child: SqueshApp()));
}

class SqueshApp extends StatelessWidget {
  const SqueshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Squesh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig:
          appRouter, // <--- O GoRouter assume o controle das rotas aqui
    );
  }
}
