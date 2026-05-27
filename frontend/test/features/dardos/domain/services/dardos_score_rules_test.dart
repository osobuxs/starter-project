import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/services/dardos_score_rules.dart';

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
  bool isMiss = false,
  int? remainingAfter,
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
    isMiss: isMiss,
    isBust: isBust,
    remainingAfter: remainingAfter,
    cricketPointsScored: 0,
    timestamp: 0,
    createdBy: 'uid',
  );
}

void main() {
  // -----------------------------------------------------------------------
  // isBust
  // -----------------------------------------------------------------------
  group('isBust', () {
    test('bust when remainingAfter < 0 (overshoot)', () {
      // remainingBefore=10, dartPoints=15 → remainingAfter=-5
      expect(
        isBust(
          remainingBefore: 10,
          dartPoints: 15,
          dartMultiplier: 1,
          doubleOut: true,
        ),
        isTrue,
      );
    });

    test('bust when remainingAfter == 1 with doubleOut=true', () {
      // remainingBefore=3, dartPoints=2 → remainingAfter=1
      expect(
        isBust(
          remainingBefore: 3,
          dartPoints: 2,
          dartMultiplier: 1,
          doubleOut: true,
        ),
        isTrue,
      );
    });

    test('bust when remainingAfter == 0 with doubleOut=true and multiplier != 2 (single)', () {
      // remainingBefore=20, dartPoints=20, multiplier=1 → lands on 0 with single
      expect(
        isBust(
          remainingBefore: 20,
          dartPoints: 20,
          dartMultiplier: 1,
          doubleOut: true,
        ),
        isTrue,
      );
    });

    test('NOT bust when remainingAfter == 0 with doubleOut=true and number==50 (bull inner = double)', () {
      // bull interior: number=50, multiplier=2 → valid checkout
      expect(
        isBust(
          remainingBefore: 50,
          dartPoints: 50,
          dartMultiplier: 2,
          doubleOut: true,
        ),
        isFalse,
      );
    });

    test('NOT bust when remainingAfter == 0 with doubleOut=false (any dart valid)', () {
      expect(
        isBust(
          remainingBefore: 20,
          dartPoints: 20,
          dartMultiplier: 1,
          doubleOut: false,
        ),
        isFalse,
      );
    });

    test('NOT bust when remainingAfter > 1 with doubleOut=true', () {
      // remainingBefore=100, dartPoints=60 → remainingAfter=40
      expect(
        isBust(
          remainingBefore: 100,
          dartPoints: 60,
          dartMultiplier: 3,
          doubleOut: true,
        ),
        isFalse,
      );
    });

    test('NOT bust when remainingAfter > 1 with doubleOut=false', () {
      expect(
        isBust(
          remainingBefore: 100,
          dartPoints: 60,
          dartMultiplier: 3,
          doubleOut: false,
        ),
        isFalse,
      );
    });

    test('bust when remainingAfter == 1 with doubleOut=false does NOT bust (only doubleOut matters)', () {
      // When doubleOut is false, reaching 1 is NOT a bust
      expect(
        isBust(
          remainingBefore: 3,
          dartPoints: 2,
          dartMultiplier: 1,
          doubleOut: false,
        ),
        isFalse,
      );
    });

    test('valid double checkout is NOT bust (D20=40)', () {
      expect(
        isBust(
          remainingBefore: 40,
          dartPoints: 40,
          dartMultiplier: 2,
          doubleOut: true,
        ),
        isFalse,
      );
    });

    test('triple on 0 landing is bust (triple not a valid checkout for doubleOut)', () {
      // remainingBefore=60, dartPoints=60 multiplier=3 → lands on 0 but triple
      expect(
        isBust(
          remainingBefore: 60,
          dartPoints: 60,
          dartMultiplier: 3,
          doubleOut: true,
        ),
        isTrue,
      );
    });
  });

  // -----------------------------------------------------------------------
  // isValidCheckout
  // -----------------------------------------------------------------------
  group('isValidCheckout', () {
    test('valid double checkout with doubleOut=true (D20)', () {
      expect(
        isValidCheckout(
          remainingBefore: 40,
          dartPoints: 40,
          dartMultiplier: 2,
          doubleOut: true,
        ),
        isTrue,
      );
    });

    test('valid bull inner checkout with doubleOut=true', () {
      expect(
        isValidCheckout(
          remainingBefore: 50,
          dartPoints: 50,
          dartMultiplier: 2,
          doubleOut: true,
        ),
        isTrue,
      );
    });

    test('single on 0 is NOT valid checkout with doubleOut=true', () {
      expect(
        isValidCheckout(
          remainingBefore: 20,
          dartPoints: 20,
          dartMultiplier: 1,
          doubleOut: true,
        ),
        isFalse,
      );
    });

    test('any dart on exact 0 is valid checkout with doubleOut=false', () {
      expect(
        isValidCheckout(
          remainingBefore: 20,
          dartPoints: 20,
          dartMultiplier: 1,
          doubleOut: false,
        ),
        isTrue,
      );
    });

    test('NOT a checkout when dartPoints != remainingBefore', () {
      expect(
        isValidCheckout(
          remainingBefore: 40,
          dartPoints: 20,
          dartMultiplier: 2,
          doubleOut: true,
        ),
        isFalse,
      );
    });

    test('bust scenario (overshoot) is not valid checkout', () {
      expect(
        isValidCheckout(
          remainingBefore: 10,
          dartPoints: 20,
          dartMultiplier: 1,
          doubleOut: true,
        ),
        isFalse,
      );
    });
  });

  // -----------------------------------------------------------------------
  // nextScoreAfterThrow
  // -----------------------------------------------------------------------
  group('nextScoreAfterThrow', () {
    test('normal subtraction', () {
      expect(
        nextScoreAfterThrow(remainingBefore: 501, dartPoints: 60),
        441,
      );
    });

    test('subtract from 100', () {
      expect(
        nextScoreAfterThrow(remainingBefore: 100, dartPoints: 45),
        55,
      );
    });

    test('subtract to 0 (caller handles bust separately)', () {
      expect(
        nextScoreAfterThrow(remainingBefore: 40, dartPoints: 40),
        0,
      );
    });

    test('can produce negative (caller is responsible for bust logic)', () {
      // The function itself just subtracts; bust detection is separate
      expect(
        nextScoreAfterThrow(remainingBefore: 10, dartPoints: 20),
        -10,
      );
    });
  });

  // -----------------------------------------------------------------------
  // turnTotal and isTurnComplete
  // -----------------------------------------------------------------------
  group('turnTotal and isTurnComplete', () {
    test('turnTotal sums all darts in turn', () {
      final darts = [
        makeThrow(number: 20, multiplier: 3, dartIndex: 0), // 60
        makeThrow(number: 20, multiplier: 1, dartIndex: 1), // 20
        makeThrow(number: 5, multiplier: 1, dartIndex: 2),  // 5
      ];
      expect(turnTotal(darts), 85);
    });

    test('turnTotal returns 0 for empty list', () {
      expect(turnTotal([]), 0);
    });

    test('isTurnComplete when 3 darts thrown', () {
      final darts = [
        makeThrow(number: 20, multiplier: 1, dartIndex: 0),
        makeThrow(number: 20, multiplier: 1, dartIndex: 1),
        makeThrow(number: 20, multiplier: 1, dartIndex: 2),
      ];
      expect(isTurnComplete(darts), isTrue);
    });

    test('isTurnComplete when bust on dart 1 (dartIndex=0)', () {
      final darts = [
        makeThrow(number: 20, multiplier: 1, dartIndex: 0, isBust: true),
      ];
      expect(isTurnComplete(darts), isTrue);
    });

    test('isTurnComplete when bust on dart 2 (dartIndex=1)', () {
      final darts = [
        makeThrow(number: 20, multiplier: 1, dartIndex: 0),
        makeThrow(number: 20, multiplier: 1, dartIndex: 1, isBust: true),
      ];
      expect(isTurnComplete(darts), isTrue);
    });

    test('NOT complete when only 2 non-bust darts thrown', () {
      final darts = [
        makeThrow(number: 20, multiplier: 1, dartIndex: 0),
        makeThrow(number: 20, multiplier: 1, dartIndex: 1),
      ];
      expect(isTurnComplete(darts), isFalse);
    });

    test('NOT complete when only 1 non-bust dart thrown', () {
      final darts = [
        makeThrow(number: 20, multiplier: 1, dartIndex: 0),
      ];
      expect(isTurnComplete(darts), isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // computeRemainingScore
  // -----------------------------------------------------------------------
  group('computeRemainingScore', () {
    test('501 normal sequence subtracts correctly', () {
      final throws = [
        makeThrow(
          id: 't1', playerId: 'p1', turnIndex: 0, dartIndex: 0,
          number: 20, multiplier: 3, // 60
        ),
        makeThrow(
          id: 't2', playerId: 'p1', turnIndex: 0, dartIndex: 1,
          number: 20, multiplier: 1, // 20
        ),
        makeThrow(
          id: 't3', playerId: 'p1', turnIndex: 0, dartIndex: 2,
          number: 5, multiplier: 1, // 5
        ),
      ];
      // 501 - 60 - 20 - 5 = 416
      expect(
        computeRemainingScore(
          startScore: 501,
          throwsInLeg: throws,
          playerId: 'p1',
        ),
        416,
      );
    });

    test('301 normal sequence', () {
      final throws = [
        makeThrow(id: 't1', playerId: 'p1', dartIndex: 0, number: 20, multiplier: 3), // 60
        makeThrow(id: 't2', playerId: 'p1', dartIndex: 1, number: 19, multiplier: 3), // 57
      ];
      // 301 - 60 - 57 = 184
      expect(
        computeRemainingScore(
          startScore: 301,
          throwsInLeg: throws,
          playerId: 'p1',
        ),
        184,
      );
    });

    test('bust darts excluded from subtraction', () {
      final throws = [
        makeThrow(
          id: 't1', playerId: 'p1', dartIndex: 0,
          number: 20, multiplier: 1, // 20 → remaining=480
        ),
        makeThrow(
          id: 't2', playerId: 'p1', dartIndex: 1,
          number: 20, multiplier: 3, isBust: true, // bust: ignored
        ),
      ];
      // Only first dart counts → 501 - 20 = 481
      // But bust means the WHOLE TURN is reverted.
      // computeRemainingScore only subtracts non-bust darts, so 501-20 = 481
      // (the BLoC is responsible for reverting the full turn on bust)
      expect(
        computeRemainingScore(
          startScore: 501,
          throwsInLeg: throws,
          playerId: 'p1',
        ),
        481,
      );
    });

    test('multi-player: only counts target player darts', () {
      final throws = [
        makeThrow(id: 't1', playerId: 'p1', dartIndex: 0, number: 20, multiplier: 3), // p1: 60
        makeThrow(id: 't2', playerId: 'p2', dartIndex: 0, number: 20, multiplier: 3), // p2: 60
        makeThrow(id: 't3', playerId: 'p1', dartIndex: 1, number: 20, multiplier: 1), // p1: 20
      ];
      // p1 remaining = 501 - 60 - 20 = 421
      expect(
        computeRemainingScore(
          startScore: 501,
          throwsInLeg: throws,
          playerId: 'p1',
        ),
        421,
      );
    });

    test('returns startScore when no throws for player', () {
      expect(
        computeRemainingScore(
          startScore: 501,
          throwsInLeg: [],
          playerId: 'p1',
        ),
        501,
      );
    });
  });
}
