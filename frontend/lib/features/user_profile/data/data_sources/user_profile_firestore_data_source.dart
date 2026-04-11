import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/core/constants/constants.dart';
import 'package:news_app_clean_architecture/features/user_profile/data/models/user_profile_model.dart';

const int kArticleAuthorSyncBatchLimit = 400;

List<List<T>> chunkItems<T>(List<T> items, int chunkSize) {
  if (items.isEmpty) return const [];

  final safeChunkSize = chunkSize <= 0 ? 1 : chunkSize;
  final chunks = <List<T>>[];

  for (var i = 0; i < items.length; i += safeChunkSize) {
    final end = (i + safeChunkSize > items.length)
        ? items.length
        : i + safeChunkSize;
    chunks.add(items.sublist(i, end));
  }

  return chunks;
}

Map<String, dynamic> buildArticleAuthorSyncPayload(UserProfileModel profile) {
  return {
    'authorName': profile.name,
    'authorPhotoUrl': profile.photoUrl,
    'authorEmail': profile.email,
  };
}

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
    final userRef = _firestore.collection('users').doc(profile.uid);
    final articlesSnapshot = await _firestore
        .collection(kArticlesCollection)
        .where('authorId', isEqualTo: profile.uid)
        .get();
    final authorSyncPayload = buildArticleAuthorSyncPayload(updated);

    final articleRefs = articlesSnapshot.docs
        .map((articleDoc) => articleDoc.reference)
        .toList();

    await _commitProfileAndArticleSync(
      userRef: userRef,
      userPayload: updated.toMap(),
      articleRefs: articleRefs,
      articlePayload: authorSyncPayload,
    );

    return updated;
  }

  Future<void> _commitProfileAndArticleSync({
    required DocumentReference<Map<String, dynamic>> userRef,
    required Map<String, dynamic> userPayload,
    required List<DocumentReference<Map<String, dynamic>>> articleRefs,
    required Map<String, dynamic> articlePayload,
  }) async {
    if (articleRefs.isEmpty) {
      final batch = _firestore.batch();
      batch.update(userRef, userPayload);
      await batch.commit();
      return;
    }

    var userUpdated = false;
    final chunks = chunkItems(articleRefs, kArticleAuthorSyncBatchLimit);

    for (final chunk in chunks) {
      final batch = _firestore.batch();
      if (!userUpdated) {
        batch.update(userRef, userPayload);
        userUpdated = true;
      }

      for (final articleRef in chunk) {
        batch.update(articleRef, articlePayload);
      }

      await batch.commit();
    }
  }
}
