import 'package:news_app_clean_architecture/features/la_loba/domain/entities/score.dart';

class ScoreModel extends ScoreEntity {
  const ScoreModel({
    super.id,
    required super.playerId,
    required super.partidaId,
    required super.points,
  });

  factory ScoreModel.fromMap(Map<String, dynamic> map) {
    return ScoreModel(
      id: map['id'] as int?,
      playerId: map['playerId'] as int,
      partidaId: map['partidaId'] as int,
      points: map['points'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'playerId': playerId,
      'partidaId': partidaId,
      'points': points,
    };
  }
}
