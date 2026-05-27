import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/data/models/dardos_participant_model.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_participant.dart';

void main() {
  // -----------------------------------------------------------------------
  // Fixtures
  // -----------------------------------------------------------------------
  final fullJson = {
    'name': 'Exe',
    'email': 'lfexevega95@gmail.com',
    'uid': 'uid-123',
    'isActive': true,
    'deletedAt': null,
    'createdAt': 1716000000000,
    'totalGamesPlayed': 12,
    'totalGamesWon': 4,
    'statsByMode': {
      '501': {'played': 5, 'won': 2, 'avg3Dart': 42.3},
      'cricket': {'played': 3, 'mpr': 1.7},
    },
  };

  final minimalJson = {
    'name': 'Guest',
    'email': null,
    'uid': null,
    'isActive': true,
    'deletedAt': null,
    'createdAt': 1000000000,
    'totalGamesPlayed': 0,
    'totalGamesWon': 0,
    'statsByMode': <String, dynamic>{},
  };

  // -----------------------------------------------------------------------
  // fromFirestore
  // -----------------------------------------------------------------------
  group('DardosParticipantModel.fromFirestore', () {
    test('parses all fields from a full document', () {
      final model = DardosParticipantModel.fromFirestore(fullJson, 'p1');

      expect(model.id, 'p1');
      expect(model.name, 'Exe');
      expect(model.email, 'lfexevega95@gmail.com');
      expect(model.uid, 'uid-123');
      expect(model.isActive, isTrue);
      expect(model.deletedAt, isNull);
      expect(model.createdAt, 1716000000000);
      expect(model.totalGamesPlayed, 12);
      expect(model.totalGamesWon, 4);
      expect(model.statsByMode, isNotEmpty);
    });

    test('parses nullable fields (email, uid, deletedAt) as null when absent', () {
      final model = DardosParticipantModel.fromFirestore(minimalJson, 'p2');

      expect(model.id, 'p2');
      expect(model.email, isNull);
      expect(model.uid, isNull);
      expect(model.deletedAt, isNull);
      expect(model.totalGamesPlayed, 0);
      expect(model.statsByMode, isEmpty);
    });

    test('parses deletedAt as non-null int when present', () {
      final jsonWithDeleted = Map<String, dynamic>.from(fullJson);
      jsonWithDeleted['deletedAt'] = 1716100000000;

      final model = DardosParticipantModel.fromFirestore(jsonWithDeleted, 'p3');
      expect(model.deletedAt, 1716100000000);
    });
  });

  // -----------------------------------------------------------------------
  // toJson / round-trip
  // -----------------------------------------------------------------------
  group('DardosParticipantModel.toJson', () {
    test('round-trip: fromFirestore -> toJson produces equivalent map', () {
      final model = DardosParticipantModel.fromFirestore(fullJson, 'p1');
      final json = model.toJson();

      expect(json['name'], fullJson['name']);
      expect(json['email'], fullJson['email']);
      expect(json['uid'], fullJson['uid']);
      expect(json['isActive'], fullJson['isActive']);
      expect(json['createdAt'], fullJson['createdAt']);
      expect(json['totalGamesPlayed'], fullJson['totalGamesPlayed']);
      expect(json['totalGamesWon'], fullJson['totalGamesWon']);
    });

    test('toJson does NOT include id field (Firestore doc id is separate)', () {
      final model = DardosParticipantModel.fromFirestore(fullJson, 'p1');
      final json = model.toJson();
      expect(json.containsKey('id'), isFalse);
    });

    test('toJson includes null values for nullable fields', () {
      final model = DardosParticipantModel.fromFirestore(minimalJson, 'p99');
      final json = model.toJson();
      expect(json['email'], isNull);
      expect(json['uid'], isNull);
      expect(json['deletedAt'], isNull);
    });
  });

  // -----------------------------------------------------------------------
  // toEntity / fromEntity
  // -----------------------------------------------------------------------
  group('DardosParticipantModel entity conversion', () {
    test('toEntity returns DardosParticipantEntity with same data', () {
      final model = DardosParticipantModel.fromFirestore(fullJson, 'p1');
      final entity = model.toEntity();

      expect(entity, isA<DardosParticipantEntity>());
      expect(entity.id, model.id);
      expect(entity.name, model.name);
      expect(entity.email, model.email);
      expect(entity.uid, model.uid);
      expect(entity.isActive, model.isActive);
      expect(entity.totalGamesPlayed, model.totalGamesPlayed);
      expect(entity.totalGamesWon, model.totalGamesWon);
    });

    test('fromEntity round-trip preserves all fields', () {
      final original = DardosParticipantEntity(
        id: 'p-ent',
        name: 'Test Player',
        email: 'test@test.com',
        uid: 'uid-test',
        isActive: true,
        deletedAt: null,
        createdAt: 1234567890,
        totalGamesPlayed: 3,
        totalGamesWon: 1,
        statsByMode: const {},
      );

      final model = DardosParticipantModel.fromEntity(original);
      final entity2 = model.toEntity();

      expect(entity2.id, original.id);
      expect(entity2.name, original.name);
      expect(entity2.email, original.email);
      expect(entity2.totalGamesPlayed, original.totalGamesPlayed);
    });
  });
}
