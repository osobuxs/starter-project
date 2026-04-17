import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/services/game_round_rules.dart';

void main() {
  group('buildRoundScoresForActivePlayers', () {
    test('includes only active participants from entered scores', () {
      final result = buildRoundScoresForActivePlayers(
        participantIds: const ['p1', 'p2', 'p3'],
        participantStates: const {
          'p1': {'score': 10, 'status': 'active'},
          'p2': {'score': 20, 'status': 'eliminated'},
          'p3': {'score': 30, 'status': 'active'},
        },
        enteredScores: const {
          'p1': 5,
          'p2': 99,
          'p3': 7,
        },
      );

      expect(result, {'p1': 5, 'p3': 7});
    });

    test('defaults missing active player score to zero', () {
      final result = buildRoundScoresForActivePlayers(
        participantIds: const ['p1', 'p2'],
        participantStates: const {
          'p1': {'score': 10, 'status': 'active'},
          'p2': {'score': 20, 'status': 'active'},
        },
        enteredScores: const {
          'p1': 3,
        },
      );

      expect(result, {'p1': 3, 'p2': 0});
    });
  });

  group('applyRoundScoresAndFindOverLimit', () {
    test('returns over-limit active players after applying round points', () {
      final result = applyRoundScoresAndFindOverLimit(
        participantStates: const {
          'p1': {'score': 80, 'status': 'active'},
          'p2': {'score': 95, 'status': 'active'},
          'p3': {'score': 60, 'status': 'eliminated'},
        },
        roundScores: const {'p1': 10, 'p2': 6, 'p3': 100},
      );

      expect(
        result.updatedStates,
        {
          'p1': {'score': 90, 'status': 'active'},
          'p2': {'score': 101, 'status': 'active'},
          'p3': {'score': 60, 'status': 'eliminated'},
        },
      );
      expect(result.overLimitParticipantIds, ['p2']);
    });

    test('keeps all players out of list when no one exceeds 100', () {
      final result = applyRoundScoresAndFindOverLimit(
        participantStates: const {
          'p1': {'score': 70, 'status': 'active'},
          'p2': {'score': 99, 'status': 'active'},
        },
        roundScores: const {'p1': 10, 'p2': 1},
      );

      expect(result.overLimitParticipantIds, isEmpty);
      expect(result.updatedStates['p2'], {'score': 100, 'status': 'active'});
    });
  });

  group('applyRetryDecision', () {
    test('rejoin sets player score to highest active score', () {
      final result = applyRetryDecision(
        participantStates: const {
          'p1': {'score': 104, 'status': 'active'},
          'p2': {'score': 96, 'status': 'active'},
          'p3': {'score': 89, 'status': 'active'},
        },
        participantId: 'p1',
        rejoin: true,
      );

      expect(result['p1'], {'score': 96, 'status': 'active'});
    });

    test('reject rejoin eliminates player and keeps score', () {
      final result = applyRetryDecision(
        participantStates: const {
          'p1': {'score': 104, 'status': 'active'},
          'p2': {'score': 96, 'status': 'active'},
        },
        participantId: 'p1',
        rejoin: false,
      );

      expect(result['p1'], {'score': 104, 'status': 'eliminated'});
    });

    test('rejoin uses override score when provided', () {
      final result = applyRetryDecision(
        participantStates: const {
          'p1': {'score': 110, 'status': 'active'},
          'p2': {'score': 96, 'status': 'active'},
          'p3': {'score': 91, 'status': 'active'},
        },
        participantId: 'p1',
        rejoin: true,
        rejoinScoreOverride: 93,
      );

      expect(result['p1'], {'score': 93, 'status': 'active'});
    });
  });

  group('determineAutomaticWinner', () {
    test('returns winner when only one active player remains under 100', () {
      final winnerId = determineAutomaticWinner(
        const {
          'p1': {'score': 99, 'status': 'active'},
          'p2': {'score': 102, 'status': 'active'},
          'p3': {'score': 107, 'status': 'eliminated'},
        },
      );

      expect(winnerId, 'p1');
    });

    test('returns null when two active players remain under 100', () {
      final winnerId = determineAutomaticWinner(
        const {
          'p1': {'score': 99, 'status': 'active'},
          'p2': {'score': 98, 'status': 'active'},
        },
      );

      expect(winnerId, isNull);
    });
  });
}
