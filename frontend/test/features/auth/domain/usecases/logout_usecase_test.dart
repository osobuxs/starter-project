import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/auth/domain/usecases/logout_usecase.dart';
import '../../support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository authRepository;
  late LogoutUseCase useCase;

  setUp(() {
    authRepository = FakeAuthRepository();
    useCase = LogoutUseCase(authRepository);
  });

  test('calls repository logout and returns DataSuccess', () async {
    authRepository.onLogout = () async => const DataSuccess(null);

    final result = await useCase();

    expect(result, isA<DataSuccess<void>>());
  });
}
