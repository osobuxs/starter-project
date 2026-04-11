import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/user_profile/data/data_sources/user_profile_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/user_profile/data/models/user_profile_model.dart';

void main() {
  group('buildArticleAuthorSyncPayload', () {
    test('syncs the public author fields used by article documents', () {
      final profile = UserProfileModel(
        uid: 'user-1',
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        photoUrl: 'https://example.com/ada.png',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final payload = buildArticleAuthorSyncPayload(profile);

      expect(payload['authorName'], 'Ada Lovelace');
      expect(payload['authorPhotoUrl'], 'https://example.com/ada.png');
      expect(payload['authorEmail'], 'ada@example.com');
    });

    test('preserves null photos so stale article avatars are cleared', () {
      final profile = UserProfileModel(
        uid: 'user-1',
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        photoUrl: null,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final payload = buildArticleAuthorSyncPayload(profile);

      expect(payload['authorName'], 'Ada Lovelace');
      expect(payload.containsKey('authorPhotoUrl'), isTrue);
      expect(payload['authorPhotoUrl'], isNull);
      expect(payload['authorEmail'], 'ada@example.com');
    });
  });
}
