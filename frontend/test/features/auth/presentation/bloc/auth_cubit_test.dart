import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_state.dart';

import 'auth_cubit_test.mocks.dart';

void main() {
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockSignInWithGoogleUseCase mockSignInWithGoogleUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late AuthCubit cubit;

  const tUser = UserEntity(
    id: 'uid1',
    email: 'test@test.com',
    displayName: 'Test User',
  );
  const tGoogleUser = UserEntity(
    id: 'uid_google',
    email: 'google@test.com',
    displayName: 'Google User',
  );

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockSignInWithGoogleUseCase = MockSignInWithGoogleUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    cubit = AuthCubit(
      mockLoginUseCase,
      mockRegisterUseCase,
      mockSignInWithGoogleUseCase,
      mockLogoutUseCase,
      mockGetCurrentUserUseCase,
    );
  });

  tearDown(() => cubit.close());

  test('initial state is AuthInitial', () {
    expect(cubit.state, const AuthInitial());
  });

  group('login', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on success',
      build: () {
        mockLoginUseCase.handler = ({params}) async => const DataSuccess(tUser);
        return cubit;
      },
      act: (c) => c.login(email: 'test@test.com', password: '123456'),
      expect: () => [const AuthLoading(), const AuthAuthenticated(tUser)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] on failure',
      build: () {
        mockLoginUseCase.handler = ({params}) async =>
            DataFailed(Exception('wrong-password'));
        return cubit;
      },
      act: (c) => c.login(email: 'test@test.com', password: 'wrong'),
      expect: () => [const AuthLoading(), isA<AuthError>()],
    );
  });

  group('register', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on success',
      build: () {
        mockRegisterUseCase.handler = ({params}) async =>
            const DataSuccess(tUser);
        return cubit;
      },
      act: (c) => c.register(
        email: 'test@test.com',
        password: '123456',
        displayName: 'Test User',
      ),
      expect: () => [const AuthLoading(), const AuthAuthenticated(tUser)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] on failure',
      build: () {
        mockRegisterUseCase.handler = ({params}) async => DataFailed(
          FirebaseAuthException(code: 'email-already-in-use-google'),
        );
        return cubit;
      },
      act: (c) => c.register(
        email: 'exists@test.com',
        password: '123456',
        displayName: 'Test User',
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError(
          'Ese email ya está asociado a una cuenta creada con Google. Usá “Continuar con Google” para ingresar.',
        ),
      ],
    );
  });

  group('signInWithGoogle', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on success',
      build: () {
        mockSignInWithGoogleUseCase.handler = ({params}) async =>
            const DataSuccess(tGoogleUser);
        return cubit;
      },
      act: (c) => c.signInWithGoogle(),
      expect: () => [const AuthLoading(), const AuthAuthenticated(tGoogleUser)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when aborted',
      build: () {
        mockSignInWithGoogleUseCase.handler = ({params}) async =>
            DataFailed(Exception('Google sign-in aborted'));
        return cubit;
      },
      act: (c) => c.signInWithGoogle(),
      expect: () => [const AuthLoading(), isA<AuthError>()],
    );
  });

  group('logout', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] on success',
      build: () {
        mockLogoutUseCase.handler = ({params}) async => const DataSuccess(null);
        return cubit;
      },
      act: (c) => c.logout(),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );
  });

  group('checkCurrentUser', () {
    blocTest<AuthCubit, AuthState>(
      'emits AuthAuthenticated when user is logged in',
      build: () {
        mockGetCurrentUserUseCase.handler = () async => tUser;
        return cubit;
      },
      act: (c) => c.checkCurrentUser(),
      expect: () => [const AuthAuthenticated(tUser)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthUnauthenticated when no user',
      build: () {
        mockGetCurrentUserUseCase.handler = () async => null;
        return cubit;
      },
      act: (c) => c.checkCurrentUser(),
      expect: () => [const AuthUnauthenticated()],
    );
  });
}
