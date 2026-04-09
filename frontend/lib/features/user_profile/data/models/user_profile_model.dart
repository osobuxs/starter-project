import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/features/user_profile/domain/entities/user_profile_entity.dart';

class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.uid,
    required super.name,
    required super.email,
    super.age,
    super.photoUrl,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserProfileModel.fromRawData(Map<String, dynamic> map, String uid) {
    final createdAt = map['createdAt'];
    final updatedAt = map['updatedAt'];

    return UserProfileModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      age: map['age'] as int?,
      photoUrl: map['photoUrl'] as String?,
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : (createdAt as DateTime?) ?? DateTime.now(),
      updatedAt: updatedAt is Timestamp
          ? updatedAt.toDate()
          : (updatedAt as DateTime?) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory UserProfileModel.fromEntity(UserProfileEntity entity) {
    return UserProfileModel(
      uid: entity.uid,
      name: entity.name,
      email: entity.email,
      age: entity.age,
      photoUrl: entity.photoUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  UserProfileEntity toEntity() {
    return UserProfileEntity(
      uid: uid,
      name: name,
      email: email,
      age: age,
      photoUrl: photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  UserProfileModel copyWith({
    String? uid,
    String? name,
    String? email,
    int? age,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
