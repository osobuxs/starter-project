import 'package:equatable/equatable.dart';

class HandEntity extends Equatable {
  final int handNumber;
  final String dealerId; // participantId of dealer for this hand
  final Map<String, int> scores; // {participantId: points}
  final int timestamp;

  // Snapshot of the game right before this hand was closed. Lets the last
  // hand be reopened and corrected. Null on legacy hands (not editable).
  final Map<String, dynamic>? participantStatesBefore;
  final String? dealerIdBefore;

  /// Whether closing this hand finished the game, and who won it.
  final bool finishedGame;
  final String? winnerId;

  const HandEntity({
    required this.handNumber,
    required this.dealerId,
    this.scores = const {},
    required this.timestamp,
    this.participantStatesBefore,
    this.dealerIdBefore,
    this.finishedGame = false,
    this.winnerId,
  });

  bool get canBeEdited =>
      participantStatesBefore != null && dealerIdBefore != null;

  HandEntity copyWith({
    int? handNumber,
    String? dealerId,
    Map<String, int>? scores,
    int? timestamp,
    Map<String, dynamic>? participantStatesBefore,
    String? dealerIdBefore,
    bool? finishedGame,
    String? winnerId,
  }) {
    return HandEntity(
      handNumber: handNumber ?? this.handNumber,
      dealerId: dealerId ?? this.dealerId,
      scores: scores ?? this.scores,
      timestamp: timestamp ?? this.timestamp,
      participantStatesBefore:
          participantStatesBefore ?? this.participantStatesBefore,
      dealerIdBefore: dealerIdBefore ?? this.dealerIdBefore,
      finishedGame: finishedGame ?? this.finishedGame,
      winnerId: winnerId ?? this.winnerId,
    );
  }

  @override
  List<Object?> get props => [
        handNumber,
        dealerId,
        scores,
        timestamp,
        participantStatesBefore,
        dealerIdBefore,
        finishedGame,
        winnerId,
      ];
}
