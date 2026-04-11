import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';

enum AuthRequestSource { none, loginScreen, registerScreen, system }

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  final AuthRequestSource source;
  final String? requestId;

  const AuthLoading({this.source = AuthRequestSource.none, this.requestId});

  @override
  List<Object?> get props => [source, requestId];
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  final AuthRequestSource source;
  final String? requestId;

  const AuthAuthenticated(
    this.user, {
    this.source = AuthRequestSource.none,
    this.requestId,
  });

  @override
  List<Object?> get props => [user, source, requestId];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  final AuthRequestSource source;
  final String? requestId;

  const AuthError(
    this.message, {
    this.source = AuthRequestSource.none,
    this.requestId,
  });

  @override
  List<Object?> get props => [message, source, requestId];
}
