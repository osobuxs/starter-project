import 'package:equatable/equatable.dart';

class ScoreEntity extends Equatable {
  final int? id;
  final int playerId;
  final int partidaId;
  final int points;

  const ScoreEntity({
    this.id,
    required this.playerId,
    required this.partidaId,
    required this.points,
  });

  ScoreEntity copyWith({
    int? id,
    int? playerId,
    int? partidaId,
    int? points,
  }) {
    return ScoreEntity(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      partidaId: partidaId ?? this.partidaId,
      points: points ?? this.points,
    );
  }

  @override
  List<Object?> get props => [id, playerId, partidaId, points];
}
