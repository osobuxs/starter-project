import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/partida.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';

class GameModel extends GameEntity {
  const GameModel({
    super.id,
    required super.name,
    super.status,
    required super.createdAt,
    super.players,
    super.partidas,
  });

  factory GameModel.fromMap(
    Map<String, dynamic> map, {
    List<PlayerEntity> players = const [],
    List<PartidaEntity> partidas = const [],
  }) {
    return GameModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      status: map['status'] as String? ?? 'created',
      createdAt: map['createdAt'] as int,
      players: players,
      partidas: partidas,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
