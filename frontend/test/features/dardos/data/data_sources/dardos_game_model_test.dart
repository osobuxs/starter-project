import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/data/models/dardos_game_model.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_game.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';

void main() {
  // -----------------------------------------------------------------------
  // Fixtures
  // -----------------------------------------------------------------------
  final baseJson = {
    'name': 'Final torneo viernes',
    'mode': '501',
    'doubleOut': true,
    'sets': 1,
    'legs': 3,
    'status': 'playing',
    'createdAt': 1716000000000,
    'createdBy': 'uid-creator',
    'playerIds': ['p1', 'p2'],
    'starterOrder': ['p1', 'p2'],
    'rosterLocked': false,
    'currentSet': 0,
    'currentLeg': 0,
    'currentTurnPlayerId': 'p1',
    'currentTurnIndex': 0,
    'currentDartIndex': 0,
    'legWinners': [
      [null, null, null]
    ],
    'setWinners': [null],
    'winnerId': null,
    'activeAnnotator': null,
    'activeAnnotatorAt': null,
    'isActive': true,
    'deletedAt': null,
    'cancelledAt': null,
    'cancelledBy': null,
    'computedMetrics': null,
  };

  final legWinnersNestedJson = {
    'name': 'Test',
    'mode': '501',
    'doubleOut': false,
    'sets': 2,
    'legs': 3,
    'status': 'playing',
    'createdAt': 111,
    'createdBy': 'uid',
    'playerIds': ['p1', 'p2'],
    'starterOrder': ['p1', 'p2'],
    'rosterLocked': true,
    'currentSet': 1,
    'currentLeg': 0,
    'currentTurnPlayerId': 'p2',
    'currentTurnIndex': 2,
    'currentDartIndex': 0,
    'legWinners': [
      ['p1', 'p2', 'p1'],
      [null, null, null],
    ],
    'setWinners': ['p1', null],
    'winnerId': null,
    'activeAnnotator': 'device-A',
    'activeAnnotatorAt': 99999,
    'isActive': true,
    'deletedAt': null,
    'cancelledAt': null,
    'cancelledBy': null,
    'computedMetrics': null,
  };

  final throwEntity = DardosThrowEntity(
    id: 't1',
    playerId: 'p1',
    setIndex: 0,
    legIndex: 0,
    turnIndex: 0,
    dartIndex: 0,
    number: 20,
    multiplier: 3,
    points: 60,
    isMiss: false,
    isBust: false,
    remainingAfter: 441,
    cricketPointsScored: 0,
    timestamp: 1716000001,
    createdBy: 'uid',
  );

  // -----------------------------------------------------------------------
  // fromFirestore
  // -----------------------------------------------------------------------
  group('DardosGameModel.fromFirestore', () {
    test('parses base fields from Firestore document', () {
      final model = DardosGameModel.fromFirestore(baseJson, 'g1', []);

      expect(model.id, 'g1');
      expect(model.name, 'Final torneo viernes');
      expect(model.mode, '501');
      expect(model.doubleOut, isTrue);
      expect(model.sets, 1);
      expect(model.legs, 3);
      expect(model.status, 'playing');
      expect(model.playerIds, ['p1', 'p2']);
      expect(model.rosterLocked, isFalse);
      expect(model.currentSet, 0);
      expect(model.currentLeg, 0);
      expect(model.activeAnnotator, isNull);
      expect(model.winnerId, isNull);
    });

    test('parses nested legWinners: List<List<String?>>', () {
      final model = DardosGameModel.fromFirestore(legWinnersNestedJson, 'g2', []);

      expect(model.legWinners.length, 2);
      expect(model.legWinners[0], ['p1', 'p2', 'p1']);
      expect(model.legWinners[1], [null, null, null]);
    });

    test('parses setWinners list', () {
      final model = DardosGameModel.fromFirestore(legWinnersNestedJson, 'g2', []);

      expect(model.setWinners.length, 2);
      expect(model.setWinners[0], 'p1');
      expect(model.setWinners[1], isNull);
    });

    test('passes throws list through', () {
      final model = DardosGameModel.fromFirestore(baseJson, 'g1', [throwEntity]);

      expect(model.throws.length, 1);
      expect(model.throws.first.id, 't1');
    });

    test('parses computedMetrics as null when absent', () {
      final model = DardosGameModel.fromFirestore(baseJson, 'g1', []);
      expect(model.computedMetrics, isNull);
    });

    test('parses computedMetrics when present', () {
      final jsonWithMetrics = Map<String, dynamic>.from(baseJson);
      jsonWithMetrics['computedMetrics'] = {
        'perPlayer': {'p1': {'avg3Dart': 45.0}}
      };
      final model = DardosGameModel.fromFirestore(jsonWithMetrics, 'g1', []);
      expect(model.computedMetrics, isNotNull);
    });
  });

  // -----------------------------------------------------------------------
  // toJson
  // -----------------------------------------------------------------------
  group('DardosGameModel.toJson', () {
    test('round-trip preserves key fields', () {
      final model = DardosGameModel.fromFirestore(baseJson, 'g1', []);
      final json = model.toJson();

      expect(json['name'], baseJson['name']);
      expect(json['mode'], baseJson['mode']);
      expect(json['doubleOut'], baseJson['doubleOut']);
      expect(json['sets'], baseJson['sets']);
      expect(json['legs'], baseJson['legs']);
      expect(json['status'], baseJson['status']);
      expect(json['playerIds'], baseJson['playerIds']);
    });

    test('legWinners serialized as List<List<dynamic>>', () {
      final model = DardosGameModel.fromFirestore(legWinnersNestedJson, 'g2', []);
      final json = model.toJson();

      final lw = json['legWinners'] as List;
      expect(lw.length, 2);
      expect(lw[0], ['p1', 'p2', 'p1']);
    });

    test('toJson does NOT include id', () {
      final model = DardosGameModel.fromFirestore(baseJson, 'g1', []);
      final json = model.toJson();
      expect(json.containsKey('id'), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // toEntity / fromEntity
  // -----------------------------------------------------------------------
  group('DardosGameModel entity conversion', () {
    test('toEntity returns DardosGameEntity with same data', () {
      final model = DardosGameModel.fromFirestore(legWinnersNestedJson, 'g2', [throwEntity]);
      final entity = model.toEntity();

      expect(entity, isA<DardosGameEntity>());
      expect(entity.id, 'g2');
      expect(entity.legWinners[0][0], 'p1');
      expect(entity.throws.length, 1);
    });

    test('fromEntity preserves all fields including legWinners nesting', () {
      final original = DardosGameEntity(
        id: 'g-ent',
        name: 'Test',
        mode: 'cricket',
        doubleOut: false,
        sets: 1,
        legs: 3,
        status: 'playing',
        createdAt: 123,
        createdBy: 'uid',
        playerIds: const ['p1', 'p2', 'p3'],
        starterOrder: const ['p1', 'p2', 'p3'],
        rosterLocked: false,
        currentSet: 0,
        currentLeg: 1,
        currentTurnPlayerId: 'p2',
        currentTurnIndex: 0,
        currentDartIndex: 0,
        legWinners: const [
          ['p1', null, null]
        ],
        setWinners: const [null],
        isActive: true,
        throws: const [],
      );

      final model = DardosGameModel.fromEntity(original, []);
      final entity2 = model.toEntity();

      expect(entity2.id, original.id);
      expect(entity2.mode, original.mode);
      expect(entity2.legWinners[0][0], 'p1');
      expect(entity2.playerIds.length, 3);
    });
  });
}
