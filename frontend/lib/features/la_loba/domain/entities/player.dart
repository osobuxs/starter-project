import 'package:equatable/equatable.dart';

class PlayerEntity extends Equatable {
  final int? id;
  final String name;
  final int gameId;
  final int totalScore;
  final bool hasUsedRetry;
  final bool isEliminated;

  const PlayerEntity({
    this.id,
    required this.name,
    required this.gameId,
    this.totalScore = 0,
    this.hasUsedRetry = false,
    this.isEliminated = false,
  });

  PlayerEntity copyWith({
    int? id,
    String? name,
    int? gameId,
    int? totalScore,
    bool? hasUsedRetry,
    bool? isEliminated,
  }) {
    return PlayerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      gameId: gameId ?? this.gameId,
      totalScore: totalScore ?? this.totalScore,
      hasUsedRetry: hasUsedRetry ?? this.hasUsedRetry,
      isEliminated: isEliminated ?? this.isEliminated,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    gameId,
    totalScore,
    hasUsedRetry,
    isEliminated,
  ];
}
