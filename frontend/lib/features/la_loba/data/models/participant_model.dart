import 'package:news_app_clean_architecture/features/la_loba/domain/entities/participant.dart';

class ParticipantModel extends ParticipantEntity {
  const ParticipantModel({
    required String id,
    required String name,
    String? email,
    int totalGamesPlayed = 0,
    int totalGamesWon = 0,
    String? uid,
  }) : super(
    id: id,
    name: name,
    email: email,
    totalGamesPlayed: totalGamesPlayed,
    totalGamesWon: totalGamesWon,
    uid: uid,
  );

  factory ParticipantModel.fromFirestore(
    Map<String, dynamic> json,
    String documentId,
  ) {
    return ParticipantModel(
      id: documentId,
      name: json['name'] as String,
      email: json['email'] as String?,
      totalGamesPlayed: json['totalGamesPlayed'] as int? ?? 0,
      totalGamesWon: json['totalGamesWon'] as int? ?? 0,
      uid: json['uid'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'totalGamesPlayed': totalGamesPlayed,
      'totalGamesWon': totalGamesWon,
      'uid': uid,
    };
  }
}
