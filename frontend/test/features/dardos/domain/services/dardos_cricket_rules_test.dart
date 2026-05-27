import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/cricket_marks_state.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/services/dardos_cricket_rules.dart';

void main() {
  // -----------------------------------------------------------------------
  // computeMarksAfterThrow
  // -----------------------------------------------------------------------
  group('computeMarksAfterThrow', () {
    test('single on 15 adds 1 mark', () {
      final state = CricketMarksState.empty(['p1', 'p2']);
      final result = computeMarksAfterThrow(
        currentState: state,
        playerId: 'p1',
        target: '15',
        multiplier: 1,
      );
      expect(result.marksByPlayer['p1']!['15'], 1);
    });

    test('double on 19 adds 2 marks', () {
      final state = CricketMarksState.empty(['p1', 'p2']);
      final result = computeMarksAfterThrow(
        currentState: state,
        playerId: 'p1',
        target: '19',
        multiplier: 2,
      );
      expect(result.marksByPlayer['p1']!['19'], 2);
    });

    test('triple on 20 adds 3 marks (closes it)', () {
      final state = CricketMarksState.empty(['p1', 'p2']);
      final result = computeMarksAfterThrow(
        currentState: state,
        playerId: 'p1',
        target: '20',
        multiplier: 3,
      );
      expect(result.marksByPlayer['p1']!['20'], 3);
    });

    test('bull exterior (multiplier=1) adds 1 mark on bull', () {
      final state = CricketMarksState.empty(['p1', 'p2']);
      final result = computeMarksAfterThrow(
        currentState: state,
        playerId: 'p1',
        target: 'bull',
        multiplier: 1,
      );
      expect(result.marksByPlayer['p1']!['bull'], 1);
    });

    test('bull interior (multiplier=2) adds 2 marks on bull', () {
      final state = CricketMarksState.empty(['p1', 'p2']);
      final result = computeMarksAfterThrow(
        currentState: state,
        playerId: 'p1',
        target: 'bull',
        multiplier: 2,
      );
      expect(result.marksByPlayer['p1']!['bull'], 2);
    });

    test('marks accumulate beyond 3 (cap not applied here — caller reads overflow)', () {
      // Starting with 2 marks, adding double = 4 marks total
      final state = CricketMarksState(
        marksByPlayer: {
          'p1': {'15': 2, '16': 0, '17': 0, '18': 0, '19': 0, '20': 0, 'bull': 0},
          'p2': {'15': 0, '16': 0, '17': 0, '18': 0, '19': 0, '20': 0, 'bull': 0},
        },
        pointsByPlayer: {'p1': 0, 'p2': 0},
      );
      final result = computeMarksAfterThrow(
        currentState: state,
        playerId: 'p1',
        target: '15',
        multiplier: 2,
      );
      expect(result.marksByPlayer['p1']!['15'], 4);
    });

    test('hit on invalid target (14) adds 0 marks', () {
      final state = CricketMarksState.empty(['p1', 'p2']);
      final result = computeMarksAfterThrow(
        currentState: state,
        playerId: 'p1',
        target: '14',
        multiplier: 3,
      );
      // '14' is not a cricket target — no marks on any target
      expect(result.marksByPlayer['p1']!['15'], 0);
      expect(result.marksByPlayer['p1']!['20'], 0);
    });

    test('other player marks not affected', () {
      final state = CricketMarksState.empty(['p1', 'p2']);
      final result = computeMarksAfterThrow(
        currentState: state,
        playerId: 'p1',
        target: '20',
        multiplier: 3,
      );
      expect(result.marksByPlayer['p2']!['20'], 0);
    });
  });

  // -----------------------------------------------------------------------
  // isTargetClosedByAll
  // -----------------------------------------------------------------------
  group('isTargetClosedByAll', () {
    test('all 2 players closed (>=3) returns true', () {
      expect(
        isTargetClosedByAll({'p1': 3, 'p2': 4}),
        isTrue,
      );
    });

    test('one of 2 not closed returns false', () {
      expect(
        isTargetClosedByAll({'p1': 3, 'p2': 2}),
        isFalse,
      );
    });

    test('3 players all closed returns true', () {
      expect(
        isTargetClosedByAll({'p1': 3, 'p2': 5, 'p3': 3}),
        isTrue,
      );
    });

    test('3 players one not closed returns false', () {
      expect(
        isTargetClosedByAll({'p1': 3, 'p2': 2, 'p3': 3}),
        isFalse,
      );
    });

    test('single player with >=3 returns true', () {
      expect(isTargetClosedByAll({'p1': 3}), isTrue);
    });

    test('empty map returns true (vacuously all closed)', () {
      expect(isTargetClosedByAll({}), isTrue);
    });
  });

  // -----------------------------------------------------------------------
  // computePointsFromOverflow
  // -----------------------------------------------------------------------
  group('computePointsFromOverflow', () {
    test('own marks < 3: no points (not yet closed)', () {
      // p1 has 2 marks, multiplier applied = 1
      expect(
        computePointsFromOverflow(
          playerMarksOnTarget: {'p1': 2, 'p2': 0},
          playerId: 'p1',
          target: '20',
          multiplierApplied: 1,
          basePoints: 20,
        ),
        0,
      );
    });

    test('own marks == 3 after hit (exact close): 0 surplus points', () {
      // Before: p1 has 2 marks. After adding 1 = 3. No surplus.
      expect(
        computePointsFromOverflow(
          playerMarksOnTarget: {'p1': 2, 'p2': 0},
          playerId: 'p1',
          target: '20',
          multiplierApplied: 1,
          basePoints: 20,
        ),
        0,
      );
    });

    test('own marks == 4 (was 3, hit single), opponent not closed → basePoints * 1', () {
      // p1 already has 3 marks (closed). Hits single → now 4 marks. 1 overflow mark.
      expect(
        computePointsFromOverflow(
          playerMarksOnTarget: {'p1': 3, 'p2': 1},
          playerId: 'p1',
          target: '20',
          multiplierApplied: 1,
          basePoints: 20,
        ),
        20,
      );
    });

    test('own marks == 5 (was 3, hit double), opponent not closed → basePoints * 2', () {
      // p1 already has 3 marks. Hits double → now 5 marks. 2 overflow marks.
      expect(
        computePointsFromOverflow(
          playerMarksOnTarget: {'p1': 3, 'p2': 1},
          playerId: 'p1',
          target: '20',
          multiplierApplied: 2,
          basePoints: 20,
        ),
        40,
      );
    });

    test('own marks > 3 but ALL opponents closed → 0 points (number dead)', () {
      expect(
        computePointsFromOverflow(
          playerMarksOnTarget: {'p1': 3, 'p2': 3},
          playerId: 'p1',
          target: '20',
          multiplierApplied: 1,
          basePoints: 20,
        ),
        0,
      );
    });

    test('3-player: 1 opponent closed, 1 not → points generated', () {
      // p1 already has 3 marks. Hits single. p2 closed, p3 not.
      // Points should be generated because p3 hasn't closed yet.
      expect(
        computePointsFromOverflow(
          playerMarksOnTarget: {'p1': 3, 'p2': 3, 'p3': 1},
          playerId: 'p1',
          target: '18',
          multiplierApplied: 1,
          basePoints: 18,
        ),
        18,
      );
    });

    test('bull target uses 25 as basePoints', () {
      // p1 has 3 bull marks, hits exterior (mult=1). p2 not closed.
      expect(
        computePointsFromOverflow(
          playerMarksOnTarget: {'p1': 3, 'p2': 0},
          playerId: 'p1',
          target: 'bull',
          multiplierApplied: 1,
          basePoints: 25,
        ),
        25,
      );
    });

    test('closing mark itself (from 2 marks + single): surplus=0, points=0', () {
      // Before: p1 has 2 marks. After single = 3 exactly. 0 surplus.
      // The marks map passed here is AFTER the throw = 3
      // But the function needs to know marks BEFORE to compute surplus
      // Actually the function receives marks-before-this-multiplier context.
      // With playerMarksOnTarget = {'p1': 2, 'p2': 0}, multiplierApplied=1:
      // p1 will have 3 after (exactly closed), surplus = 0.
      expect(
        computePointsFromOverflow(
          playerMarksOnTarget: {'p1': 2, 'p2': 0},
          playerId: 'p1',
          target: '17',
          multiplierApplied: 1,
          basePoints: 17,
        ),
        0,
      );
    });

    test('2 marks + double = 4 marks: 1 surplus, opponent not closed → basePoints', () {
      // p1 has 2 marks, hits double → 4 marks. Need 3 to close, so 1 mark surplus.
      expect(
        computePointsFromOverflow(
          playerMarksOnTarget: {'p1': 2, 'p2': 0},
          playerId: 'p1',
          target: '17',
          multiplierApplied: 2,
          basePoints: 17,
        ),
        17,
      );
    });
  });

  // -----------------------------------------------------------------------
  // isCricketWinner
  // -----------------------------------------------------------------------
  group('isCricketWinner', () {
    CricketMarksState makeFullyClosedState({
      required String playerId,
      required List<String> playerIds,
      required int points,
    }) {
      final marks = <String, Map<String, int>>{};
      for (final pid in playerIds) {
        marks[pid] = {
          for (final t in CricketMarksState.cricketTargets)
            t: pid == playerId ? 3 : 0,
        };
      }
      final pts = <String, int>{};
      for (final pid in playerIds) {
        pts[pid] = pid == playerId ? points : 0;
      }
      return CricketMarksState(
        marksByPlayer: marks,
        pointsByPlayer: pts,
      );
    }

    test('player closed all 7 targets AND pts >= all opponents → true', () {
      final state = makeFullyClosedState(
        playerId: 'p1',
        playerIds: ['p1', 'p2'],
        points: 80,
      );
      expect(
        isCricketWinner(state: state, playerId: 'p1', playerIds: ['p1', 'p2']),
        isTrue,
      );
    });

    test('player closed all but has fewer pts than one opponent → false', () {
      final state = CricketMarksState(
        marksByPlayer: {
          'p1': {for (final t in CricketMarksState.cricketTargets) t: 3},
          'p2': {for (final t in CricketMarksState.cricketTargets) t: 0},
        },
        pointsByPlayer: {'p1': 10, 'p2': 50},
      );
      expect(
        isCricketWinner(state: state, playerId: 'p1', playerIds: ['p1', 'p2']),
        isFalse,
      );
    });

    test('player has more pts but one target not closed → false', () {
      final marks = {
        'p1': {
          '15': 3, '16': 3, '17': 3, '18': 3, '19': 3, '20': 3,
          'bull': 2, // not closed!
        },
        'p2': {for (final t in CricketMarksState.cricketTargets) t: 0},
      };
      final state = CricketMarksState(
        marksByPlayer: marks,
        pointsByPlayer: {'p1': 200, 'p2': 0},
      );
      expect(
        isCricketWinner(state: state, playerId: 'p1', playerIds: ['p1', 'p2']),
        isFalse,
      );
    });

    test('3-player all-closed pts comparison: winner has highest pts', () {
      final state = CricketMarksState(
        marksByPlayer: {
          'p1': {for (final t in CricketMarksState.cricketTargets) t: 3},
          'p2': {for (final t in CricketMarksState.cricketTargets) t: 3},
          'p3': {for (final t in CricketMarksState.cricketTargets) t: 3},
        },
        pointsByPlayer: {'p1': 80, 'p2': 60, 'p3': 40},
      );
      expect(
        isCricketWinner(state: state, playerId: 'p1', playerIds: ['p1', 'p2', 'p3']),
        isTrue,
      );
      expect(
        isCricketWinner(state: state, playerId: 'p2', playerIds: ['p1', 'p2', 'p3']),
        isFalse,
      );
    });

    test('3-player: player2 closed all with tied pts → false (must be >=)', () {
      final state = CricketMarksState(
        marksByPlayer: {
          'p1': {for (final t in CricketMarksState.cricketTargets) t: 3},
          'p2': {for (final t in CricketMarksState.cricketTargets) t: 3},
          'p3': {for (final t in CricketMarksState.cricketTargets) t: 0},
        },
        pointsByPlayer: {'p1': 50, 'p2': 50, 'p3': 0},
      );
      // p1 closed all and pts == p2 pts, so p1 wins (>=)
      expect(
        isCricketWinner(state: state, playerId: 'p1', playerIds: ['p1', 'p2', 'p3']),
        isTrue,
      );
    });
  });
}
