import 'package:equatable/equatable.dart';

class DardosParticipantEntity extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? uid;
  final bool isActive;
  final int? deletedAt;
  final int createdAt;
  final int totalGamesPlayed;
  final int totalGamesWon;
  final Map<String, Map<String, dynamic>> statsByMode;

  const DardosParticipantEntity({
    required this.id,
    required this.name,
    this.email,
    this.uid,
    required this.isActive,
    this.deletedAt,
    required this.createdAt,
    required this.totalGamesPlayed,
    required this.totalGamesWon,
    required this.statsByMode,
  });

  DardosParticipantEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? uid,
    bool? isActive,
    int? deletedAt,
    int? createdAt,
    int? totalGamesPlayed,
    int? totalGamesWon,
    Map<String, Map<String, dynamic>>? statsByMode,
  }) {
    return DardosParticipantEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      uid: uid ?? this.uid,
      isActive: isActive ?? this.isActive,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalGamesWon: totalGamesWon ?? this.totalGamesWon,
      statsByMode: statsByMode ?? this.statsByMode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        uid,
        isActive,
        deletedAt,
        createdAt,
        totalGamesPlayed,
        totalGamesWon,
        statsByMode,
      ];
}
