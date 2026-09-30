import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:squesh_flutter/features/auth/presentation/auth_controller.dart';
import 'package:squesh_flutter/features/auth/presentation/login_screen.dart';
import 'package:squesh_flutter/features/auth/presentation/splash_screen.dart';
import 'package:squesh_flutter/features/notification/presentation/notification_screen.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/ranking/presentation/ranking_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/shop/presentation/shop_screen.dart';
import '../features/social/presentation/photos_screen.dart';
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

/// Configuração das rotas. É um Provider porque o redirect depende do estado
/// de autenticação (authControllerProvider): deslogado só enxerga /login,
/// logado enxerga o app, e em restauração de sessão mostra o /splash.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      // 1. Sessão ainda sendo restaurada -> splash
      if (authState.isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      final isAuthenticated = authState.value != null;

      // 2. Deslogado: só pode ficar na tela de login
      if (!isAuthenticated) {
        return location == '/login' ? null : '/login';
      }

      // 3. Logado: não pode ficar na tela de login NEM na de splash (sessão
      // restaurada). Qualquer outra rota é do app e deve ser liberada.
      return (location == '/login' || location == '/splash') ? '/' : null;
    },
    routes: [
      // Rotas de autenticação (fullscreen, fora da bottom navigation)
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Rotas das Abas Principais (com Bottom Navigation Shell)
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
                  child: const RankingScreen(),
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
                  child: const PhotosScreen(),
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
                  child: const ShopScreen(),
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
                  child: const SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Rota independente (Fullscreen Overlay, esconde a BottomNavBar)
      GoRoute(
        path: '/notifications',
        builder: (context, state) {
          return NotificationScreen();
        },
      ),
    ],
  );

  // Sempre que o auth mudar (login/logout), reavalia o redirect.
  ref.listen(authControllerProvider, (_, _) => router.refresh());

  return router;
});