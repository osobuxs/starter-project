import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_state.dart';

enum AppSectionDrawerVariant { full, auth }

class AppSectionScaffold extends StatelessWidget {
  final String title;
  final String currentRouteName;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final AppSectionDrawerVariant drawerVariant;
  final String? redirectRouteName;

  const AppSectionScaffold({
    super.key,
    required this.title,
    required this.currentRouteName,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
    this.drawerVariant = AppSectionDrawerVariant.full,
    this.redirectRouteName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black)),
        actions: actions,
      ),
      drawer: _AppSectionDrawer(
        currentRouteName: currentRouteName,
        drawerVariant: drawerVariant,
        redirectRouteName: redirectRouteName,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class _AppSectionDrawer extends StatelessWidget {
  final String currentRouteName;
  final AppSectionDrawerVariant drawerVariant;
  final String? redirectRouteName;

  const _AppSectionDrawer({
    required this.currentRouteName,
    required this.drawerVariant,
    required this.redirectRouteName,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isAuthenticated = authState is AuthAuthenticated;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Daily News',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
          _DrawerRouteTile(
            icon: Icons.home,
            label: 'Dashboard',
            onTap: () =>
                _navigateToRoute(context, routeName: AppRouteNames.dashboard),
          ),
          _DrawerRouteTile(
            icon: Icons.person,
            label: 'Mi perfil',
            onTap: () => _navigateToProtectedRoute(
              context,
              routeName: AppRouteNames.userProfile,
              label: 'Mi perfil',
            ),
          ),
          _DrawerRouteTile(
            icon: Icons.add_circle_outline,
            label: 'Crear noticia',
            onTap: () => _navigateToProtectedRoute(
              context,
              routeName: AppRouteNames.createArticle,
              label: 'Crear noticia',
            ),
          ),
          _DrawerRouteTile(
            icon: Icons.article_outlined,
            label: 'Mis notas',
            onTap: () => _navigateToProtectedRoute(
              context,
              routeName: AppRouteNames.myNotes,
              label: 'Mis notas',
            ),
          ),
          _DrawerRouteTile(
            icon: Icons.favorite_outline,
            label: 'Mis favoritos',
            onTap: () => _navigateToProtectedRoute(
              context,
              routeName: AppRouteNames.myFavorites,
              label: 'Mis favoritos',
            ),
          ),
          const Divider(),
          if (drawerVariant == AppSectionDrawerVariant.full)
            _DrawerRouteTile(
              icon: isAuthenticated ? Icons.logout : Icons.person_add_alt,
              label: isAuthenticated ? 'Cerrar sesión' : 'Crear cuenta',
              onTap: () {
                if (isAuthenticated) {
                  _onLogoutTapped(context);
                  return;
                }

                _navigateToRoute(
                  context,
                  routeName: AppRouteNames.register,
                  arguments: redirectRouteName,
                );
              },
            )
          else if (currentRouteName == AppRouteNames.login)
            _DrawerRouteTile(
              icon: Icons.person_add_alt,
              label: 'Crear cuenta',
              onTap: () => _navigateToRoute(
                context,
                routeName: AppRouteNames.register,
                arguments: redirectRouteName,
                replaceCurrent: true,
              ),
            )
          else
            _DrawerRouteTile(
              icon: Icons.login,
              label: 'Iniciar sesión',
              onTap: () => _navigateToRoute(
                context,
                routeName: AppRouteNames.login,
                arguments: redirectRouteName,
                replaceCurrent: true,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _navigateToProtectedRoute(
    BuildContext context, {
    required String routeName,
    required String label,
  }) async {
    final authState = context.read<AuthCubit>().state;
    final isAuthenticated = authState is AuthAuthenticated;

    if (isAuthenticated) {
      _navigateToRoute(context, routeName: routeName);
      return;
    }

    Navigator.of(context).pop();

    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Necesitás iniciar sesión'),
          content: Text(
            'Para abrir "$label" primero necesitás iniciar sesión. Después te llevamos automáticamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Ir al login'),
            ),
          ],
        );
      },
    );

    if (shouldContinue != true || !context.mounted) {
      return;
    }

    final shouldReplaceCurrent =
        currentRouteName == AppRouteNames.login ||
        currentRouteName == AppRouteNames.register;

    _navigateToRoute(
      context,
      routeName: AppRouteNames.login,
      arguments: routeName,
      replaceCurrent: shouldReplaceCurrent,
      closeDrawer: false,
    );
  }

  Future<void> _onLogoutTapped(BuildContext context) async {
    Navigator.of(context).pop();

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Querés cerrar tu sesión actual?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
    context.read<AuthCubit>().logout();
  }

  void _navigateToRoute(
    BuildContext context, {
    required String routeName,
    Object? arguments,
    bool replaceCurrent = false,
    bool closeDrawer = true,
  }) {
    if (closeDrawer) {
      Navigator.of(context).pop();
    }

    if (currentRouteName == routeName && arguments == redirectRouteName) {
      return;
    }

    if (replaceCurrent) {
      Navigator.of(
        context,
      ).pushReplacementNamed(routeName, arguments: arguments);
      return;
    }

    Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }
}

class _DrawerRouteTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerRouteTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
  }
}
