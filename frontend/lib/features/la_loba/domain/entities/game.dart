import 'package:equatable/equatable.dart';

import 'partida.dart';
import 'player.dart';

class GameEntity extends Equatable {
  final int? id;
  final String name;
  final String status; // 'created', 'playing', 'finished'
  final int createdAt;
  final List<PlayerEntity> players;
  final List<PartidaEntity> partidas;

  const GameEntity({
    this.id,
    required this.name,
    this.status = 'created',
    required this.createdAt,
    this.players = const [],
    this.partidas = const [],
  });

  List<PlayerEntity> get activePlayers =>
      players.where((p) => !p.isEliminated).toList();

  GameEntity copyWith({
    int? id,
    String? name,
    String? status,
    int? createdAt,
    List<PlayerEntity>? players,
    List<PartidaEntity>? partidas,
  }) {
    return GameEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      players: players ?? this.players,
      partidas: partidas ?? this.partidas,
    );
  }

  @override
  List<Object?> get props => [id, name, status, createdAt, players, partidas];
}
