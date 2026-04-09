import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/entities/user_profile_entity.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/repository/user_profile_repository.dart';

class GetUserProfileParams {
  final String uid;

  const GetUserProfileParams({required this.uid});
}

class GetUserProfileUseCase
    implements UseCase<DataState<UserProfileEntity>, GetUserProfileParams> {
  final UserProfileRepository _repository;

  GetUserProfileUseCase(this._repository);

  @override
  Future<DataState<UserProfileEntity>> call({GetUserProfileParams? params}) {
    return _repository.getUserProfile(params!.uid);
  }
}
