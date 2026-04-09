import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/features/user_profile/data/models/user_profile_model.dart';

abstract class UserProfileFirestoreDataSource {
  Future<UserProfileModel?> getUserProfile(String uid);
  Future<UserProfileModel> createUserProfile(
    String uid,
    String email,
    String name,
  );
  Future<UserProfileModel> updateUserProfile(UserProfileModel profile);
}

class UserProfileFirestoreDataSourceImpl
    implements UserProfileFirestoreDataSource {
  final FirebaseFirestore _firestore;

  UserProfileFirestoreDataSourceImpl(this._firestore);

  @override
  Future<UserProfileModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfileModel.fromRawData(doc.data()!, uid);
  }

  @override
  Future<UserProfileModel> createUserProfile(
    String uid,
    String email,
    String name,
  ) async {
    final now = DateTime.now();
    final profile = UserProfileModel(
      uid: uid,
      name: name,
      email: email,
      createdAt: now,
      updatedAt: now,
    );
    await _firestore.collection('users').doc(uid).set(profile.toMap());
    return profile;
  }

  @override
  Future<UserProfileModel> updateUserProfile(UserProfileModel profile) async {
    final updated = profile.copyWith(updatedAt: DateTime.now());
    await _firestore
        .collection('users')
        .doc(profile.uid)
        .update(updated.toMap());
    return updated;
  }
}
