import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/services/game_round_rules.dart';

/// What the scoreboard needs to mark each hand: who rejoined (and with which
/// score) and in which hand every eliminated participant went out.
class BoardHistory {
  /// {handNumber: {participantId: score the participant rejoined with}}.
  final Map<int, Map<String, int>> rejoinScoresByHand;

  /// {participantId: handNumber} for participants whose final status is
  /// eliminated.
  final Map<String, int> eliminationHandByParticipant;

  /// {handNumber: {participantId: entry score}} for participants that joined
  /// mid-game, keyed by the hand right before they started playing. Legacy
  /// joins already have the entry score inside that hand's scores.
  final Map<int, Map<String, int>> joinScoresByHand;

  const BoardHistory({
    required this.rejoinScoresByHand,
    required this.eliminationHandByParticipant,
    this.joinScoresByHand = const {},
  });
}

/// Replays [game]'s hands to build the board marks.
///
/// Hands persisted with `rejoinScores` are taken as-is. Legacy hands (no
/// `rejoinScores`) are inferred: an over-limit participant rejoined when it
/// kept playing afterwards (or its state says so), and the rejoin score is
/// the one [computeRejoinBaseScore] would have produced at that hand.
BoardHistory buildBoardHistory(GameEntity game) {
  final hands = [...game.hands]
    ..sort((a, b) => a.handNumber.compareTo(b.handNumber));

  final totals = <String, int>{};
  final rejoinScoresByHand = <int, Map<String, int>>{};
  final inferredEliminationHand = <String, int>{};

  // Participants that joined mid-game start from their join score the
  // first time they show up in a hand.
  final joinScores = <String, int>{};
  final joinScoresByHand = <int, Map<String, int>>{};
  for (final participantId in game.participantIds) {
    final state = game.participantStates[participantId];
    if (state is! Map) continue;
    final joinedAtHand = state['joinedAtHand'];
    final joinScore = state['joinScore'];
    if (joinedAtHand is! int || joinScore is! int) continue;

    joinScores[participantId] = joinScore;
    final entryHand = joinedAtHand - 1;
    if (hands.any((hand) => hand.handNumber == entryHand)) {
      (joinScoresByHand[entryHand] ??= {})[participantId] = joinScore;
    }
  }

  for (var i = 0; i < hands.length; i++) {
    final hand = hands[i];

    for (final entry in hand.scores.entries) {
      totals[entry.key] =
          (totals[entry.key] ?? joinScores[entry.key] ?? 0) + entry.value;
    }

    final overLimitIds = [
      for (final participantId in hand.scores.keys)
        if ((totals[participantId] ?? 0) > 100) participantId,
    ];
    if (overLimitIds.isEmpty) continue;

    final rejoinScores = hand.rejoinScores ??
        _inferLegacyRejoinScores(
          game: game,
          hand: hand,
          laterHands: hands.sublist(i + 1),
          totals: totals,
          overLimitIds: overLimitIds,
        );

    for (final participantId in overLimitIds) {
      final rejoinScore = rejoinScores[participantId];
      if (rejoinScore != null) {
        totals[participantId] = rejoinScore;
        (rejoinScoresByHand[hand.handNumber] ??= {})[participantId] =
            rejoinScore;
      } else {
        inferredEliminationHand[participantId] = hand.handNumber;
      }
    }
  }

  final eliminationHandByParticipant = <String, int>{};
  for (final participantId in game.participantIds) {
    final state = game.participantStates[participantId];
    if (state is! Map || state['status'] != 'eliminated') continue;

    final explicitHand = state['eliminatedAtHand'];
    final eliminationHand = explicitHand is int && explicitHand > 0
        ? explicitHand
        : inferredEliminationHand[participantId];
    if (eliminationHand != null) {
      eliminationHandByParticipant[participantId] = eliminationHand;
    }
  }

  return BoardHistory(
    rejoinScoresByHand: rejoinScoresByHand,
    eliminationHandByParticipant: eliminationHandByParticipant,
    joinScoresByHand: joinScoresByHand,
  );
}

Map<String, int> _inferLegacyRejoinScores({
  required GameEntity game,
  required HandEntity hand,
  required List<HandEntity> laterHands,
  required Map<String, int> totals,
  required List<String> overLimitIds,
}) {
  final baseScore = computeRejoinBaseScore(
    participantStates: {
      for (final participantId in hand.scores.keys)
        participantId: <String, dynamic>{
          'score': totals[participantId] ?? 0,
          'status': 'active',
        },
    },
    overLimitParticipantIds: overLimitIds,
  );

  final result = <String, int>{};
  for (final participantId in overLimitIds) {
    final state = game.participantStates[participantId];
    final explicitRejoin =
        state is Map && state['rejoinedAtHand'] == hand.handNumber;
    final keptPlaying =
        laterHands.any((later) => later.scores.containsKey(participantId));
    final activeAfterLastHand = laterHands.isEmpty &&
        state is Map &&
        state['status'] == 'active';

    if (explicitRejoin || keptPlaying || activeAfterLastHand) {
      result[participantId] = baseScore;
    }
  }
  return result;
}
