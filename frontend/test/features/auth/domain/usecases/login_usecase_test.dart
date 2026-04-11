import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/login_usecase.dart';
import '../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository authRepository;
  late LoginUseCase useCase;

  const tUser = UserEntity(
    id: 'uid1',
    email: 'test@test.com',
    displayName: 'Test',
  );
  const tParams = LoginParams(email: 'test@test.com', password: '123456');

  setUp(() {
    authRepository = FakeAuthRepository();
    useCase = LoginUseCase(authRepository);
  });

  test('returns DataSuccess with UserEntity on successful login', () async {
    authRepository.onLogin = ({required email, required password}) async {
      expect(email, tParams.email);
      expect(password, tParams.password);
      return const DataSuccess(tUser);
    };

    final result = await useCase(params: tParams);

    expect(result, isA<DataSuccess<UserEntity>>());
    expect(result.data, equals(tUser));
  });

  test('returns DataFailed on login error', () async {
    authRepository.onLogin = ({required email, required password}) async {
      return DataFailed(Exception('wrong-password'));
    };

    final result = await useCase(params: tParams);

    expect(result, isA<DataFailed<UserEntity>>());
  });
}
