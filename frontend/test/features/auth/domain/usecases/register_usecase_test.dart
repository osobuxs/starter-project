// dart run build_runner build --delete-conflicting-outputs
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/repository/auth_repository.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/register_usecase.dart';

import 'register_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepository;
  late RegisterUseCase useCase;

  const tUser = UserEntity(id: 'uid1', email: 'test@test.com', displayName: 'New User');
  const tParams = RegisterParams(
    email: 'test@test.com',
    password: '123456',
    displayName: 'New User',
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = RegisterUseCase(mockAuthRepository);
  });

  test('returns DataSuccess with UserEntity on successful registration', () async {
    when(mockAuthRepository.register(
      email: anyNamed('email'),
      password: anyNamed('password'),
      displayName: anyNamed('displayName'),
    )).thenAnswer((_) async => const DataSuccess(tUser));

    final result = await useCase(params: tParams);

    expect(result, isA<DataSuccess<UserEntity>>());
    expect(result.data?.displayName, equals('New User'));
    verify(mockAuthRepository.register(
      email: tParams.email,
      password: tParams.password,
      displayName: tParams.displayName,
    ));
  });

  test('returns DataFailed when email already in use', () async {
    when(mockAuthRepository.register(
      email: anyNamed('email'),
      password: anyNamed('password'),
      displayName: anyNamed('displayName'),
    )).thenAnswer((_) async => DataFailed(Exception('email-already-in-use')));

    final result = await useCase(params: tParams);

    expect(result, isA<DataFailed<UserEntity>>());
  });
}
