import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_participant.dart';

class DardosParticipantModel extends DardosParticipantEntity {
  const DardosParticipantModel({
    required String id,
    required String name,
    String? email,
    String? uid,
    required bool isActive,
    int? deletedAt,
    required int createdAt,
    required int totalGamesPlayed,
    required int totalGamesWon,
    required Map<String, Map<String, dynamic>> statsByMode,
    Map<String, int> numberFreq = const {},
  }) : super(
          id: id,
          name: name,
          email: email,
          uid: uid,
          isActive: isActive,
          deletedAt: deletedAt,
          createdAt: createdAt,
          totalGamesPlayed: totalGamesPlayed,
          totalGamesWon: totalGamesWon,
          statsByMode: statsByMode,
          numberFreq: numberFreq,
        );

  factory DardosParticipantModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    final rawStatsByMode = (data['statsByMode'] as Map<String, dynamic>?) ?? {};
    final statsByMode = <String, Map<String, dynamic>>{};
    rawStatsByMode.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        statsByMode[key] = value;
      }
    });

    final rawFreq = (data['numberFreq'] as Map<String, dynamic>?) ?? {};
    final numberFreq = <String, int>{};
    rawFreq.forEach((key, value) {
      if (value is int) numberFreq[key] = value;
      if (value is num) numberFreq[key] = value.toInt();
    });

    return DardosParticipantModel(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String?,
      uid: data['uid'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      deletedAt: data['deletedAt'] as int?,
      createdAt: data['createdAt'] as int? ?? 0,
      totalGamesPlayed: data['totalGamesPlayed'] as int? ?? 0,
      totalGamesWon: data['totalGamesWon'] as int? ?? 0,
      statsByMode: statsByMode,
      numberFreq: numberFreq,
    );
  }

  factory DardosParticipantModel.fromEntity(DardosParticipantEntity entity) {
    return DardosParticipantModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      uid: entity.uid,
      isActive: entity.isActive,
      deletedAt: entity.deletedAt,
      createdAt: entity.createdAt,
      totalGamesPlayed: entity.totalGamesPlayed,
      totalGamesWon: entity.totalGamesWon,
      statsByMode: entity.statsByMode,
      numberFreq: entity.numberFreq,
    );
  }

  DardosParticipantEntity toEntity() {
    return DardosParticipantEntity(
      id: id,
      name: name,
      email: email,
      uid: uid,
      isActive: isActive,
      deletedAt: deletedAt,
      createdAt: createdAt,
      totalGamesPlayed: totalGamesPlayed,
      totalGamesWon: totalGamesWon,
      statsByMode: statsByMode,
      numberFreq: numberFreq,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'uid': uid,
      'isActive': isActive,
      'deletedAt': deletedAt,
      'createdAt': createdAt,
      'totalGamesPlayed': totalGamesPlayed,
      'totalGamesWon': totalGamesWon,
      'statsByMode': statsByMode,
      'numberFreq': numberFreq,
    };
  }
}
