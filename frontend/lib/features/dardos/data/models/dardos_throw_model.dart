import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';

class DardosThrowModel extends DardosThrowEntity {
  const DardosThrowModel({
    required String id,
    required String playerId,
    required int setIndex,
    required int legIndex,
    required int turnIndex,
    required int dartIndex,
    required int number,
    required int multiplier,
    required int points,
    required bool isMiss,
    required bool isBust,
    int? remainingAfter,
    String? cricketTarget,
    int? cricketMarksDelta,
    required int cricketPointsScored,
    required int timestamp,
    required String createdBy,
  }) : super(
          id: id,
          playerId: playerId,
          setIndex: setIndex,
          legIndex: legIndex,
          turnIndex: turnIndex,
          dartIndex: dartIndex,
          number: number,
          multiplier: multiplier,
          points: points,
          isMiss: isMiss,
          isBust: isBust,
          remainingAfter: remainingAfter,
          cricketTarget: cricketTarget,
          cricketMarksDelta: cricketMarksDelta,
          cricketPointsScored: cricketPointsScored,
          timestamp: timestamp,
          createdBy: createdBy,
        );

  factory DardosThrowModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return DardosThrowModel(
      id: id,
      playerId: data['playerId'] as String? ?? '',
      setIndex: data['setIndex'] as int? ?? 0,
      legIndex: data['legIndex'] as int? ?? 0,
      turnIndex: data['turnIndex'] as int? ?? 0,
      dartIndex: data['dartIndex'] as int? ?? 0,
      number: data['number'] as int? ?? 0,
      multiplier: data['multiplier'] as int? ?? 1,
      points: data['points'] as int? ?? 0,
      isMiss: data['isMiss'] as bool? ?? false,
      isBust: data['isBust'] as bool? ?? false,
      remainingAfter: data['remainingAfter'] as int?,
      cricketTarget: data['cricketTarget'] as String?,
      cricketMarksDelta: data['cricketMarksDelta'] as int?,
      cricketPointsScored: data['cricketPointsScored'] as int? ?? 0,
      timestamp: data['timestamp'] as int? ?? 0,
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  factory DardosThrowModel.fromEntity(DardosThrowEntity entity) {
    return DardosThrowModel(
      id: entity.id,
      playerId: entity.playerId,
      setIndex: entity.setIndex,
      legIndex: entity.legIndex,
      turnIndex: entity.turnIndex,
      dartIndex: entity.dartIndex,
      number: entity.number,
      multiplier: entity.multiplier,
      points: entity.points,
      isMiss: entity.isMiss,
      isBust: entity.isBust,
      remainingAfter: entity.remainingAfter,
      cricketTarget: entity.cricketTarget,
      cricketMarksDelta: entity.cricketMarksDelta,
      cricketPointsScored: entity.cricketPointsScored,
      timestamp: entity.timestamp,
      createdBy: entity.createdBy,
    );
  }

  DardosThrowEntity toEntity() {
    return DardosThrowEntity(
      id: id,
      playerId: playerId,
      setIndex: setIndex,
      legIndex: legIndex,
      turnIndex: turnIndex,
      dartIndex: dartIndex,
      number: number,
      multiplier: multiplier,
      points: points,
      isMiss: isMiss,
      isBust: isBust,
      remainingAfter: remainingAfter,
      cricketTarget: cricketTarget,
      cricketMarksDelta: cricketMarksDelta,
      cricketPointsScored: cricketPointsScored,
      timestamp: timestamp,
      createdBy: createdBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'setIndex': setIndex,
      'legIndex': legIndex,
      'turnIndex': turnIndex,
      'dartIndex': dartIndex,
      'number': number,
      'multiplier': multiplier,
      'points': points,
      'isMiss': isMiss,
      'isBust': isBust,
      'remainingAfter': remainingAfter,
      'cricketTarget': cricketTarget,
      'cricketMarksDelta': cricketMarksDelta,
      'cricketPointsScored': cricketPointsScored,
      'timestamp': timestamp,
      'createdBy': createdBy,
    };
  }
}
