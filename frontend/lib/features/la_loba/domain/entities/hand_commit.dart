import 'package:equatable/equatable.dart';

import 'hand.dart';

/// Everything that must be persisted atomically when a hand is closed:
/// the hand document plus the resulting game state (and, when the hand
/// finishes the game, the winner and participant stats).
class HandCommit extends Equatable {
  final String gameId;
  final HandEntity hand;
  final List<String> participantIds;
  final Map<String, dynamic> participantStates;
  final String nextDealerId;
  final int nextHandNumber;
  final String? winnerId;

  const HandCommit({
    required this.gameId,
    required this.hand,
    required this.participantIds,
    required this.participantStates,
    required this.nextDealerId,
    required this.nextHandNumber,
    this.winnerId,
  });

  @override
  List<Object?> get props => [
        gameId,
        hand,
        participantIds,
        participantStates,
        nextDealerId,
        nextHandNumber,
        winnerId,
      ];
}
