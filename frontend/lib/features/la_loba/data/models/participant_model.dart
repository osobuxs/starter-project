import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/participant.dart';

class ParticipantModel extends ParticipantEntity {
  const ParticipantModel({
    required super.id,
    required super.name,
    super.email,
    super.totalGamesPlayed,
    super.totalGamesWon,
    super.uid,
    super.isActive,
    super.deletedAt,
  });

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
      isActive: json['isActive'] as bool? ?? true,
      deletedAt: _toDateTime(json['deletedAt']),
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'totalGamesPlayed': totalGamesPlayed,
      'totalGamesWon': totalGamesWon,
      'uid': uid,
      'isActive': isActive,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
    };
  }
}
