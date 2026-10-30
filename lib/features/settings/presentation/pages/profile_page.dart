import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:singgah/core/di/injection_container.dart';
import 'package:singgah/core/localization/app_localizations.dart';
import 'package:singgah/core/theme/app_theme.dart';
import 'package:singgah/core/widgets/app_surfaces.dart';
import 'package:singgah/domain/usecases/auth_usecases.dart';
import 'package:singgah/features/auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _seeded = false;
  bool _saving = false;
  bool _uploading = false;
  String? _avatarUrl;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.watch<AuthBloc>().state.user;
    if (!_seeded) {
      _seeded = true;
      _name.text = user?.displayName ?? '';
      _avatarUrl = user?.avatarUrl;
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.back,
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.profile),
      ),
      body: PageScroll(
        maxWidth: 620,
        top: 10,
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _uploading ? null : _pickAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: context.singgah.accentSoft,
                        backgroundImage: _avatarUrl == null
                            ? null
                            : NetworkImage(_avatarUrl!),
                        child: _avatarUrl == null
                            ? Text(
                                user?.initials ?? '?',
                                style: context.texts.headlineMedium?.copyWith(
                                  color: context.singgah.accent,
                                ),
                              )
                            : null,
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: context.singgah.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.singgah.background,
                            width: 2,
                          ),
                        ),
                        child: _uploading
                            ? const Padding(
                                padding: EdgeInsets.all(7),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.photo_camera_outlined,
                                size: 15,
                                color: Colors.white,
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _uploading ? null : _pickAvatar,
                  child: Text(l10n.avatarChange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.profileSubtitle,
            textAlign: TextAlign.center,
            style: context.texts.bodySmall,
          ),
          const SizedBox(height: 22),
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.displayName,
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? l10n.authNameRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: user?.email ?? '',
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(l10n.save),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.accountDemoBody,
            textAlign: TextAlign.center,
            style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final l10n = context.l10n;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 720,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _uploading = true);
      final bytes = await picked.readAsBytes();
      final url = await getIt<UploadAvatar>()(bytes);
      if (!mounted) return;
      if (url == null) {
        // Demo mode keeps the initials avatar instead of failing the screen.
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.demoModeBody)));
        return;
      }
      setState(() {
        _avatarUrl = url;
        _uploading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorSaveData)));
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await getIt<UpdateProfile>()(
        displayName: _name.text.trim(),
        avatarUrl: _avatarUrl,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorSaveData)));
    }
  }
}
