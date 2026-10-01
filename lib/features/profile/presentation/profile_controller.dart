import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../social/data/social_api_service.dart';
import '../data/user_api_service.dart';
import '../domain/user_preferences.dart';
import '../domain/user_profile.dart';

/// Perfil completo do usuário logado, usado pela tela de Configurações.
///
/// Separado do `authControllerProvider` (que guarda a identidade da sessão)
/// porque aqui também vivem bio, pontos e preferências, que só a tela de
/// configurações precisa. Depois de salvar, os dois ficam em dia: o perfil
/// volta da API e a sessão é recarregada para o nome e o avatar mudarem no
/// resto do app.
final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, UserProfile>(
      ProfileController.new,
    );

class ProfileController extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() {
    return ref.read(userApiServiceProvider).getProfile();
  }

  /// PUT /users/me — campos nulos ficam de fora do corpo (atualização parcial).
  Future<UserProfile> updateProfile({
    String? name,
    String? bio,
    String? avatarUrl,
  }) async {
    final updated = await ref
        .read(userApiServiceProvider)
        .updateProfile(name: name, bio: bio, avatarUrl: avatarUrl);

    state = AsyncData(updated);
    // O nome e o avatar também aparecem no resto do app: atualiza a sessão.
    await _syncSession();
    return updated;
  }

  /// Sobe a foto do perfil: presign -> PUT direto na URL assinada -> grava a
  /// URL pública. O arquivo nunca passa pelo servidor da API.
  Future<UserProfile> uploadAvatar(File file) async {
    final social = ref.read(socialApiServiceProvider);
    final presign = await social.presignUpload(
      filename: 'avatar.png',
      contentType: 'image/png',
      folder: 'avatars',
    );
    await social.uploadFile(
      uploadUrl: presign.uploadUrl,
      file: file,
      contentType: 'image/png',
    );
    return updateProfile(avatarUrl: presign.imageUrl);
  }

  /// PUT /users/me/preferences
  Future<UserProfile> savePreferences(UserPreferences preferences) async {
    final updated = await ref
        .read(userApiServiceProvider)
        .updatePreferences(preferences);
    state = AsyncData(updated);
    return updated;
  }

  Future<UserProfile> reload() async {
    final fresh = await ref.read(userApiServiceProvider).getProfile();
    state = AsyncData(fresh);
    await _syncSession();
    return fresh;
  }

  Future<void> _syncSession() async {
    try {
      await ref.read(authControllerProvider.notifier).refreshProfile();
    } catch (_) {
      // A sessão é secundária: se falhar, a tela de configurações já tem o
      // dado certo, então não vale mostrar erro por causa disso.
    }
  }
}
