import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

abstract class UserProfileStorageDataSource {
  Future<String> uploadProfilePhoto(String uid, String imagePath);
  Future<void> deleteProfilePhoto(String uid);
}

class UserProfileStorageDataSourceImpl implements UserProfileStorageDataSource {
  final FirebaseStorage _storage;

  UserProfileStorageDataSourceImpl(this._storage);

  @override
  Future<String> uploadProfilePhoto(String uid, String imagePath) async {
    final ref = _storage.ref().child('media/users/$uid/profile.jpg');
    await ref.putFile(File(imagePath));
    return await ref.getDownloadURL();
  }

  @override
  Future<void> deleteProfilePhoto(String uid) async {
    final ref = _storage.ref().child('media/users/$uid/profile.jpg');
    await ref.delete();
  }
}
