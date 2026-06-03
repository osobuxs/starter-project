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

    group('team mode helpers', () {
      final teamGame = game.copyWith(
        playerIds: const ['p1', 'p2', 'p3', 'p4'],
        starterOrder: const ['p1', 'p2', 'p3', 'p4'],
        teamMode: true,
        teams: const [
          {
            'id': 'team_1',
            'name': 'Equipo 1',
            'playerIds': ['p1', 'p3'],
          },
          {
            'id': 'team_2',
            'name': 'Equipo 2',
            'playerIds': ['p2', 'p4'],
          },
        ],
        playerTeamIds: const {
          'p1': 'team_1',
          'p3': 'team_1',
          'p2': 'team_2',
          'p4': 'team_2',
        },
      );

      test('scoreOwnerIds returns team ids instead of player ids', () {
        expect(teamGame.scoreOwnerIds, ['team_1', 'team_2']);
      });

      test('scoreOwnerForPlayer maps player to team', () {
        expect(teamGame.scoreOwnerForPlayer('p1'), 'team_1');
        expect(teamGame.scoreOwnerForPlayer('p4'), 'team_2');
      });

      test('playersForWinner returns both team players', () {
        expect(teamGame.playersForWinner('team_1'), ['p1', 'p3']);
      });

      test('non-team mode keeps player as score owner and winner', () {
        expect(game.scoreOwnerIds, ['p1', 'p2']);
        expect(game.scoreOwnerForPlayer('p1'), 'p1');
        expect(game.playersForWinner('p2'), ['p2']);
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
