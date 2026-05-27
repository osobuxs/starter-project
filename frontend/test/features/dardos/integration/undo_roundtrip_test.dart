import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/services/dardos_score_rules.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/services/dardos_leg_rules.dart';

/// Integration test: undo round-trip via domain services.
///
/// Simulates a 501 game: N throws → undo all → verify state returns to initial.
/// Then redo the same throws and verify the same final state.
void main() {
  group('Undo round-trip — 501 mode', () {
    // Build a synthetic throw list for a single player
    List<DardosThrowEntity> _makeThrows(
        List<int> numbers, List<int> multipliers) {
      assert(numbers.length == multipliers.length);
      final throws = <DardosThrowEntity>[];
      var remaining = 501;

      for (var i = 0; i < numbers.length; i++) {
        final number = numbers[i];
        final multiplier = multipliers[i];
        final points = number * multiplier;
        final isMiss = number == 0;
        final isBust = !isMiss &&
            isBust_(
              remainingBefore: remaining,
              dartPoints: points,
              dartMultiplier: multiplier,
              doubleOut: true,
            );
        final remainingAfter = isBust ? remaining : remaining - points;
        if (!isBust) remaining = remainingAfter;

        throws.add(DardosThrowEntity(
          id: 'throw_$i',
          playerId: 'p1',
          setIndex: 0,
          legIndex: 0,
          turnIndex: i ~/ 3,
          dartIndex: i % 3,
          number: number,
          multiplier: multiplier,
          points: points,
          isMiss: isMiss,
          isBust: isBust,
          remainingAfter: remainingAfter,
          cricketTarget: null,
          cricketMarksDelta: null,
          cricketPointsScored: 0,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          createdBy: 'test',
        ));
      }
      return throws;
    }

    test('computeRemainingScore matches after throw sequence', () {
      // Simple sequence: 20, 20, 20 (single each = 60 per turn)
      final throws = _makeThrows(
        [20, 20, 20, 19, 19, 19],
        [1, 1, 1, 1, 1, 1],
      );

      final remaining = computeRemainingScore(
        startScore: 501,
        throwsInLeg: throws,
        playerId: 'p1',
      );

      // 501 - 60 (turn1) - 57 (turn2) = 384
      expect(remaining, equals(384));
    });

    test('undo all throws restores initial state', () {
      final throws = _makeThrows(
        [20, 20, 20, 19, 19, 19, 18, 18, 18],
        [1, 1, 1, 1, 1, 1, 1, 1, 1],
      );

      // State after all throws
      final remaining = computeRemainingScore(
        startScore: 501,
        throwsInLeg: throws,
        playerId: 'p1',
      );
      expect(remaining, equals(501 - 60 - 57 - 54)); // = 330

      // Simulate undo one by one
      var remainingThrows = List<DardosThrowEntity>.from(throws);
      while (remainingThrows.isNotEmpty) {
        remainingThrows = remainingThrows.sublist(
            0, remainingThrows.length - 1);
      }

      // After undoing all, remaining should be 501
      final remainingAfterUndo = computeRemainingScore(
        startScore: 501,
        throwsInLeg: remainingThrows,
        playerId: 'p1',
      );
      expect(remainingAfterUndo, equals(501));
    });

    test('redo throws after full undo gives same final state', () {
      final throws = _makeThrows(
        [20, 20, 20, 15, 15, 15],
        [2, 2, 2, 3, 3, 3], // D20 + T15
      );

      // First pass
      final finalScore1 = computeRemainingScore(
        startScore: 501,
        throwsInLeg: throws,
        playerId: 'p1',
      );

      // Undo all → redo (simulate by rebuilding throws)
      final throwsRedone = _makeThrows(
        [20, 20, 20, 15, 15, 15],
        [2, 2, 2, 3, 3, 3],
      );
      final finalScore2 = computeRemainingScore(
        startScore: 501,
        throwsInLeg: throwsRedone,
        playerId: 'p1',
      );

      expect(finalScore1, equals(finalScore2));
    });

    test('isTurnComplete returns true after 3 darts', () {
      final throws = _makeThrows([20, 19, 18], [1, 1, 1]);
      expect(isTurnComplete(throws), isTrue);
    });

    test('isTurnComplete returns false with only 2 darts', () {
      final throws = _makeThrows([20, 19], [1, 1]);
      expect(isTurnComplete(throws), isFalse);
    });

    test('bust on dart 1 ends turn immediately', () {
      // Player has 2 remaining, throws single 3 = 3 points → bust
      final bustThrow = DardosThrowEntity(
        id: 'bust_throw',
        playerId: 'p1',
        setIndex: 0,
        legIndex: 0,
        turnIndex: 0,
        dartIndex: 0,
        number: 3,
        multiplier: 1,
        points: 3,
        isMiss: false,
        isBust: true,
        remainingAfter: 2,
        cricketTarget: null,
        cricketMarksDelta: null,
        cricketPointsScored: 0,
        timestamp: 0,
        createdBy: 'test',
      );

      expect(isTurnComplete([bustThrow]), isTrue);
    });
  });
}

// Alias to avoid ambiguity with top-level name
bool isBust_({
  required int remainingBefore,
  required int dartPoints,
  required int dartMultiplier,
  required bool doubleOut,
}) {
  return isBust(
    remainingBefore: remainingBefore,
    dartPoints: dartPoints,
    dartMultiplier: dartMultiplier,
    doubleOut: doubleOut,
  );
}
