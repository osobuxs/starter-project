import 'package:equatable/equatable.dart';

class UserProfileEntity extends Equatable {
  static const Object _photoUrlSentinel = Object();

  final String uid;
  final String name;
  final String email;
  final int? age;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfileEntity({
    required this.uid,
    required this.name,
    required this.email,
    this.age,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfileEntity copyWith({
    String? uid,
    String? name,
    String? email,
    int? age,
    Object? photoUrl = _photoUrlSentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileEntity(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      photoUrl: identical(photoUrl, _photoUrlSentinel)
          ? this.photoUrl
          : photoUrl as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    name,
    email,
    age,
    photoUrl,
    createdAt,
    updatedAt,
  ];
}
