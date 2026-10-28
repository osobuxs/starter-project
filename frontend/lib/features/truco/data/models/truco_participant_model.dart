import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_participant.dart';

/// Firestore mapping for `truco_participants/{id}`.
class TrucoParticipantModel {
  const TrucoParticipantModel._();

  static TrucoParticipant fromFirestore(String id, Map<String, dynamic> json) {
    return TrucoParticipant(
      id: id,
      name: json['name'] as String? ?? '',
      totalGamesPlayed: json['totalGamesPlayed'] as int? ?? 0,
      totalGamesWon: json['totalGamesWon'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static Map<String, dynamic> toJson(TrucoParticipant participant) {
    return {
      'name': participant.name,
      'totalGamesPlayed': participant.totalGamesPlayed,
      'totalGamesWon': participant.totalGamesWon,
      'isActive': participant.isActive,
    };
  }
}
