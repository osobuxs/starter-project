import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';
import 'package:news_app_clean_architecture/features/auth/domain/repository/auth_repository.dart';

class RegisterParams {
  final String email;
  final String password;
  final String displayName;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

class RegisterUseCase implements UseCase<DataState<UserEntity>, RegisterParams> {
  final AuthRepository _authRepository;

  RegisterUseCase(this._authRepository);

  @override
  Future<DataState<UserEntity>> call({RegisterParams? params}) {
    return _authRepository.register(
      email: params!.email,
      password: params.password,
      displayName: params.displayName,
    );
  }
}
