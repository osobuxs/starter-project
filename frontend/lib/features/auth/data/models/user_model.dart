import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_app_clean_architecture/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required String id,
    required String email,
    String? displayName,
  }) : super(id: id, email: email, displayName: displayName);

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  factory UserModel.fromRawData(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
    );
  }

  UserEntity toEntity() {
    return UserEntity(id: id, email: email, displayName: displayName);
  }
}
