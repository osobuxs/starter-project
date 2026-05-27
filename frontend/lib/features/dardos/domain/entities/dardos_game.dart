import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_throw.dart';

class DardosGameEntity extends Equatable {
  final String id;
  final String name;
  final String mode; // '501' | '301' | 'cricket'
  final bool doubleOut;
  final int sets;
  final int legs;
  final String status; // 'playing' | 'finished' | 'cancelled'
  final int createdAt;
  final String createdBy;
  final List<String> playerIds;
  final List<String> starterOrder;
  final bool rosterLocked;
  final int currentSet;
  final int currentLeg;
  final String currentTurnPlayerId;
  final int currentTurnIndex;
  final int currentDartIndex;
  final List<List<String?>> legWinners; // [setIndex][legIndex]
  final List<String?> setWinners;
  final String? winnerId;
  final String? activeAnnotator;
  final int? activeAnnotatorAt;
  final bool isActive;
  final int? deletedAt;
  final int? cancelledAt;
  final String? cancelledBy;
  final Map<String, dynamic>? computedMetrics;
  final List<DardosThrowEntity> throws;

  const DardosGameEntity({
    required this.id,
    required this.name,
    required this.mode,
    required this.doubleOut,
    required this.sets,
    required this.legs,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.playerIds,
    required this.starterOrder,
    required this.rosterLocked,
    required this.currentSet,
    required this.currentLeg,
    required this.currentTurnPlayerId,
    required this.currentTurnIndex,
    required this.currentDartIndex,
    required this.legWinners,
    required this.setWinners,
    this.winnerId,
    this.activeAnnotator,
    this.activeAnnotatorAt,
    required this.isActive,
    this.deletedAt,
    this.cancelledAt,
    this.cancelledBy,
    this.computedMetrics,
    required this.throws,
  });

  DardosGameEntity copyWith({
    String? id,
    String? name,
    String? mode,
    bool? doubleOut,
    int? sets,
    int? legs,
    String? status,
    int? createdAt,
    String? createdBy,
    List<String>? playerIds,
    List<String>? starterOrder,
    bool? rosterLocked,
    int? currentSet,
    int? currentLeg,
    String? currentTurnPlayerId,
    int? currentTurnIndex,
    int? currentDartIndex,
    List<List<String?>>? legWinners,
    List<String?>? setWinners,
    String? winnerId,
    String? activeAnnotator,
    int? activeAnnotatorAt,
    bool? isActive,
    int? deletedAt,
    int? cancelledAt,
    String? cancelledBy,
    Map<String, dynamic>? computedMetrics,
    List<DardosThrowEntity>? throws,
  }) {
    return DardosGameEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      doubleOut: doubleOut ?? this.doubleOut,
      sets: sets ?? this.sets,
      legs: legs ?? this.legs,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      playerIds: playerIds ?? this.playerIds,
      starterOrder: starterOrder ?? this.starterOrder,
      rosterLocked: rosterLocked ?? this.rosterLocked,
      currentSet: currentSet ?? this.currentSet,
      currentLeg: currentLeg ?? this.currentLeg,
      currentTurnPlayerId: currentTurnPlayerId ?? this.currentTurnPlayerId,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      currentDartIndex: currentDartIndex ?? this.currentDartIndex,
      legWinners: legWinners ?? this.legWinners,
      setWinners: setWinners ?? this.setWinners,
      winnerId: winnerId ?? this.winnerId,
      activeAnnotator: activeAnnotator ?? this.activeAnnotator,
      activeAnnotatorAt: activeAnnotatorAt ?? this.activeAnnotatorAt,
      isActive: isActive ?? this.isActive,
      deletedAt: deletedAt ?? this.deletedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      computedMetrics: computedMetrics ?? this.computedMetrics,
      throws: throws ?? this.throws,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        mode,
        doubleOut,
        sets,
        legs,
        status,
        createdAt,
        createdBy,
        playerIds,
        starterOrder,
        rosterLocked,
        currentSet,
        currentLeg,
        currentTurnPlayerId,
        currentTurnIndex,
        currentDartIndex,
        legWinners,
        setWinners,
        winnerId,
        activeAnnotator,
        activeAnnotatorAt,
        isActive,
        deletedAt,
        cancelledAt,
        cancelledBy,
        computedMetrics,
        throws,
      ];
}
