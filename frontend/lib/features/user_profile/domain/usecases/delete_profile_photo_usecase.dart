import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/repository/user_profile_repository.dart';

class DeleteProfilePhotoParams {
  final String uid;

  const DeleteProfilePhotoParams({required this.uid});
}

class DeleteProfilePhotoUseCase
    implements UseCase<DataState<void>, DeleteProfilePhotoParams> {
  final UserProfileRepository _repository;

  DeleteProfilePhotoUseCase(this._repository);

  @override
  Future<DataState<void>> call({DeleteProfilePhotoParams? params}) {
    return _repository.deleteProfilePhoto(params!.uid);
  }
}
