import 'package:equatable/equatable.dart';

import 'hand.dart';

class GameEntity extends Equatable {
  final String id;
  final String name;
  final String status; // 'playing', 'paused', 'finished'
  final int date;
  final List<String> participantIds; // Firestore references
  final String currentDealerId;
  final int currentHand;
  final Map<String, dynamic> participantStates; // {participantId: {score: int, status: 'active'/'eliminated'/'reinstarted'}}
  final String? winnerId;
  final List<HandEntity> hands;

  const GameEntity({
    required this.id,
    required this.name,
    this.status = 'playing',
    required this.date,
    this.participantIds = const [],
    required this.currentDealerId,
    this.currentHand = 0,
    this.participantStates = const {},
    this.winnerId,
    this.hands = const [],
  });

  GameEntity copyWith({
    String? id,
    String? name,
    String? status,
    int? date,
    List<String>? participantIds,
    String? currentDealerId,
    int? currentHand,
    Map<String, dynamic>? participantStates,
    String? winnerId,
    List<HandEntity>? hands,
  }) {
    return GameEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      date: date ?? this.date,
      participantIds: participantIds ?? this.participantIds,
      currentDealerId: currentDealerId ?? this.currentDealerId,
      currentHand: currentHand ?? this.currentHand,
      participantStates: participantStates ?? this.participantStates,
      winnerId: winnerId ?? this.winnerId,
      hands: hands ?? this.hands,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    status,
    date,
    participantIds,
    currentDealerId,
    currentHand,
    participantStates,
    winnerId,
    hands,
  ];
}
