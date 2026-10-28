import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/domain/repository/truco_game_repository.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_create_game/truco_create_game_state.dart';

/// Suggested name for a new game, e.g. "Truco 28/10".
String trucoSuggestedGameName(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${TrucoGame.defaultName} ${two(date.day)}/${two(date.month)}';
}

/// Form state of the "new Truco game" screen: name, mode, target, team
/// names, the seated players of each team and who deals first.
class TrucoCreateGameCubit extends Cubit<TrucoCreateGameState> {
  final TrucoGameRepository _repository;

  TrucoCreateGameCubit(this._repository, {DateTime Function()? now})
      : super(TrucoCreateGameState(
          name: trucoSuggestedGameName((now ?? DateTime.now)()),
        ));

  void rename(String name) {
    emit(state.copyWith(
      status: TrucoCreateGameStatus.editing,
      name: name,
      clearError: true,
    ));
  }

  /// Picks who deals the first hand; ignored for players not seated.
  void selectFirstDealer(String playerId) {
    if (!state.seatingOrder.contains(playerId)) return;
    emit(state.copyWith(
      status: TrucoCreateGameStatus.editing,
      preferredDealerId: playerId,
      clearError: true,
    ));
  }

  void selectMode(TrucoMode mode) {
    final size = mode.playersPerTeam;
    emit(_editing(
      mode: mode,
      teamA: _trim(state.teamA, size),
      teamB: _trim(state.teamB, size),
    ));
  }

  void selectTarget(int targetScore) {
    if (!trucoTargetScores.contains(targetScore)) return;
    emit(_editing(targetScore: targetScore));
  }

  void renameTeam(TrucoTeamSide side, String name) {
    emit(_withTeam(side, state.teamOf(side).copyWith(name: name)));
  }

  /// Adds the player to [side] (moving them out of the other team) or
  /// removes them if they already sit there. Ignored when the team is full.
  void togglePlayer(TrucoTeamSide side, String playerId) {
    final team = state.teamOf(side);
    if (team.playerIds.contains(playerId)) {
      emit(_withTeam(
        side,
        team.copyWith(
          playerIds: team.playerIds.where((id) => id != playerId).toList(),
        ),
      ));
      return;
    }
    if (team.playerIds.length >= state.mode.playersPerTeam) return;

    final other = state.teamOf(side.other);
    final updatedOther = other.copyWith(
      playerIds: other.playerIds.where((id) => id != playerId).toList(),
    );
    final updated = team.copyWith(playerIds: [...team.playerIds, playerId]);
    emit(side == TrucoTeamSide.a
        ? _editing(teamA: updated, teamB: updatedOther)
        : _editing(teamA: updatedOther, teamB: updated));
  }

  /// Reorders a team so its seats match how the players actually sit.
  void movePlayer(TrucoTeamSide side, int oldIndex, int newIndex) {
    final ids = [...state.teamOf(side).playerIds];
    if (oldIndex < 0 || oldIndex >= ids.length) return;
    final target = newIndex.clamp(0, ids.length - 1);
    final moved = ids.removeAt(oldIndex);
    ids.insert(target, moved);
    emit(_withTeam(side, state.teamOf(side).copyWith(playerIds: ids)));
  }

  Future<void> submit() async {
    final error = state.validationError;
    if (error != null) {
      emit(state.copyWith(status: TrucoCreateGameStatus.error, error: error));
      return;
    }
    if (state.status == TrucoCreateGameStatus.submitting) return;

    emit(state.copyWith(
      status: TrucoCreateGameStatus.submitting,
      clearError: true,
    ));
    final result = await _repository.createGame(
      name: state.name.trim(),
      mode: state.mode,
      targetScore: state.targetScore,
      teamA: state.teamA.copyWith(name: state.teamA.name.trim()),
      teamB: state.teamB.copyWith(name: state.teamB.name.trim()),
      seatingOrder: state.seatingOrder,
      // Validated above: a complete table always has a dealer.
      firstDealerId: state.firstDealerId!,
    );
    if (result is DataSuccess) {
      emit(state.copyWith(
        status: TrucoCreateGameStatus.created,
        createdGame: result.data,
      ));
    } else {
      emit(state.copyWith(
        status: TrucoCreateGameStatus.error,
        error: 'No se pudo crear la partida: ${result.error}',
      ));
    }
  }

  TrucoCreateGameState _withTeam(TrucoTeamSide side, TrucoTeam team) {
    return side == TrucoTeamSide.a
        ? _editing(teamA: team)
        : _editing(teamB: team);
  }

  TrucoCreateGameState _editing({
    TrucoMode? mode,
    int? targetScore,
    TrucoTeam? teamA,
    TrucoTeam? teamB,
  }) {
    return state.copyWith(
      status: TrucoCreateGameStatus.editing,
      mode: mode,
      targetScore: targetScore,
      teamA: teamA,
      teamB: teamB,
      clearError: true,
    );
  }

  TrucoTeam _trim(TrucoTeam team, int size) {
    if (team.playerIds.length <= size) return team;
    return team.copyWith(playerIds: team.playerIds.take(size).toList());
  }
}
