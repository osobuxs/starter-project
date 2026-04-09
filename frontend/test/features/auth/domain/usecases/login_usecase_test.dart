// dart run build_runner build --delete-conflicting-outputs
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/repository/auth_repository.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/login_usecase.dart';

import 'login_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepository;
  late LoginUseCase useCase;

  const tUser = UserEntity(id: 'uid1', email: 'test@test.com', displayName: 'Test');
  const tParams = LoginParams(email: 'test@test.com', password: '123456');

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = LoginUseCase(mockAuthRepository);
  });

  test('returns DataSuccess with UserEntity on successful login', () async {
    when(mockAuthRepository.login(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenAnswer((_) async => const DataSuccess(tUser));

    final result = await useCase(params: tParams);

    expect(result, isA<DataSuccess<UserEntity>>());
    expect(result.data, equals(tUser));
    verify(mockAuthRepository.login(email: tParams.email, password: tParams.password));
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('returns DataFailed on login error', () async {
    when(mockAuthRepository.login(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenAnswer((_) async => DataFailed(Exception('wrong-password')));

    final result = await useCase(params: tParams);

    expect(result, isA<DataFailed<UserEntity>>());
  });
}
