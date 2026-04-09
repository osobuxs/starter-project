// dart run build_runner build --delete-conflicting-outputs
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/repository/auth_repository.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/logout_usecase.dart';

import 'logout_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepository;
  late LogoutUseCase useCase;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    useCase = LogoutUseCase(mockAuthRepository);
  });

  test('calls repository logout and returns DataSuccess', () async {
    when(mockAuthRepository.logout())
        .thenAnswer((_) async => const DataSuccess(null));

    final result = await useCase();

    expect(result, isA<DataSuccess<void>>());
    verify(mockAuthRepository.logout());
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
