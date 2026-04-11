import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import '../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository authRepository;
  late SignInWithGoogleUseCase useCase;

  const tUser = UserEntity(
    id: 'uid_google',
    email: 'google@test.com',
    displayName: 'Google User',
  );

  setUp(() {
    authRepository = FakeAuthRepository();
    useCase = SignInWithGoogleUseCase(authRepository);
  });

  test(
    'returns DataSuccess with UserEntity on successful Google sign-in',
    () async {
      authRepository.onSignInWithGoogle = () async => const DataSuccess(tUser);

      final result = await useCase();

      expect(result, isA<DataSuccess<UserEntity>>());
      expect(result.data, equals(tUser));
    },
  );

  test('returns DataFailed when Google sign-in is aborted or fails', () async {
    authRepository.onSignInWithGoogle = () async =>
        DataFailed(Exception('Google sign-in aborted'));

    final result = await useCase();

    expect(result, isA<DataFailed<UserEntity>>());
  });
}
