import 'package:equatable/equatable.dart';

import 'score.dart';

class PartidaEntity extends Equatable {
  final int? id;
  final int partidaNumber;
  final int gameId;
  final List<ScoreEntity> scores;
  final int createdAt;

  const PartidaEntity({
    this.id,
    required this.partidaNumber,
    required this.gameId,
    this.scores = const [],
    required this.createdAt,
  });

  PartidaEntity copyWith({
    int? id,
    int? partidaNumber,
    int? gameId,
    List<ScoreEntity>? scores,
    int? createdAt,
  }) {
    return PartidaEntity(
      id: id ?? this.id,
      partidaNumber: partidaNumber ?? this.partidaNumber,
      gameId: gameId ?? this.gameId,
      scores: scores ?? this.scores,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, partidaNumber, gameId, scores, createdAt];
}
