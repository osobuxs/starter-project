import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/services/board_history.dart';

GameEntity _game({
  required Map<String, dynamic> states,
  required List<HandEntity> hands,
}) {
  return GameEntity(
    id: 'g1',
    name: 'Partida',
    date: 1,
    participantIds: states.keys.toList(),
    currentDealerId: states.keys.first,
    currentHand: hands.length + 1,
    participantStates: states,
    hands: hands,
  );
}

HandEntity _hand(
  int number,
  Map<String, int> scores, {
  Map<String, int>? rejoinScores,
}) {
  return HandEntity(
    handNumber: number,
    dealerId: 'p1',
    scores: scores,
    timestamp: number,
    rejoinScores: rejoinScores,
  );
}

void main() {
  group('eliminationHandByParticipant', () {
    test('uses the explicit eliminatedAtHand when present', () {
      final history = buildBoardHistory(_game(
        states: {
          'p1': {'score': 120, 'status': 'eliminated', 'eliminatedAtHand': 2},
          'p2': {'score': 30, 'status': 'active'},
        },
        hands: [
          _hand(1, {'p1': 110, 'p2': 10}),
          _hand(2, {'p1': 10, 'p2': 20}),
        ],
      ));

      expect(history.eliminationHandByParticipant, {'p1': 2});
    });

    test('infers the hand where a legacy eliminated player went over', () {
      final history = buildBoardHistory(_game(
        states: {
          'p1': {'score': 105, 'status': 'eliminated'},
          'p2': {'score': 40, 'status': 'active'},
          'p3': {'score': 50, 'status': 'active'},
        },
        hands: [
          _hand(1, {'p1': 60, 'p2': 20, 'p3': 25}),
          _hand(2, {'p1': 45, 'p2': 20, 'p3': 25}),
          _hand(3, {'p2': 0, 'p3': 0}),
        ],
      ));

      expect(history.eliminationHandByParticipant, {'p1': 2});
    });

    test('a legacy player that rejoined and later went out is eliminated at '
        'the last hand, not at the rejoin hand', () {
      final history = buildBoardHistory(_game(
        states: {
          'p1': {'score': 112, 'status': 'eliminated', 'rejoinedAtHand': 1},
          'p2': {'score': 70, 'status': 'active'},
          'p3': {'score': 60, 'status': 'active'},
        },
        hands: [
          _hand(1, {'p1': 101, 'p2': 50, 'p3': 40}),
          _hand(2, {'p1': 62, 'p2': 20, 'p3': 20}),
          _hand(3, {'p2': 0, 'p3': 0}),
        ],
      ));

      expect(history.eliminationHandByParticipant, {'p1': 2});
      expect(history.rejoinScoresByHand, {
        1: {'p1': 50},
      });
    });

    test('active players are never marked as eliminated', () {
      final history = buildBoardHistory(_game(
        states: {
          'p1': {'score': 90, 'status': 'active'},
          'p2': {'score': 80, 'status': 'active'},
        },
        hands: [
          _hand(1, {'p1': 90, 'p2': 80}),
        ],
      ));

      expect(history.eliminationHandByParticipant, isEmpty);
      expect(history.rejoinScoresByHand, isEmpty);
    });
  });

  group('rejoinScoresByHand', () {
    test('uses the persisted rejoin scores of the hand', () {
      final history = buildBoardHistory(_game(
        states: {
          'p1': {'score': 77, 'status': 'active', 'rejoinedAtHand': 1},
          'p2': {'score': 60, 'status': 'active'},
        },
        hands: [
          _hand(1, {'p1': 105, 'p2': 60}, rejoinScores: {'p1': 77}),
        ],
      ));

      expect(history.rejoinScoresByHand, {
        1: {'p1': 77},
      });
    });

    test('a persisted empty map means nobody rejoined in that hand', () {
      final history = buildBoardHistory(_game(
        states: {
          'p1': {'score': 105, 'status': 'eliminated'},
          'p2': {'score': 60, 'status': 'active'},
          'p3': {'score': 50, 'status': 'active'},
        },
        hands: [
          _hand(1, {'p1': 105, 'p2': 60, 'p3': 50}, rejoinScores: {}),
        ],
      ));

      expect(history.rejoinScoresByHand, isEmpty);
      expect(history.eliminationHandByParticipant, {'p1': 1});
    });

    test('infers a legacy rejoin score as the highest total at or under the '
        'limit after that hand', () {
      final history = buildBoardHistory(_game(
        states: {
          'p1': {'score': 85, 'status': 'active', 'rejoinedAtHand': 2},
          'p2': {'score': 85, 'status': 'active'},
          'p3': {'score': 40, 'status': 'active'},
        },
        hands: [
          _hand(1, {'p1': 80, 'p2': 50, 'p3': 20}),
          _hand(2, {'p1': 30, 'p2': 35, 'p3': 20}),
        ],
      ));

      expect(history.rejoinScoresByHand, {
        2: {'p1': 85},
      });
    });

    test('infers every legacy rejoin, not only the last one', () {
      final history = buildBoardHistory(_game(
        states: {
          'p1': {'score': 95, 'status': 'active', 'rejoinedAtHand': 3},
          'p2': {'score': 95, 'status': 'active'},
        },
        hands: [
          _hand(1, {'p1': 101, 'p2': 40}),
          _hand(2, {'p1': 10, 'p2': 50}),
          _hand(3, {'p1': 60, 'p2': 5}),
        ],
      ));

      expect(history.rejoinScoresByHand, {
        1: {'p1': 40},
        3: {'p1': 95},
      });
    });

    test('mixes persisted and legacy hands in the same game', () {
      final history = buildBoardHistory(_game(
        states: {
          'p1': {'score': 70, 'status': 'active', 'rejoinedAtHand': 2},
          'p2': {'score': 70, 'status': 'active'},
          'p3': {'score': 30, 'status': 'active'},
        },
        hands: [
          _hand(1, {'p1': 101, 'p2': 30, 'p3': 10}),
          _hand(2, {'p1': 80, 'p2': 40, 'p3': 20}, rejoinScores: {'p1': 70}),
        ],
      ));

      expect(history.rejoinScoresByHand, {
        1: {'p1': 30},
        2: {'p1': 70},
      });
    });
  });

  group('mid-game joins', () {
    test('a joined participant starts from its join score and its entry is '
        'shown in the hand before it started playing', () {
      final history = buildBoardHistory(_game(
        states: {
          'p1': {'score': 60, 'status': 'active'},
          'p2': {'score': 90, 'status': 'active'},
          'p3': {
            'score': 90,
            'status': 'active',
            'joinedAtHand': 3,
            'joinScore': 80,
            'rejoinedAtHand': 3,
          },
        },
        hands: [
          _hand(1, {'p1': 30, 'p2': 40}),
          _hand(2, {'p1': 20, 'p2': 40}),
          _hand(3, {'p1': 10, 'p2': 10, 'p3': 25}),
        ],
      ));

      expect(history.joinScoresByHand, {
        2: {'p3': 80},
      });
      // 80 + 25 = 105 went over and rejoined with the highest total (90).
      expect(history.rejoinScoresByHand, {
        3: {'p3': 90},
      });
    });

    test('legacy joins (entry written into the previous hand) need no join '
        'entry', () {
      final history = buildBoardHistory(_game(
        states: {
          'p1': {'score': 50, 'status': 'active'},
          'p2': {'score': 60, 'status': 'active'},
        },
        hands: [
          _hand(1, {'p1': 50, 'p2': 50}),
          _hand(2, {'p1': 0, 'p2': 10}),
        ],
      ));

      expect(history.joinScoresByHand, isEmpty);
    });
  });
}
