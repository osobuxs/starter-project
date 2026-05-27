import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/cricket_marks_state.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/services/dardos_leg_rules.dart';

DardosThrowEntity makeThrow({
  String id = 't',
  String playerId = 'p1',
  int setIndex = 0,
  int legIndex = 0,
  int turnIndex = 0,
  int dartIndex = 0,
  required int number,
  required int multiplier,
  bool isBust = false,
  int? remainingAfter,
  String? cricketTarget,
  int? cricketMarksDelta,
  int cricketPointsScored = 0,
}) {
  return DardosThrowEntity(
    id: id,
    playerId: playerId,
    setIndex: setIndex,
    legIndex: legIndex,
    turnIndex: turnIndex,
    dartIndex: dartIndex,
    number: number,
    multiplier: multiplier,
    points: number * multiplier,
    isMiss: false,
    isBust: isBust,
    remainingAfter: remainingAfter,
    cricketTarget: cricketTarget,
    cricketMarksDelta: cricketMarksDelta,
    cricketPointsScored: cricketPointsScored,
    timestamp: 0,
    createdBy: 'uid',
  );
}

void main() {
  // -----------------------------------------------------------------------
  // nextStarter
  // -----------------------------------------------------------------------
  group('nextStarter', () {
    test('[A,B,C] globalLeg=0 → A', () {
      expect(
        nextStarter(starterOrder: ['A', 'B', 'C'], globalLegIndex: 0),
        'A',
      );
    });

    test('[A,B,C] globalLeg=1 → B', () {
      expect(
        nextStarter(starterOrder: ['A', 'B', 'C'], globalLegIndex: 1),
        'B',
      );
    });

    test('[A,B,C] globalLeg=2 → C', () {
      expect(
        nextStarter(starterOrder: ['A', 'B', 'C'], globalLegIndex: 2),
        'C',
      );
    });

    test('[A,B,C] globalLeg=3 → A (wraps)', () {
      expect(
        nextStarter(starterOrder: ['A', 'B', 'C'], globalLegIndex: 3),
        'A',
      );
    });

    test('[A,B,C] globalLeg=4 → B (wraps)', () {
      expect(
        nextStarter(starterOrder: ['A', 'B', 'C'], globalLegIndex: 4),
        'B',
      );
    });

    test('single-player always returns same player', () {
      expect(nextStarter(starterOrder: ['solo'], globalLegIndex: 0), 'solo');
      expect(nextStarter(starterOrder: ['solo'], globalLegIndex: 10), 'solo');
    });

    test('[A,B] globalLeg=7 → A (7 mod 2 = 1 → B, 7 mod 2 = 1)', () {
      // 7 mod 2 = 1 → B
      expect(
        nextStarter(starterOrder: ['A', 'B'], globalLegIndex: 7),
        'B',
      );
    });
  });

  // -----------------------------------------------------------------------
  // isLegOver / legWinner (501 mode)
  // -----------------------------------------------------------------------
  group('isLegOver / legWinner — 501 mode', () {
    test('501: player reaches 0 with valid double checkout → leg over', () {
      // p1 has 40 remaining, hits D20 = 40 pts (checkout valid)
      final throws = [
        makeThrow(
          id: 't1', playerId: 'p1', dartIndex: 0,
          number: 20, multiplier: 2,
          remainingAfter: 0,
        ),
      ];
      expect(
        isLegOver(
          mode: '501',
          legStartScore: 501,
          legThrows: throws,
          playerIds: ['p1', 'p2'],
          doubleOut: true,
        ),
        isTrue,
      );
    });

    test('501: bust dart leaves score > 0 → not over', () {
      final throws = [
        makeThrow(
          id: 't1', playerId: 'p1', dartIndex: 0,
          number: 20, multiplier: 1,
          isBust: true,
        ),
      ];
      expect(
        isLegOver(
          mode: '501',
          legStartScore: 501,
          legThrows: throws,
          playerIds: ['p1', 'p2'],
          doubleOut: true,
        ),
        isFalse,
      );
    });

    test('501 legWinner returns playerId when player has 0 remaining', () {
      // Build enough throws for p1 to reach 0 from 40 with doubleOut
      final throws = <DardosThrowEntity>[];
      // 501 - 60*8 = 21, too complicated. Let's use startScore=40.
      // p1 hits D20: remainingAfter=0
      throws.add(makeThrow(
        id: 't1', playerId: 'p1', dartIndex: 0,
        number: 20, multiplier: 2,
        remainingAfter: 0,
      ));

      expect(
        legWinner(
          mode: '501',
          legStartScore: 40,
          legThrows: throws,
          playerIds: ['p1', 'p2'],
          doubleOut: true,
        ),
        'p1',
      );
    });

    test('501 legWinner returns null when no one reached 0', () {
      final throws = [
        makeThrow(id: 't1', playerId: 'p1', dartIndex: 0, number: 20, multiplier: 1),
      ];
      expect(
        legWinner(
          mode: '501',
          legStartScore: 501,
          legThrows: throws,
          playerIds: ['p1', 'p2'],
          doubleOut: true,
        ),
        isNull,
      );
    });
  });

  // -----------------------------------------------------------------------
  // isLegOver / legWinner (Cricket mode)
  // -----------------------------------------------------------------------
  group('isLegOver / legWinner — cricket mode', () {
    test('Cricket: player closed all + pts >= others → leg over', () {
      // Build a CricketMarksState where p1 has all closed and more pts than p2
      // We need isLegOver to check each player via isCricketWinner
      // The function needs to reconstruct cricket state from legThrows.
      // For simplicity, we pass throws that result in all-closed state for p1.
      // Actually per design, isLegOver for cricket delegates to isCricketWinner.
      // We'll pass cricketTarget and cricketMarksDelta on throws.
      final throws = <DardosThrowEntity>[];
      // p1 closes all 7 targets with triples
      for (final target in CricketMarksState.cricketTargets) {
        throws.add(DardosThrowEntity(
          id: 't_$target',
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
          cricketTarget: target,
          cricketMarksDelta: 3,
          cricketPointsScored: 0,
          timestamp: 0,
          createdBy: 'uid',
        ));
      }
      expect(
        isLegOver(
          mode: 'cricket',
          legStartScore: 0,
          legThrows: throws,
          playerIds: ['p1', 'p2'],
          doubleOut: false,
        ),
        isTrue,
      );
    });
  });

  // -----------------------------------------------------------------------
  // isSetOver / setWinner
  // -----------------------------------------------------------------------
  group('isSetOver / setWinner', () {
    test('legs=3: 2 wins for A → set over', () {
      expect(
        isSetOver(
          legsPerSet: 3,
          legWinnersInSet: ['A', 'A', null],
        ),
        isTrue,
      );
    });

    test('legs=3: 1-1 after 2 legs → not over', () {
      expect(
        isSetOver(
          legsPerSet: 3,
          legWinnersInSet: ['A', 'B', null],
        ),
        isFalse,
      );
    });

    test('legs=3: 2-0 → set over', () {
      expect(
        isSetOver(
          legsPerSet: 3,
          legWinnersInSet: ['A', 'A', null],
        ),
        isTrue,
      );
    });

    test('legs=1: 1 win → set over', () {
      expect(
        isSetOver(
          legsPerSet: 1,
          legWinnersInSet: ['A'],
        ),
        isTrue,
      );
    });

    test('setWinner returns correct playerId with majority', () {
      expect(setWinner(['A', 'A', 'B']), 'A');
    });

    test('setWinner returns null when no majority', () {
      expect(setWinner(['A', 'B', null]), isNull);
    });

    test('setWinner returns winner from 2-leg majority', () {
      expect(setWinner(['B', 'B']), 'B');
    });

    test('legs=5: 3 wins for B → set over', () {
      expect(
        isSetOver(
          legsPerSet: 5,
          legWinnersInSet: ['B', 'B', 'B', null, null],
        ),
        isTrue,
      );
    });

    test('legs=5: 2 each → not over (need 3)', () {
      expect(
        isSetOver(
          legsPerSet: 5,
          legWinnersInSet: ['A', 'B', 'A', 'B', null],
        ),
        isFalse,
      );
    });
  });

  // -----------------------------------------------------------------------
  // isGameOver / gameWinner
  // -----------------------------------------------------------------------
  group('isGameOver / gameWinner', () {
    test('sets=3: 2 wins for A → game over', () {
      expect(
        isGameOver(setsPerGame: 3, setWinners: ['A', 'A', null]),
        isTrue,
      );
    });

    test('sets=3: 1-1 after 2 sets → not over', () {
      expect(
        isGameOver(setsPerGame: 3, setWinners: ['A', 'B', null]),
        isFalse,
      );
    });

    test('sets=1: 1 win → game over', () {
      expect(
        isGameOver(setsPerGame: 1, setWinners: ['A']),
        isTrue,
      );
    });

    test('gameWinner returns playerId with majority sets', () {
      expect(gameWinner(['A', 'A', 'B']), 'A');
    });

    test('gameWinner returns null when no majority', () {
      expect(gameWinner(['A', 'B', null]), isNull);
    });

    test('sets=5: 3 wins for B → game over', () {
      expect(
        isGameOver(setsPerGame: 5, setWinners: ['B', 'B', 'B', null, null]),
        isTrue,
      );
    });

    test('sets=1: no winners yet → not over', () {
      expect(
        isGameOver(setsPerGame: 1, setWinners: [null]),
        isFalse,
      );
    });
  });
}
