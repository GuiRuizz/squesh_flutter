import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';
import '../widgets/main_navigation_screen.dart';

// Função auxiliar para criar a transição suave (Fade)
CustomTransitionPage<void> _buildCustomPageTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}

// Configuração das rotas
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavigationShell(navigationShell: navigationShell);
      },
      branches: [
        // Aba 0: Home Screen
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => _buildCustomPageTransition(
                state: state,
                child: const HomeScreen(),
              ),
            ),
          ],
        ),

        // Aba 1: Ranking
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ranking',
              pageBuilder: (context, state) => _buildCustomPageTransition(
                state: state,
                child: const _PlaceholderScreen(
                  title: 'RANKING',
                  icon: Icons.leaderboard,
                ),
              ),
            ),
          ],
        ),

        // Aba 2: Fotos / Compartilhar
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/photos',
              pageBuilder: (context, state) => _buildCustomPageTransition(
                state: state,
                child: const _PlaceholderScreen(
                  title: 'COMPARTILHAR',
                  icon: Icons.photo_camera,
                ),
              ),
            ),
          ],
        ),

        // Aba 3: Loja
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shop',
              pageBuilder: (context, state) => _buildCustomPageTransition(
                state: state,
                child: const _PlaceholderScreen(
                  title: 'LOJA',
                  icon: Icons.shopping_bag,
                ),
              ),
            ),
          ],
        ),

        // Aba 4: Configurações
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => _buildCustomPageTransition(
                state: state,
                child: const _PlaceholderScreen(
                  title: 'CONFIGURAÇÕES',
                  icon: Icons.settings,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

// Widget genérico de Placeholder para as rotas em desenvolvimento
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFF1E40), // AppTheme.crimsonRed
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: const Color(0xFF333333)),
            const SizedBox(height: 16),
            Text(
              'Página de $title em breve...',
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
