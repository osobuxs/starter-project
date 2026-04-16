import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';

class PlayerModel extends PlayerEntity {
  const PlayerModel({
    super.id,
    required super.name,
    required super.gameId,
    super.totalScore,
    super.hasUsedRetry,
    super.isEliminated,
  });

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      gameId: map['gameId'] as int,
      totalScore: map['totalScore'] as int? ?? 0,
      hasUsedRetry: (map['hasUsedRetry'] as int? ?? 0) == 1,
      isEliminated: (map['isEliminated'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'gameId': gameId,
      'totalScore': totalScore,
      'hasUsedRetry': hasUsedRetry ? 1 : 0,
      'isEliminated': isEliminated ? 1 : 0,
    };
  }
}
