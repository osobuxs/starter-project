import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/register_usecase.dart';
import '../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository authRepository;
  late RegisterUseCase useCase;

  const tUser = UserEntity(
    id: 'uid1',
    email: 'test@test.com',
    displayName: 'New User',
  );
  const tParams = RegisterParams(
    email: 'test@test.com',
    password: '123456',
    displayName: 'New User',
  );

  setUp(() {
    authRepository = FakeAuthRepository();
    useCase = RegisterUseCase(authRepository);
  });

  test(
    'returns DataSuccess with UserEntity on successful registration',
    () async {
      authRepository.onRegister =
          ({required email, required password, required displayName}) async {
            expect(email, tParams.email);
            expect(password, tParams.password);
            expect(displayName, tParams.displayName);
            return const DataSuccess(tUser);
          };

      final result = await useCase(params: tParams);

      expect(result, isA<DataSuccess<UserEntity>>());
      expect(result.data?.displayName, equals('New User'));
    },
  );

  test('returns DataFailed when email already in use', () async {
    authRepository.onRegister =
        ({required email, required password, required displayName}) async {
          return DataFailed(Exception('email-already-in-use'));
        };

    final result = await useCase(params: tParams);

    expect(result, isA<DataFailed<UserEntity>>());
  });
}
