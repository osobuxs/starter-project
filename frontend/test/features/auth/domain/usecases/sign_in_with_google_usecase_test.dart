// dart run build_runner build --delete-conflicting-outputs
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/repository/auth_repository.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/sign_in_with_google_usecase.dart';

import 'sign_in_with_google_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepository;
  late SignInWithGoogleUseCase useCase;

  const tUser = UserEntity(id: 'uid_google', email: 'google@test.com', displayName: 'Google User');

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = SignInWithGoogleUseCase(mockAuthRepository);
  });

  test('returns DataSuccess with UserEntity on successful Google sign-in', () async {
    when(mockAuthRepository.signInWithGoogle())
        .thenAnswer((_) async => const DataSuccess(tUser));

    final result = await useCase();

    expect(result, isA<DataSuccess<UserEntity>>());
    expect(result.data, equals(tUser));
    verify(mockAuthRepository.signInWithGoogle());
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('returns DataFailed when Google sign-in is aborted or fails', () async {
    when(mockAuthRepository.signInWithGoogle())
        .thenAnswer((_) async => DataFailed(Exception('Google sign-in aborted')));

    final result = await useCase();

    expect(result, isA<DataFailed<UserEntity>>());
  });
}
