import 'package:equatable/equatable.dart';

class DardosThrowEntity extends Equatable {
  final String id;
  final String playerId;
  final int setIndex;
  final int legIndex;
  final int turnIndex;
  final int dartIndex; // 0..2
  final int number; // 1..20 | 25 (bull ext) | 50 (bull int, represented as number=50)
  final int multiplier; // 1..3
  final int points; // number * multiplier
  final bool isMiss;
  final bool isBust;
  final int? remainingAfter; // 501/301 only
  final String? cricketTarget; // '15'..'20' | 'bull' | null
  final int? cricketMarksDelta; // 0..3
  final int cricketPointsScored;
  final int timestamp;
  final String createdBy;

  const DardosThrowEntity({
    required this.id,
    required this.playerId,
    required this.setIndex,
    required this.legIndex,
    required this.turnIndex,
    required this.dartIndex,
    required this.number,
    required this.multiplier,
    required this.points,
    required this.isMiss,
    required this.isBust,
    this.remainingAfter,
    this.cricketTarget,
    this.cricketMarksDelta,
    required this.cricketPointsScored,
    required this.timestamp,
    required this.createdBy,
  });

  DardosThrowEntity copyWith({
    String? id,
    String? playerId,
    int? setIndex,
    int? legIndex,
    int? turnIndex,
    int? dartIndex,
    int? number,
    int? multiplier,
    int? points,
    bool? isMiss,
    bool? isBust,
    int? remainingAfter,
    String? cricketTarget,
    int? cricketMarksDelta,
    int? cricketPointsScored,
    int? timestamp,
    String? createdBy,
  }) {
    return DardosThrowEntity(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      setIndex: setIndex ?? this.setIndex,
      legIndex: legIndex ?? this.legIndex,
      turnIndex: turnIndex ?? this.turnIndex,
      dartIndex: dartIndex ?? this.dartIndex,
      number: number ?? this.number,
      multiplier: multiplier ?? this.multiplier,
      points: points ?? this.points,
      isMiss: isMiss ?? this.isMiss,
      isBust: isBust ?? this.isBust,
      remainingAfter: remainingAfter ?? this.remainingAfter,
      cricketTarget: cricketTarget ?? this.cricketTarget,
      cricketMarksDelta: cricketMarksDelta ?? this.cricketMarksDelta,
      cricketPointsScored: cricketPointsScored ?? this.cricketPointsScored,
      timestamp: timestamp ?? this.timestamp,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        playerId,
        setIndex,
        legIndex,
        turnIndex,
        dartIndex,
        number,
        multiplier,
        points,
        isMiss,
        isBust,
        remainingAfter,
        cricketTarget,
        cricketMarksDelta,
        cricketPointsScored,
        timestamp,
        createdBy,
      ];
}
