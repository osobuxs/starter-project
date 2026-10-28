import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/domain/services/truco_score_rules.dart';

void main() {
  group('trucoHalfOf', () {
    test('splits 18 into 9 malas and 30 into 15 malas', () {
      expect(trucoHalfOf(18), 9);
      expect(trucoHalfOf(30), 15);
    });
  });

  group('isTrucoBuenas', () {
    test('points up to half are malas, above half are buenas', () {
      expect(isTrucoBuenas(0, 30), isFalse);
      expect(isTrucoBuenas(15, 30), isFalse);
      expect(isTrucoBuenas(16, 30), isTrue);
      expect(isTrucoBuenas(9, 18), isFalse);
      expect(isTrucoBuenas(10, 18), isTrue);
    });
  });

  group('applyTrucoHand', () {
    test('adds each team points to its total', () {
      final outcome = applyTrucoHand(
        scoreA: 3,
        scoreB: 5,
        pointsA: 2,
        pointsB: 4,
        targetScore: 30,
      );

      expect(outcome.scoreA, 5);
      expect(outcome.scoreB, 9);
      expect(outcome.winner, isNull);
      expect(outcome.isUnresolvedTie, isFalse);
    });

    test('negative points subtract and totals never go below zero', () {
      final outcome = applyTrucoHand(
        scoreA: 3,
        scoreB: 10,
        pointsA: -5,
        pointsB: -2,
        targetScore: 30,
      );

      expect(outcome.scoreA, 0);
      expect(outcome.scoreB, 8);
    });

    test('totals never exceed the target and reaching it wins', () {
      final outcome = applyTrucoHand(
        scoreA: 16,
        scoreB: 4,
        pointsA: 5,
        pointsB: 0,
        targetScore: 18,
      );

      expect(outcome.scoreA, 18);
      expect(outcome.winner, TrucoTeamSide.a);
    });

    test('when both reach the target the higher raw total wins', () {
      final outcome = applyTrucoHand(
        scoreA: 28,
        scoreB: 29,
        pointsA: 5,
        pointsB: 2,
        targetScore: 30,
      );

      expect(outcome.scoreA, 30);
      expect(outcome.scoreB, 30);
      expect(outcome.winner, TrucoTeamSide.a);
    });

    test('when both reach the target with the same total it is unresolved', () {
      final outcome = applyTrucoHand(
        scoreA: 28,
        scoreB: 28,
        pointsA: 2,
        pointsB: 2,
        targetScore: 30,
      );

      expect(outcome.winner, isNull);
      expect(outcome.isUnresolvedTie, isTrue);
    });
  });

  group('trucoMatchstickLayout', () {
    test('zero points draws no sticks', () {
      final layout = trucoMatchstickLayout(points: 0, targetScore: 30);

      expect(layout.malas, isEmpty);
      expect(layout.buenas, isEmpty);
    });

    test('groups malas in fives with a partial last group', () {
      final layout = trucoMatchstickLayout(points: 12, targetScore: 30);

      expect(layout.malas, [5, 5, 2]);
      expect(layout.buenas, isEmpty);
    });

    test('points above half overflow into buenas, regrouped from zero', () {
      final layout = trucoMatchstickLayout(points: 17, targetScore: 30);

      expect(layout.malas, [5, 5, 5]);
      expect(layout.buenas, [2]);
    });

    test('a half of 9 closes malas with a group of four', () {
      final full = trucoMatchstickLayout(points: 18, targetScore: 18);

      expect(full.malas, [5, 4]);
      expect(full.buenas, [5, 4]);
    });

    test('points are clamped to the target', () {
      final layout = trucoMatchstickLayout(points: 40, targetScore: 30);

      expect(layout.malas, [5, 5, 5]);
      expect(layout.buenas, [5, 5, 5]);
    });
  });

  group('trucoSeatingOrder', () {
    test('alternates team A and team B players around the table', () {
      expect(
        trucoSeatingOrder(['a1', 'a2', 'a3'], ['b1', 'b2', 'b3']),
        ['a1', 'b1', 'a2', 'b2', 'a3', 'b3'],
      );
    });

    test('works for a single player per team', () {
      expect(trucoSeatingOrder(['a1'], ['b1']), ['a1', 'b1']);
    });
  });
}
