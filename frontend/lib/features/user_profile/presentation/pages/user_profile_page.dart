import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/core/widgets/app_section_scaffold.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_state.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/entities/user_profile_entity.dart';
import 'package:news_app_clean_architecture/features/user_profile/presentation/cubit/user_profile_cubit.dart';
import 'package:news_app_clean_architecture/features/user_profile/presentation/cubit/user_profile_state.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  bool _didLoad = false;
  String? _pendingPhotoPath;
  bool _removePhotoRequested = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFormChanged);
    _ageController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFormChanged);
    _ageController.removeListener(_onFormChanged);
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<UserProfileCubit>().loadProfile(authState.user.id);
      _didLoad = true;
    }
  }

  Future<void> _onPickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _pendingPhotoPath = image.path;
      _removePhotoRequested = false;
    });
  }

  void _onRemovePhoto(UserProfileEntity currentProfile) {
    setState(() {
      _pendingPhotoPath = null;
      _removePhotoRequested =
          currentProfile.photoUrl?.trim().isNotEmpty == true;
    });
  }

  void _retryLoadProfile() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return;
    }

    context.read<UserProfileCubit>().loadProfile(authState.user.id);
  }

  Future<void> _showProfileErrorDialog(String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('No pudimos cargar tu perfil'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _retryLoadProfile();
              },
              child: const Text('Reintentar'),
            ),
          ],
        );
      },
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return;
    }

    context.read<UserProfileCubit>().updateProfile(
      uid: authState.user.id,
      name: _nameController.text.trim(),
      age: _ageController.text.trim().isEmpty
          ? null
          : int.tryParse(_ageController.text.trim()),
      pendingPhotoPath: _removePhotoRequested ? null : _pendingPhotoPath,
      removePhoto: _removePhotoRequested,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserProfileCubit, UserProfileState>(
      listener: (context, state) {
        if (state is UserProfileLoaded) {
          _nameController.text = state.profile.name;
          _ageController.text = state.profile.age?.toString() ?? '';
          if (_pendingPhotoPath != null || _removePhotoRequested) {
            setState(() {
              _pendingPhotoPath = null;
              _removePhotoRequested = false;
            });
          }
        }

        if (state is UserProfileError) {
          _showProfileErrorDialog(state.message);
        }
      },
      builder: (context, state) {
        if (state is UserProfileLoading || state is UserProfileInitial) {
          return const AppSectionScaffold(
            title: 'Mi perfil',
            currentRouteName: AppRouteNames.userProfile,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is UserProfileNotFound) {
          return const AppSectionScaffold(
            title: 'Mi perfil',
            currentRouteName: AppRouteNames.userProfile,
            body: Center(child: Text('No se encontró el perfil.')),
          );
        }

        final currentProfile = state is UserProfileLoaded
            ? state.profile
            : state is UserProfileUpdating
            ? state.profile
            : state is UserProfileError
            ? state.profile
            : null;

        if (currentProfile == null) {
          return AppSectionScaffold(
            title: 'Mi perfil',
            currentRouteName: AppRouteNames.userProfile,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'No se pudo cargar el perfil.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retryLoadProfile,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final isBusy = state is UserProfileUpdating;
        final hasUnsavedChanges = _hasUnsavedChanges(currentProfile);
        final photoProvider = _resolvePhotoProvider(currentProfile);
        final hasDisplayedPhoto = photoProvider != null;

        return WillPopScope(
          onWillPop: () => _confirmDiscardIfNeeded(currentProfile),
          child: AppSectionScaffold(
            title: 'Mi perfil',
            currentRouteName: AppRouteNames.userProfile,
            onWillLeaveSection: () => _confirmDiscardIfNeeded(currentProfile),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: hasDisplayedPhoto
                                ? () {
                                    _showProfilePhotoPreview(currentProfile);
                                  }
                                : null,
                            child: CircleAvatar(
                              radius: 42,
                              backgroundImage: photoProvider,
                              child: !hasDisplayedPhoto
                                  ? Text(
                                      currentProfile.name.isEmpty
                                          ? '?'
                                          : currentProfile.name[0]
                                                .toUpperCase(),
                                      style: const TextStyle(fontSize: 28),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              TextButton(
                                onPressed: isBusy ? null : _onPickPhoto,
                                child: const Text('Cambiar foto'),
                              ),
                              if (hasDisplayedPhoto)
                                OutlinedButton.icon(
                                  onPressed: isBusy
                                      ? null
                                      : () => _onRemovePhoto(currentProfile),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Quitar foto'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresá tu nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: currentProfile.email,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Edad',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }

                        if (int.tryParse(value.trim()) == null) {
                          return 'Ingresá una edad válida';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isBusy || !hasUnsavedChanges ? null : _onSave,
                      child: isBusy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar cambios'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDiscardIfNeeded(UserProfileEntity currentProfile) async {
    if (!_hasUnsavedChanges(currentProfile)) {
      return true;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tenés cambios sin guardar'),
          content: const Text(
            'Si salís ahora, vas a perder los cambios pendientes. ¿Querés salir igual?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Seguir editando'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Salir sin guardar'),
            ),
          ],
        );
      },
    );

    return shouldLeave ?? false;
  }

  bool _hasUnsavedChanges(UserProfileEntity currentProfile) {
    final normalizedName = _nameController.text.trim();
    final normalizedAgeText = _ageController.text.trim();
    final parsedAge = normalizedAgeText.isEmpty
        ? null
        : int.tryParse(normalizedAgeText);

    return currentProfile.name.trim() != normalizedName ||
        currentProfile.age != parsedAge ||
        _pendingPhotoPath != null ||
        (_removePhotoRequested &&
            currentProfile.photoUrl?.trim().isNotEmpty == true);
  }

  ImageProvider<Object>? _resolvePhotoProvider(
    UserProfileEntity currentProfile,
  ) {
    if (_pendingPhotoPath != null) {
      return FileImage(File(_pendingPhotoPath!));
    }

    if (_removePhotoRequested) {
      return null;
    }

    final photoUrl = currentProfile.photoUrl?.trim();
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }

    return NetworkImage(photoUrl);
  }

  Future<void> _showProfilePhotoPreview(UserProfileEntity currentProfile) {
    final pendingPhotoPath = _pendingPhotoPath?.trim();
    final photoUrl = _removePhotoRequested
        ? null
        : currentProfile.photoUrl?.trim();

    if ((pendingPhotoPath == null || pendingPhotoPath.isEmpty) &&
        (photoUrl == null || photoUrl.isEmpty)) {
      return Future<void>.value();
    }

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: pendingPhotoPath != null && pendingPhotoPath.isNotEmpty
                      ? Image.file(File(pendingPhotoPath), fit: BoxFit.contain)
                      : Image.network(photoUrl!, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
