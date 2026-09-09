import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: SqueshApp()));
}

class SqueshApp extends StatelessWidget {
  const SqueshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Squesh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}
