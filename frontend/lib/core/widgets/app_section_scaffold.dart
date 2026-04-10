import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/auth_redirect.dart';
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
  final Object? redirectRouteName;
  final Future<bool> Function()? onWillLeaveSection;

  const AppSectionScaffold({
    super.key,
    required this.title,
    required this.currentRouteName,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
    this.drawerVariant = AppSectionDrawerVariant.full,
    this.redirectRouteName,
    this.onWillLeaveSection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black)),
        actions: actions,
      ),
      drawer: _AppSectionDrawer(
        navigationContext: context,
        currentRouteName: currentRouteName,
        drawerVariant: drawerVariant,
        redirectRouteName: redirectRouteName,
        onWillLeaveSection: onWillLeaveSection,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

Future<void> navigateToProtectedRoute(
  BuildContext context, {
  required BuildContext navigationContext,
  required String currentRouteName,
  required String routeName,
  required String label,
  bool closeCurrentDrawer = false,
  Object? redirectArguments,
}) async {
  await navigateRequiringAuthentication(
    context,
    navigationContext: navigationContext,
    currentRouteName: currentRouteName,
    destination: AuthRedirectDestination(
      routeName: routeName,
      arguments: redirectArguments,
    ),
    actionLabel: 'abrir "$label"',
    closeCurrentNavigator: closeCurrentDrawer,
  );
}

class _AppSectionDrawer extends StatelessWidget {
  final BuildContext navigationContext;
  final String currentRouteName;
  final AppSectionDrawerVariant drawerVariant;
  final Object? redirectRouteName;
  final Future<bool> Function()? onWillLeaveSection;

  const _AppSectionDrawer({
    required this.navigationContext,
    required this.currentRouteName,
    required this.drawerVariant,
    required this.redirectRouteName,
    required this.onWillLeaveSection,
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
          if (drawerVariant == AppSectionDrawerVariant.full && isAuthenticated)
            _DrawerRouteTile(
              icon: Icons.logout,
              label: 'Cerrar sesión',
              onTap: () => _onLogoutTapped(context),
            )
          else if (drawerVariant == AppSectionDrawerVariant.full) ...[
            _DrawerRouteTile(
              icon: Icons.person_add_alt,
              label: 'Crear cuenta',
              onTap: () => _navigateToRoute(
                context,
                routeName: AppRouteNames.register,
                arguments: redirectRouteName,
              ),
            ),
            _DrawerRouteTile(
              icon: Icons.login,
              label: 'Iniciar sesión',
              onTap: () => _navigateToRoute(
                context,
                routeName: AppRouteNames.login,
                arguments: redirectRouteName,
              ),
            ),
          ] else if (currentRouteName == AppRouteNames.login)
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
    final shouldLeave = await _confirmLeaveSectionIfNeeded(
      routeName: routeName,
    );
    if (!shouldLeave) {
      return;
    }

    await navigateToProtectedRoute(
      context,
      navigationContext: navigationContext,
      currentRouteName: currentRouteName,
      routeName: routeName,
      label: label,
      closeCurrentDrawer: true,
      redirectArguments: null,
    );
  }

  Future<void> _onLogoutTapped(BuildContext context) async {
    final shouldLeave = await _confirmLeaveSectionIfNeeded();
    if (!shouldLeave) {
      return;
    }

    Navigator.of(context).pop();

    final shouldLogout = await showDialog<bool>(
      context: navigationContext,
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

    if (shouldLogout != true || !navigationContext.mounted) {
      return;
    }

    Navigator.of(navigationContext).popUntil((route) => route.isFirst);
    navigationContext.read<AuthCubit>().logout();
  }

  Future<void> _navigateToRoute(
    BuildContext context, {
    required String routeName,
    Object? arguments,
    bool replaceCurrent = false,
    bool closeDrawer = true,
  }) async {
    if (currentRouteName == routeName && arguments == redirectRouteName) {
      if (closeDrawer) {
        Navigator.of(context).pop();
      }
      return;
    }

    final shouldLeave = await _confirmLeaveSectionIfNeeded(
      routeName: routeName,
      arguments: arguments,
      skipIfSameDestination: true,
    );
    if (!shouldLeave) {
      return;
    }

    if (closeDrawer) {
      Navigator.of(context).pop();
    }

    if (replaceCurrent) {
      Navigator.of(
        navigationContext,
      ).pushReplacementNamed(routeName, arguments: arguments);
      return;
    }

    Navigator.of(navigationContext).pushNamed(routeName, arguments: arguments);
  }

  Future<bool> _confirmLeaveSectionIfNeeded({
    String? routeName,
    Object? arguments,
    bool skipIfSameDestination = false,
  }) async {
    final isSameDestination =
        skipIfSameDestination &&
        routeName != null &&
        currentRouteName == routeName &&
        arguments == redirectRouteName;

    if (isSameDestination || onWillLeaveSection == null) {
      return true;
    }

    return await onWillLeaveSection!();
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
