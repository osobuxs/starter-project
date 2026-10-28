import 'package:equatable/equatable.dart';

/// A registered Truco player (separate registry from La Loba and Dardos).
class TrucoParticipant extends Equatable {
  final String id;
  final String name;
  final int totalGamesPlayed;
  final int totalGamesWon;
  final bool isActive;

  const TrucoParticipant({
    required this.id,
    required this.name,
    this.totalGamesPlayed = 0,
    this.totalGamesWon = 0,
    this.isActive = true,
  });

  TrucoParticipant copyWith({
    String? name,
    int? totalGamesPlayed,
    int? totalGamesWon,
    bool? isActive,
  }) {
    return TrucoParticipant(
      id: id,
      name: name ?? this.name,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalGamesWon: totalGamesWon ?? this.totalGamesWon,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, totalGamesPlayed, totalGamesWon, isActive];
}
