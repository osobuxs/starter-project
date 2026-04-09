import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/entities/user_profile_entity.dart';

abstract class UserProfileState extends Equatable {
  const UserProfileState();

  @override
  List<Object?> get props => [];
}

class UserProfileInitial extends UserProfileState {}

class UserProfileLoading extends UserProfileState {}

class UserProfileLoaded extends UserProfileState {
  final UserProfileEntity profile;

  const UserProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class UserProfileNotFound extends UserProfileState {}

class UserProfileError extends UserProfileState {
  final String message;
  final UserProfileEntity? profile;

  const UserProfileError(this.message, {this.profile});

  @override
  List<Object?> get props => [message, profile];
}

class UserProfileUpdating extends UserProfileState {
  final UserProfileEntity profile;

  const UserProfileUpdating(this.profile);

  @override
  List<Object?> get props => [profile];
}

class UserProfilePhotoUploading extends UserProfileState {
  final UserProfileEntity profile;

  const UserProfilePhotoUploading(this.profile);

  @override
  List<Object?> get props => [profile];
}
