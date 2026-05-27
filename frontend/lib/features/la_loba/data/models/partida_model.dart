import 'package:news_app_clean_architecture/features/la_loba/domain/entities/partida.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/score.dart';

class PartidaModel extends PartidaEntity {
  const PartidaModel({
    super.id,
    required super.partidaNumber,
    required super.gameId,
    super.scores,
    required super.createdAt,
  });

  factory PartidaModel.fromMap(
    Map<String, dynamic> map, {
    List<ScoreEntity> scores = const [],
  }) {
    return PartidaModel(
      id: map['id'] as int?,
      partidaNumber: map['partidaNumber'] as int,
      gameId: map['gameId'] as int,
      scores: scores,
      createdAt: map['createdAt'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'partidaNumber': partidaNumber,
      'gameId': gameId,
      'createdAt': createdAt,
    };
  }
}
