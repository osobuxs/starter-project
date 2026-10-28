import 'package:equatable/equatable.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/domain/services/truco_dealer_rules.dart';
import 'package:news_app_clean_architecture/features/truco/domain/services/truco_game_config_validator.dart';
import 'package:news_app_clean_architecture/features/truco/domain/services/truco_score_rules.dart';

enum TrucoCreateGameStatus { editing, submitting, created, error }

class TrucoCreateGameState extends Equatable {
  final TrucoCreateGameStatus status;
  final String name;
  final TrucoMode mode;
  final int targetScore;
  final TrucoTeam teamA;
  final TrucoTeam teamB;
  final String? error;
  final TrucoGame? createdGame;

  /// Dealer picked by the admin; ignored while that player is not seated.
  final String? preferredDealerId;

  const TrucoCreateGameState({
    this.status = TrucoCreateGameStatus.editing,
    this.name = TrucoGame.defaultName,
    this.mode = TrucoMode.twoVsTwo,
    this.targetScore = 30,
    this.teamA = const TrucoTeam(name: TrucoTeam.defaultNameA),
    this.teamB = const TrucoTeam(name: TrucoTeam.defaultNameB),
    this.error,
    this.createdGame,
    this.preferredDealerId,
  });

  TrucoTeam teamOf(TrucoTeamSide side) =>
      side == TrucoTeamSide.a ? teamA : teamB;

  /// Players around the table: A1, B1, A2, B2, ...
  List<String> get seatingOrder =>
      trucoSeatingOrder(teamA.playerIds, teamB.playerIds);

  /// Who deals the first hand: the picked player, or A1 by default.
  String? get firstDealerId =>
      trucoFirstDealer(seatingOrder, preferredDealerId);

  String? get validationError => validateTrucoGameConfig(
        name: name,
        firstDealerId: firstDealerId,
        mode: mode,
        targetScore: targetScore,
        teamA: teamA,
        teamB: teamB,
      );

  bool get canSubmit =>
      validationError == null && status != TrucoCreateGameStatus.submitting;

  TrucoCreateGameState copyWith({
    TrucoCreateGameStatus? status,
    String? name,
    String? preferredDealerId,
    TrucoMode? mode,
    int? targetScore,
    TrucoTeam? teamA,
    TrucoTeam? teamB,
    String? error,
    bool clearError = false,
    TrucoGame? createdGame,
  }) {
    return TrucoCreateGameState(
      status: status ?? this.status,
      name: name ?? this.name,
      preferredDealerId: preferredDealerId ?? this.preferredDealerId,
      mode: mode ?? this.mode,
      targetScore: targetScore ?? this.targetScore,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      error: clearError ? null : (error ?? this.error),
      createdGame: createdGame ?? this.createdGame,
    );
  }

  @override
  List<Object?> get props => [
        status,
        name,
        mode,
        targetScore,
        teamA,
        teamB,
        error,
        createdGame,
        preferredDealerId,
      ];
}
