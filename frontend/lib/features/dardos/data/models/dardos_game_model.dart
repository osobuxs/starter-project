import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_game.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';

class DardosGameModel extends DardosGameEntity {
  const DardosGameModel({
    required super.id,
    required super.name,
    required super.mode,
    required super.doubleOut,
    required super.sets,
    required super.legs,
    required super.status,
    required super.createdAt,
    required super.createdBy,
    required super.playerIds,
    required super.starterOrder,
    super.teamMode = false,
    super.teams = const [],
    super.playerTeamIds = const {},
    required super.rosterLocked,
    required super.currentSet,
    required super.currentLeg,
    required super.currentTurnPlayerId,
    required super.currentTurnIndex,
    required super.currentDartIndex,
    required super.legWinners,
    required super.setWinners,
    super.winnerId,
    super.activeAnnotator,
    super.activeAnnotatorAt,
    required super.isActive,
    super.deletedAt,
    super.cancelledAt,
    super.cancelledBy,
    super.computedMetrics,
    required super.throws,
  });

  factory DardosGameModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
    List<DardosThrowEntity> throws_,
  ) {
    // Deserialize legWinners stored as Map<String, List<String?>>
    // (Firestore doesn't support nested arrays). Keys are setIndex as string.
    final rawLegWinners = data['legWinners'];
    final List<List<String?>> legWinners;
    if (rawLegWinners is Map) {
      final entries = rawLegWinners.entries.toList()
        ..sort((a, b) =>
            int.parse(a.key.toString()).compareTo(int.parse(b.key.toString())));
      legWinners = entries.map((entry) {
        final inner = entry.value;
        if (inner is List) {
          return inner.map((v) => v as String?).toList();
        }
        return <String?>[];
      }).toList();
    } else if (rawLegWinners is List) {
      legWinners = rawLegWinners.map((outer) {
        if (outer is List) {
          return outer.map((inner) => inner as String?).toList();
        }
        return <String?>[];
      }).toList();
    } else {
      legWinners = <List<String?>>[];
    }

    // Deserialize setWinners: List<String?>
    final rawSetWinners = (data['setWinners'] as List<dynamic>?) ?? [];
    final setWinners = rawSetWinners.map((v) => v as String?).toList();

    return DardosGameModel(
      id: id,
      name: data['name'] as String? ?? '',
      mode: data['mode'] as String? ?? '501',
      doubleOut: data['doubleOut'] as bool? ?? true,
      sets: data['sets'] as int? ?? 1,
      legs: data['legs'] as int? ?? 1,
      status: data['status'] as String? ?? 'waiting',
      createdAt: data['createdAt'] as int? ?? 0,
      createdBy: data['createdBy'] as String? ?? '',
      playerIds: List<String>.from((data['playerIds'] as List<dynamic>?) ?? []),
      starterOrder:
          List<String>.from((data['starterOrder'] as List<dynamic>?) ?? []),
      teamMode: data['teamMode'] as bool? ?? false,
      teams: ((data['teams'] as List<dynamic>?) ?? [])
          .whereType<Map>()
          .map((t) => Map<String, dynamic>.from(t))
          .toList(),
      playerTeamIds: Map<String, String>.from(
        (data['playerTeamIds'] as Map<dynamic, dynamic>?) ?? {},
      ),
      rosterLocked: data['rosterLocked'] as bool? ?? false,
      currentSet: data['currentSet'] as int? ?? 0,
      currentLeg: data['currentLeg'] as int? ?? 0,
      currentTurnPlayerId: data['currentTurnPlayerId'] as String? ?? '',
      currentTurnIndex: data['currentTurnIndex'] as int? ?? 0,
      currentDartIndex: data['currentDartIndex'] as int? ?? 0,
      legWinners: legWinners,
      setWinners: setWinners,
      winnerId: data['winnerId'] as String?,
      activeAnnotator: data['activeAnnotator'] as String?,
      activeAnnotatorAt: data['activeAnnotatorAt'] as int?,
      isActive: data['isActive'] as bool? ?? true,
      deletedAt: data['deletedAt'] as int?,
      cancelledAt: data['cancelledAt'] as int?,
      cancelledBy: data['cancelledBy'] as String?,
      computedMetrics: data['computedMetrics'] as Map<String, dynamic>?,
      throws: throws_,
    );
  }

  factory DardosGameModel.fromEntity(
    DardosGameEntity entity,
    List<DardosThrowEntity> throws_,
  ) {
    return DardosGameModel(
      id: entity.id,
      name: entity.name,
      mode: entity.mode,
      doubleOut: entity.doubleOut,
      sets: entity.sets,
      legs: entity.legs,
      status: entity.status,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      playerIds: entity.playerIds,
      starterOrder: entity.starterOrder,
      teamMode: entity.teamMode,
      teams: entity.teams,
      playerTeamIds: entity.playerTeamIds,
      rosterLocked: entity.rosterLocked,
      currentSet: entity.currentSet,
      currentLeg: entity.currentLeg,
      currentTurnPlayerId: entity.currentTurnPlayerId,
      currentTurnIndex: entity.currentTurnIndex,
      currentDartIndex: entity.currentDartIndex,
      legWinners: entity.legWinners,
      setWinners: entity.setWinners,
      winnerId: entity.winnerId,
      activeAnnotator: entity.activeAnnotator,
      activeAnnotatorAt: entity.activeAnnotatorAt,
      isActive: entity.isActive,
      deletedAt: entity.deletedAt,
      cancelledAt: entity.cancelledAt,
      cancelledBy: entity.cancelledBy,
      computedMetrics: entity.computedMetrics,
      throws: throws_,
    );
  }

  DardosGameEntity toEntity() {
    return DardosGameEntity(
      id: id,
      name: name,
      mode: mode,
      doubleOut: doubleOut,
      sets: sets,
      legs: legs,
      status: status,
      createdAt: createdAt,
      createdBy: createdBy,
      playerIds: playerIds,
      starterOrder: starterOrder,
      teamMode: teamMode,
      teams: teams,
      playerTeamIds: playerTeamIds,
      rosterLocked: rosterLocked,
      currentSet: currentSet,
      currentLeg: currentLeg,
      currentTurnPlayerId: currentTurnPlayerId,
      currentTurnIndex: currentTurnIndex,
      currentDartIndex: currentDartIndex,
      legWinners: legWinners,
      setWinners: setWinners,
      winnerId: winnerId,
      activeAnnotator: activeAnnotator,
      activeAnnotatorAt: activeAnnotatorAt,
      isActive: isActive,
      deletedAt: deletedAt,
      cancelledAt: cancelledAt,
      cancelledBy: cancelledBy,
      computedMetrics: computedMetrics,
      throws: throws,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mode': mode,
      'doubleOut': doubleOut,
      'sets': sets,
      'legs': legs,
      'status': status,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'playerIds': playerIds,
      'starterOrder': starterOrder,
      'teamMode': teamMode,
      'teams': teams,
      'playerTeamIds': playerTeamIds,
      'rosterLocked': rosterLocked,
      'currentSet': currentSet,
      'currentLeg': currentLeg,
      'currentTurnPlayerId': currentTurnPlayerId,
      'currentTurnIndex': currentTurnIndex,
      'currentDartIndex': currentDartIndex,
      'legWinners': {
        for (var i = 0; i < legWinners.length; i++) i.toString(): legWinners[i],
      },
      'setWinners': setWinners,
      'winnerId': winnerId,
      'activeAnnotator': activeAnnotator,
      'activeAnnotatorAt': activeAnnotatorAt,
      'isActive': isActive,
      'deletedAt': deletedAt,
      'cancelledAt': cancelledAt,
      'cancelledBy': cancelledBy,
      'computedMetrics': computedMetrics,
    };
  }
}
