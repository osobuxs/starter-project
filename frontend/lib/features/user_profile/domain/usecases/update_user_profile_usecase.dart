import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/entities/user_profile_entity.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/repository/user_profile_repository.dart';

class UpdateUserProfileParams {
  final UserProfileEntity profile;

  const UpdateUserProfileParams({required this.profile});
}

class UpdateUserProfileUseCase
    implements UseCase<DataState<UserProfileEntity>, UpdateUserProfileParams> {
  final UserProfileRepository _repository;

  UpdateUserProfileUseCase(this._repository);

  @override
  Future<DataState<UserProfileEntity>> call({UpdateUserProfileParams? params}) {
    return _repository.updateUserProfile(params!.profile);
  }
}
