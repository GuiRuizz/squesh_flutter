import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/profile_controller.dart';
import 'settings_widgets.dart';

/// Formulário de edição do perfil: nome, bio e foto.
///
/// A foto sobe pelo mesmo fluxo do feed (presign -> PUT direto na URL
/// assinada -> grava a URL pública), então nenhum byte passa pela API. O
/// endereço é validado aqui para dar erro na hora, sem ida ao servidor.
class EditProfileScreen extends ConsumerStatefulWidget {
  final UserProfile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late String _avatarUrl;

  final _picker = ImagePicker();
  bool _busy = false;
  bool _uploadingPhoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _bio = TextEditingController(text: widget.profile.bio);
    _avatarUrl = widget.profile.avatarUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        // Avatar é redondo e pequeno: 512px evita subir um arquivo enorme.
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null || !mounted) return;

      setState(() => _uploadingPhoto = true);
      final updated = await ref
          .read(profileControllerProvider.notifier)
          .uploadAvatar(File(picked.path));
      if (!mounted) return;
      setState(() => _avatarUrl = updated.avatarUrl);
      showSettingsSnack(context, 'Foto atualizada!');
    } catch (e) {
      if (mounted) showSettingsSnack(context, describeError(e), error: true);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final confirmed = await confirmSettingsAction(
      context,
      title: 'Remover foto',
      message: 'Seu perfil volta a usar as iniciais.',
      confirmLabel: 'REMOVER',
    );
    if (!confirmed) return;

    try {
      await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(avatarUrl: '');
      if (mounted) setState(() => _avatarUrl = '');
    } catch (e) {
      if (mounted) showSettingsSnack(context, describeError(e), error: true);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final bio = _bio.text.trim();

    if (name.length < 2) {
      setState(() => _error = 'O nome precisa de pelo menos 2 caracteres.');
      return;
    }
    if (bio.length > 200) {
      setState(() => _error = 'A bio pode ter no máximo 200 caracteres.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(profileControllerProvider.notifier).updateProfile(
        name: name,
        bio: bio,
      );
      if (!mounted) return;
      showSettingsSnack(context, 'Perfil atualizado!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsColors.background,
      appBar: const SettingsAppBar('EDITAR PERFIL'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                ProfileAvatar(
                  avatarUrl: _avatarUrl,
                  name: _name.text,
                  size: 108,
                ),
                if (_uploadingPhoto)
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: SettingsColors.accent,
                      ),
                    ),
                  )
                else
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: SettingsColors.accent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _uploadingPhoto ? null : _pickPhoto,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.photo_camera_rounded,
                            size: 18,
                            color: SettingsColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: _avatarUrl.isEmpty
                ? const SizedBox(height: 20)
                : TextButton.icon(
                    onPressed: _removePhoto,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 15,
                      color: SettingsColors.textFaint,
                    ),
                    label: const Text(
                      'Remover foto',
                      style: TextStyle(
                        color: SettingsColors.textFaint,
                        fontSize: 12,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          SettingsTextField(
            controller: _name,
            label: 'Nome',
            maxLength: 100,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          SettingsTextField(
            controller: _bio,
            label: 'Bio',
            hint: 'Fale um pouco de você',
            maxLength: 200,
            maxLines: 3,
          ),
          if (_error != null) SettingsErrorText(_error!),
          const SizedBox(height: 20),
          SettingsPrimaryButton(
            label: 'SALVAR',
            busy: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}