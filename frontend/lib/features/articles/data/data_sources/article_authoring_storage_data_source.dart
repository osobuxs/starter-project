import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

abstract class ArticleAuthoringStorageDataSource {
  Future<String> uploadArticleImage(String authorId, String imagePath);
}

class ArticleAuthoringStorageDataSourceImpl
    implements ArticleAuthoringStorageDataSource {
  final FirebaseStorage _storage;

  ArticleAuthoringStorageDataSourceImpl(this._storage);

  @override
  Future<String> uploadArticleImage(String authorId, String imagePath) async {
    final file = File(imagePath);
    final extension = imagePath.split('.').last;
    final path =
        'articles/$authorId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    final snapshot = await _storage.ref(path).putFile(file);
    return snapshot.ref.getDownloadURL();
  }
}
