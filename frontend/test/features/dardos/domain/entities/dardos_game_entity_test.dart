import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_game.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';

void main() {
  group('DardosGameEntity', () {
    final game = DardosGameEntity(
      id: 'g1',
      name: 'Test Game',
      mode: '501',
      doubleOut: true,
      sets: 1,
      legs: 3,
      status: 'playing',
      createdAt: 1716000000000,
      createdBy: 'uid-1',
      playerIds: const ['p1', 'p2'],
      starterOrder: const ['p1', 'p2'],
      rosterLocked: false,
      currentSet: 0,
      currentLeg: 0,
      currentTurnPlayerId: 'p1',
      currentTurnIndex: 0,
      currentDartIndex: 0,
      legWinners: [
        [null, null, null],
      ],
      setWinners: const [null],
      winnerId: null,
      activeAnnotator: null,
      activeAnnotatorAt: null,
      isActive: true,
      deletedAt: null,
      cancelledAt: null,
      cancelledBy: null,
      computedMetrics: null,
      throws: const [],
    );

    group('equality (Equatable)', () {
      test('two identical instances are equal', () {
        final other = DardosGameEntity(
          id: 'g1',
          name: 'Test Game',
          mode: '501',
          doubleOut: true,
          sets: 1,
          legs: 3,
          status: 'playing',
          createdAt: 1716000000000,
          createdBy: 'uid-1',
          playerIds: const ['p1', 'p2'],
          starterOrder: const ['p1', 'p2'],
          rosterLocked: false,
          currentSet: 0,
          currentLeg: 0,
          currentTurnPlayerId: 'p1',
          currentTurnIndex: 0,
          currentDartIndex: 0,
          legWinners: [
            [null, null, null],
          ],
          setWinners: const [null],
          winnerId: null,
          activeAnnotator: null,
          activeAnnotatorAt: null,
          isActive: true,
          deletedAt: null,
          cancelledAt: null,
          cancelledBy: null,
          computedMetrics: null,
          throws: const [],
        );
        expect(game, equals(other));
      });

      test('different id makes them not equal', () {
        final other = game.copyWith(id: 'g2');
        expect(game, isNot(equals(other)));
      });
    });

    group('copyWith', () {
      test('returns same values when nothing overridden', () {
        final copy = game.copyWith();
        expect(copy, equals(game));
      });

      test('changes status', () {
        final copy = game.copyWith(status: 'finished');
        expect(copy.status, 'finished');
      });

      test('changes winnerId', () {
        final copy = game.copyWith(winnerId: 'p1');
        expect(copy.winnerId, 'p1');
      });

      test('changes rosterLocked', () {
        final copy = game.copyWith(rosterLocked: true);
        expect(copy.rosterLocked, true);
      });

      test('changes currentDartIndex', () {
        final copy = game.copyWith(currentDartIndex: 2);
        expect(copy.currentDartIndex, 2);
      });

      test('changes legWinners', () {
        final newWinners = [
          ['p1', null, null],
        ];
        final copy = game.copyWith(legWinners: newWinners);
        expect(copy.legWinners[0][0], 'p1');
      });

      test('changes setWinners', () {
        final copy = game.copyWith(setWinners: ['p1']);
        expect(copy.setWinners[0], 'p1');
      });

      test('changes throws', () {
        const t = DardosThrowEntity(
          id: 't1',
          playerId: 'p1',
          setIndex: 0,
          legIndex: 0,
          turnIndex: 0,
          dartIndex: 0,
          number: 20,
          multiplier: 1,
          points: 20,
          isMiss: false,
          isBust: false,
          cricketPointsScored: 0,
          timestamp: 0,
          createdBy: 'uid',
        );
        final copy = game.copyWith(throws: [t]);
        expect(copy.throws.length, 1);
      });

      test('changes cancelledAt and cancelledBy', () {
        final copy = game.copyWith(cancelledAt: 9999, cancelledBy: 'admin');
        expect(copy.cancelledAt, 9999);
        expect(copy.cancelledBy, 'admin');
      });
    });

    group('legWinners structure', () {
      test('legWinners is List<List<String?>>', () {
        expect(game.legWinners, isA<List<List<String?>>>());
        expect(game.legWinners[0], isA<List<String?>>());
        expect(game.legWinners[0][0], isNull);
      });
    });

    group('nullable fields', () {
      test('winnerId can be null', () {
        expect(game.winnerId, isNull);
      });

      test('activeAnnotator can be null', () {
        expect(game.activeAnnotator, isNull);
      });

      test('computedMetrics can be null', () {
        expect(game.computedMetrics, isNull);
      });
    });
  });
}
