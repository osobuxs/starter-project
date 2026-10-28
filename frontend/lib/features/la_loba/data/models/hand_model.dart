import 'package:news_app_clean_architecture/features/la_loba/domain/entities/hand.dart';

class HandModel extends HandEntity {
  const HandModel({
    required int handNumber,
    required String dealerId,
    Map<String, int> scores = const {},
    required int timestamp,
    Map<String, dynamic>? participantStatesBefore,
    String? dealerIdBefore,
    bool finishedGame = false,
    String? winnerId,
    Map<String, int>? rejoinScores,
  }) : super(
    handNumber: handNumber,
    dealerId: dealerId,
    scores: scores,
    timestamp: timestamp,
    participantStatesBefore: participantStatesBefore,
    dealerIdBefore: dealerIdBefore,
    finishedGame: finishedGame,
    winnerId: winnerId,
    rejoinScores: rejoinScores,
  );

  factory HandModel.fromFirestore(Map<String, dynamic> json, String docId) {
    final statesBefore = json['participantStatesBefore'];
    final rejoinScores = json['rejoinScores'];
    return HandModel(
      handNumber: json['handNumber'] as int,
      dealerId: json['dealerId'] as String,
      scores: Map<String, int>.from(json['scores'] as Map? ?? {}),
      timestamp: json['timestamp'] as int,
      // Legacy hands have no snapshot and stay non-editable.
      participantStatesBefore: statesBefore is Map
          ? Map<String, dynamic>.from(statesBefore)
          : null,
      dealerIdBefore: json['dealerIdBefore'] as String?,
      finishedGame: json['finishedGame'] as bool? ?? false,
      winnerId: json['winnerId'] as String?,
      // Legacy hands have no rejoin scores (null, not empty).
      rejoinScores:
          rejoinScores is Map ? Map<String, int>.from(rejoinScores) : null,
    );
  }

  factory HandModel.fromEntity(HandEntity entity) {
    return HandModel(
      handNumber: entity.handNumber,
      dealerId: entity.dealerId,
      scores: entity.scores,
      timestamp: entity.timestamp,
      participantStatesBefore: entity.participantStatesBefore,
      dealerIdBefore: entity.dealerIdBefore,
      finishedGame: entity.finishedGame,
      winnerId: entity.winnerId,
      rejoinScores: entity.rejoinScores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'handNumber': handNumber,
      'dealerId': dealerId,
      'scores': scores,
      'timestamp': timestamp,
      if (participantStatesBefore != null)
        'participantStatesBefore': participantStatesBefore,
      if (dealerIdBefore != null) 'dealerIdBefore': dealerIdBefore,
      'finishedGame': finishedGame,
      'winnerId': winnerId,
      if (rejoinScores != null) 'rejoinScores': rejoinScores,
    };
  }

  HandEntity toEntity() => HandEntity(
    handNumber: handNumber,
    dealerId: dealerId,
    scores: scores,
    timestamp: timestamp,
    participantStatesBefore: participantStatesBefore,
    dealerIdBefore: dealerIdBefore,
    finishedGame: finishedGame,
    winnerId: winnerId,
    rejoinScores: rejoinScores,
  );
}
