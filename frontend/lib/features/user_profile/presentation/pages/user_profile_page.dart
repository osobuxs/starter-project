import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_state.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
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
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null || !mounted) {
      return;
    }

    await context.read<UserProfileCubit>().uploadPhoto(
      uid: authState.user.id,
      imagePath: image.path,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: BlocConsumer<UserProfileCubit, UserProfileState>(
        listener: (context, state) {
          if (state is UserProfileLoaded) {
            _nameController.text = state.profile.name;
            _ageController.text = state.profile.age?.toString() ?? '';
          }

          if (state is UserProfileError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is UserProfileLoading || state is UserProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UserProfileNotFound) {
            return const Center(child: Text('No se encontró el perfil.'));
          }

          final currentProfile = state is UserProfileLoaded
              ? state.profile
              : state is UserProfileUpdating
              ? state.profile
              : state is UserProfilePhotoUploading
              ? state.profile
              : null;

          if (currentProfile == null) {
            return const Center(child: Text('No se pudo cargar el perfil.'));
          }

          final isBusy =
              state is UserProfileUpdating ||
              state is UserProfilePhotoUploading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundImage: currentProfile.photoUrl != null
                              ? NetworkImage(currentProfile.photoUrl!)
                              : null,
                          child: currentProfile.photoUrl == null
                              ? Text(
                                  currentProfile.name.isEmpty
                                      ? '?'
                                      : currentProfile.name[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 28),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: isBusy ? null : _onPickPhoto,
                          child: const Text('Cambiar foto'),
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
                    onPressed: isBusy ? null : _onSave,
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
          );
        },
      ),
    );
  }
}
