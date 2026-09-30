import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/token_storage.dart';
import '../../profile/data/user_api_service.dart';
import '../data/auth_api_service.dart';
import '../domain/auth_user.dart';

/// Gerencia a sessão do app. Estados:
/// - AsyncLoading: restaurando sessão do armazenamento seguro (splash);
/// - AsyncData(null): deslogado -> o router manda para /login;
/// - AsyncData(AuthUser): autenticado -> o router libera o app.
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final token = await tokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await ref.read(userApiServiceProvider).getProfile();
      return AuthUser.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      // Token expirado/inválido: derruba a sessão para o fluxo de refresh
      // tentar de novo ou o usuário relogar.
      if (e.response?.statusCode == 401) {
        await tokenStorage.clearTokens();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    final data = await ref.read(authApiServiceProvider).login(email, password);
    await _persistSession(data);
  }

  Future<void> register(String name, String email, String password) async {
    final data = await ref
        .read(authApiServiceProvider)
        .register(name, email, password);
    await _persistSession(data);
  }

  Future<void> _persistSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final refreshToken = data['refresh_token'] as String;

    await ref.read(tokenStorageProvider).saveTokens(
          accessToken: token,
          refreshToken: refreshToken,
        );

    state = AsyncData(
      AuthUser.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      ),
    );
  }

  Future<void> logout() async {
    final storage = ref.read(tokenStorageProvider);
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await ref.read(authApiServiceProvider).logout(refreshToken);
      } catch (_) {
        // Revogação falhou (rede/API fora) — a sessão local é limpa de qualquer forma.
      }
    }
    await storage.clearTokens();
    state = const AsyncData(null);
  }

  /// Recarrega os dados do usuário (ex.: após editar o perfil).
  Future<void> refreshProfile() async {
    final token = await ref.read(tokenStorageProvider).getAccessToken();
    if (token == null) return;

    final response = await ref.read(userApiServiceProvider).getProfile();
    state = AsyncData(
      AuthUser.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      ),
    );
  }
}