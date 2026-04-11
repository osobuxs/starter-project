import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/navigation/auth_redirect.dart';
import 'package:news_app_clean_architecture/core/navigation/route_names.dart';
import 'package:news_app_clean_architecture/core/widgets/app_section_scaffold.dart';
import 'package:news_app_clean_architecture/core/widgets/app_state_views.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_state.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/validation/auth_form_validators.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/widgets/auth_inline_error_banner.dart';

class LoginPage extends StatefulWidget {
  final Object? redirectRoute;

  const LoginPage({Key? key, this.redirectRoute}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _authErrorMessage;
  String? _activeRequestId;
  int _submitSequence = 0;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearAuthError);
    _passwordController.addListener(_clearAuthError);
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearAuthError);
    _passwordController.removeListener(_clearAuthError);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearAuthError() {
    if (_authErrorMessage == null || !mounted) {
      return;
    }

    setState(() => _authErrorMessage = null);
  }

  String _nextRequestId() {
    _submitSequence += 1;
    return 'login-${DateTime.now().microsecondsSinceEpoch}-$_submitSequence';
  }

  bool _matchesCurrentRequest(AuthState state) {
    final activeRequestId = _activeRequestId;
    if (activeRequestId == null) {
      return false;
    }

    if (state is AuthLoading) {
      return state.source == AuthRequestSource.loginScreen &&
          state.requestId == activeRequestId;
    }

    if (state is AuthAuthenticated) {
      return state.source == AuthRequestSource.loginScreen &&
          state.requestId == activeRequestId;
    }

    if (state is AuthError) {
      return state.source == AuthRequestSource.loginScreen &&
          state.requestId == activeRequestId;
    }

    return false;
  }

  void _startSubmit() {
    setState(() {
      _authErrorMessage = null;
      _isSubmitting = true;
      _activeRequestId = _nextRequestId();
    });
  }

  void _finishSubmit({String? errorMessage}) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      _activeRequestId = null;
      _authErrorMessage = errorMessage;
    });
  }

  void _onLogin() {
    if (_isSubmitting) {
      return;
    }

    _clearAuthError();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _startSubmit();
    context.read<AuthCubit>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      source: AuthRequestSource.loginScreen,
      requestId: _activeRequestId,
    );
  }

  void _onGoogleSignIn() {
    if (_isSubmitting) {
      return;
    }

    _clearAuthError();
    _startSubmit();
    context.read<AuthCubit>().signInWithGoogle(
      source: AuthRequestSource.loginScreen,
      requestId: _activeRequestId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSectionScaffold(
      title: 'Iniciar sesión',
      currentRouteName: AppRouteNames.login,
      drawerVariant: AppSectionDrawerVariant.auth,
      redirectRouteName: widget.redirectRoute,
      body: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) => _matchesCurrentRequest(current),
        listener: (context, state) {
          if (state is AuthError) {
            _finishSubmit(errorMessage: state.message);
            return;
          }

          if (state is AuthAuthenticated) {
            _finishSubmit();
          }
        },
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Bienvenido de nuevo',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresá con tu cuenta para continuar donde habías quedado.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        inputFormatters:
                            AuthFormValidators.emailInputFormatters,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: AuthFormValidators.validateEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        inputFormatters:
                            AuthFormValidators.passwordInputFormatters,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                        ),
                        validator: AuthFormValidators.validatePassword,
                      ),
                      if (_authErrorMessage != null) ...[
                        const SizedBox(height: 16),
                        AuthInlineErrorBanner(message: _authErrorMessage!),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _onLogin,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const AppInlineLoadingIndicator()
                            : const Text('Ingresar'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'o',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _onGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.g_mobiledata, size: 24),
                        label: const Text('Continuar con Google'),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿No tenés cuenta?'),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed(
                                AppRouteNames.register,
                                arguments: widget.redirectRoute,
                              );
                            },
                            child: const Text('Registrate'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
