import 'package:equatable/equatable.dart';

class ParticipantEntity extends Equatable {
  final String id;
  final String name;
  final String? email;
  final int totalGamesPlayed;
  final int totalGamesWon;
  final String? uid; // Firebase Auth UID

  const ParticipantEntity({
    required this.id,
    required this.name,
    this.email,
    this.totalGamesPlayed = 0,
    this.totalGamesWon = 0,
    this.uid,
  });

  ParticipantEntity copyWith({
    String? id,
    String? name,
    String? email,
    int? totalGamesPlayed,
    int? totalGamesWon,
    String? uid,
  }) {
    return ParticipantEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      totalGamesWon: totalGamesWon ?? this.totalGamesWon,
      uid: uid ?? this.uid,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    totalGamesPlayed,
    totalGamesWon,
    uid,
  ];
}
