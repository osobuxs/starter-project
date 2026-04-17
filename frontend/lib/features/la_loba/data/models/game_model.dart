import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';

class GameModel extends GameEntity {
  const GameModel({
    required super.id,
    required super.name,
    super.status,
    required super.date,
    super.participantIds,
    required super.currentDealerId,
    super.currentHand,
    super.participantStates,
    super.winnerId,
    super.hands,
  });

  factory GameModel.fromFirestore(Map<String, dynamic> map) {
    return GameModel(
      id: map['id'] as String,
      name: map['name'] as String,
      status: map['status'] as String? ?? 'playing',
      date: (map['date'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      participantIds: List<String>.from(map['participantIds'] as List? ?? []),
      currentDealerId: map['currentDealerId'] as String? ?? '',
      currentHand: map['currentHand'] as int? ?? 0,
      participantStates: Map<String, dynamic>.from(map['participantStates'] as Map? ?? {}),
      winnerId: map['winnerId'] as String?,
      hands: [], // Hands loaded separately from subcollection
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'date': date,
      'participantIds': participantIds,
      'currentDealerId': currentDealerId,
      'currentHand': currentHand,
      'participantStates': participantStates,
      'winnerId': winnerId,
    };
  }
}
