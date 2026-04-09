import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/core/usecase/usecase.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/repository/user_profile_repository.dart';

class UploadProfilePhotoParams {
  final String uid;
  final String imagePath;

  const UploadProfilePhotoParams({required this.uid, required this.imagePath});
}

class UploadProfilePhotoUseCase
    implements UseCase<DataState<String>, UploadProfilePhotoParams> {
  final UserProfileRepository _repository;

  UploadProfilePhotoUseCase(this._repository);

  @override
  Future<DataState<String>> call({UploadProfilePhotoParams? params}) {
    return _repository.uploadProfilePhoto(params!.uid, params.imagePath);
  }
}
