import 'package:equatable/equatable.dart';

import 'hand.dart';

/// Everything that must be persisted atomically when a hand is closed:
/// the hand document plus the resulting game state (and, when the hand
/// finishes the game, the winner and participant stats).
///
/// When [isEdit] is true the hand document is overwritten and the game
/// status/winner are always rewritten; [revertWinnerId] is the winner the
/// original hand produced, whose stats must be undone first.
class HandCommit extends Equatable {
  final String gameId;
  final HandEntity hand;
  final List<String> participantIds;
  final Map<String, dynamic> participantStates;
  final String nextDealerId;
  final int nextHandNumber;
  final String? winnerId;
  final bool isEdit;
  final String? revertWinnerId;

  const HandCommit({
    required this.gameId,
    required this.hand,
    required this.participantIds,
    required this.participantStates,
    required this.nextDealerId,
    required this.nextHandNumber,
    this.winnerId,
    this.isEdit = false,
    this.revertWinnerId,
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
        isEdit,
        revertWinnerId,
      ];
}
