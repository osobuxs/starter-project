// dart run build_runner build --delete-conflicting-outputs
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/login_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/logout_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/register_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_state.dart';

import 'auth_cubit_test.mocks.dart';

@GenerateMocks([
  LoginUseCase,
  RegisterUseCase,
  SignInWithGoogleUseCase,
  LogoutUseCase,
  GetCurrentUserUseCase,
])
void main() {
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockSignInWithGoogleUseCase mockSignInWithGoogleUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late AuthCubit cubit;

  const tUser = UserEntity(id: 'uid1', email: 'test@test.com', displayName: 'Test User');
  const tGoogleUser = UserEntity(id: 'uid_google', email: 'google@test.com', displayName: 'Google User');

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
        when(mockLoginUseCase(params: anyNamed('params')))
            .thenAnswer((_) async => const DataSuccess(tUser));
        return cubit;
      },
      act: (c) => c.login(email: 'test@test.com', password: '123456'),
      expect: () => [const AuthLoading(), const AuthAuthenticated(tUser)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] on failure',
      build: () {
        when(mockLoginUseCase(params: anyNamed('params')))
            .thenAnswer((_) async => DataFailed(Exception('wrong-password')));
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
        when(mockRegisterUseCase(params: anyNamed('params')))
            .thenAnswer((_) async => const DataSuccess(tUser));
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
        when(mockRegisterUseCase(params: anyNamed('params')))
            .thenAnswer((_) async => DataFailed(Exception('email-already-in-use')));
        return cubit;
      },
      act: (c) => c.register(
        email: 'exists@test.com',
        password: '123456',
        displayName: 'Test User',
      ),
      expect: () => [const AuthLoading(), isA<AuthError>()],
    );
  });

  group('signInWithGoogle', () {
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on success',
      build: () {
        when(mockSignInWithGoogleUseCase())
            .thenAnswer((_) async => const DataSuccess(tGoogleUser));
        return cubit;
      },
      act: (c) => c.signInWithGoogle(),
      expect: () => [const AuthLoading(), const AuthAuthenticated(tGoogleUser)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthError] when aborted',
      build: () {
        when(mockSignInWithGoogleUseCase())
            .thenAnswer((_) async => DataFailed(Exception('Google sign-in aborted')));
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
        when(mockLogoutUseCase()).thenAnswer((_) async => const DataSuccess(null));
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
        when(mockGetCurrentUserUseCase()).thenAnswer((_) async => tUser);
        return cubit;
      },
      act: (c) => c.checkCurrentUser(),
      expect: () => [const AuthAuthenticated(tUser)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthUnauthenticated when no user',
      build: () {
        when(mockGetCurrentUserUseCase()).thenAnswer((_) async => null);
        return cubit;
      },
      act: (c) => c.checkCurrentUser(),
      expect: () => [const AuthUnauthenticated()],
    );
  });
}
