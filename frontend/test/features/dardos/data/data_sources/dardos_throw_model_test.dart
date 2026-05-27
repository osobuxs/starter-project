import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/data/models/dardos_throw_model.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';

void main() {
  // -----------------------------------------------------------------------
  // Fixtures
  // -----------------------------------------------------------------------
  final fullJson = {
    'playerId': 'p1',
    'setIndex': 0,
    'legIndex': 1,
    'turnIndex': 3,
    'dartIndex': 1,
    'number': 20,
    'multiplier': 3,
    'points': 60,
    'isMiss': false,
    'isBust': false,
    'remainingAfter': 441,
    'cricketTarget': null,
    'cricketMarksDelta': null,
    'cricketPointsScored': 0,
    'timestamp': 1716000123456,
    'createdBy': 'uid-abc',
  };

  final cricketJson = {
    'playerId': 'p2',
    'setIndex': 0,
    'legIndex': 0,
    'turnIndex': 1,
    'dartIndex': 0,
    'number': 19,
    'multiplier': 2,
    'points': 0,
    'isMiss': false,
    'isBust': false,
    'remainingAfter': null,
    'cricketTarget': '19',
    'cricketMarksDelta': 2,
    'cricketPointsScored': 0,
    'timestamp': 1716000200000,
    'createdBy': 'uid-xyz',
  };

  final bustJson = {
    'playerId': 'p1',
    'setIndex': 0,
    'legIndex': 0,
    'turnIndex': 0,
    'dartIndex': 1,
    'number': 20,
    'multiplier': 1,
    'points': 20,
    'isMiss': false,
    'isBust': true,
    'remainingAfter': null,
    'cricketTarget': null,
    'cricketMarksDelta': null,
    'cricketPointsScored': 0,
    'timestamp': 1716000999,
    'createdBy': 'uid-abc',
  };

  // -----------------------------------------------------------------------
  // fromFirestore
  // -----------------------------------------------------------------------
  group('DardosThrowModel.fromFirestore', () {
    test('parses full 501 throw with all fields', () {
      final model = DardosThrowModel.fromFirestore(fullJson, 't1');

      expect(model.id, 't1');
      expect(model.playerId, 'p1');
      expect(model.setIndex, 0);
      expect(model.legIndex, 1);
      expect(model.turnIndex, 3);
      expect(model.dartIndex, 1);
      expect(model.number, 20);
      expect(model.multiplier, 3);
      expect(model.points, 60);
      expect(model.isMiss, isFalse);
      expect(model.isBust, isFalse);
      expect(model.remainingAfter, 441);
      expect(model.cricketTarget, isNull);
      expect(model.cricketMarksDelta, isNull);
      expect(model.cricketPointsScored, 0);
      expect(model.timestamp, 1716000123456);
      expect(model.createdBy, 'uid-abc');
    });

    test('parses cricket throw with cricketTarget and cricketMarksDelta', () {
      final model = DardosThrowModel.fromFirestore(cricketJson, 't2');

      expect(model.id, 't2');
      expect(model.cricketTarget, '19');
      expect(model.cricketMarksDelta, 2);
      expect(model.remainingAfter, isNull);
    });

    test('parses bust throw with isBust=true', () {
      final model = DardosThrowModel.fromFirestore(bustJson, 't3');

      expect(model.isBust, isTrue);
      expect(model.remainingAfter, isNull);
    });

    test('dartIndex is preserved across 0..2 range', () {
      for (var i = 0; i <= 2; i++) {
        final json = Map<String, dynamic>.from(fullJson);
        json['dartIndex'] = i;
        final model = DardosThrowModel.fromFirestore(json, 't$i');
        expect(model.dartIndex, i);
      }
    });
  });

  // -----------------------------------------------------------------------
  // toJson
  // -----------------------------------------------------------------------
  group('DardosThrowModel.toJson', () {
    test('round-trip: fromFirestore -> toJson preserves all structured fields', () {
      final model = DardosThrowModel.fromFirestore(fullJson, 't1');
      final json = model.toJson();

      expect(json['playerId'], fullJson['playerId']);
      expect(json['setIndex'], fullJson['setIndex']);
      expect(json['legIndex'], fullJson['legIndex']);
      expect(json['turnIndex'], fullJson['turnIndex']);
      expect(json['dartIndex'], fullJson['dartIndex']);
      expect(json['number'], fullJson['number']);
      expect(json['multiplier'], fullJson['multiplier']);
      expect(json['points'], fullJson['points']);
      expect(json['isBust'], fullJson['isBust']);
      expect(json['remainingAfter'], fullJson['remainingAfter']);
      expect(json['timestamp'], fullJson['timestamp']);
    });

    test('toJson includes cricket fields (null when 501)', () {
      final model = DardosThrowModel.fromFirestore(fullJson, 't1');
      final json = model.toJson();

      expect(json.containsKey('cricketTarget'), isTrue);
      expect(json['cricketTarget'], isNull);
      expect(json.containsKey('cricketMarksDelta'), isTrue);
    });

    test('toJson does NOT include id (id is Firestore doc key)', () {
      final model = DardosThrowModel.fromFirestore(fullJson, 't1');
      final json = model.toJson();
      expect(json.containsKey('id'), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // toEntity / fromEntity
  // -----------------------------------------------------------------------
  group('DardosThrowModel entity conversion', () {
    test('toEntity returns DardosThrowEntity with identical data', () {
      final model = DardosThrowModel.fromFirestore(fullJson, 't1');
      final entity = model.toEntity();

      expect(entity, isA<DardosThrowEntity>());
      expect(entity.id, model.id);
      expect(entity.playerId, model.playerId);
      expect(entity.dartIndex, model.dartIndex);
      expect(entity.points, model.points);
      expect(entity.isBust, model.isBust);
    });

    test('fromEntity round-trip preserves all fields', () {
      final original = DardosThrowEntity(
        id: 'throw-1',
        playerId: 'p1',
        setIndex: 1,
        legIndex: 2,
        turnIndex: 5,
        dartIndex: 2,
        number: 25,
        multiplier: 1,
        points: 25,
        isMiss: false,
        isBust: false,
        remainingAfter: null,
        cricketTarget: 'bull',
        cricketMarksDelta: 1,
        cricketPointsScored: 0,
        timestamp: 9999999,
        createdBy: 'uid-1',
      );

      final model = DardosThrowModel.fromEntity(original);
      final entity2 = model.toEntity();

      expect(entity2.id, original.id);
      expect(entity2.cricketTarget, original.cricketTarget);
      expect(entity2.dartIndex, original.dartIndex);
    });
  });
}
