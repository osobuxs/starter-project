import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand_commit.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';

abstract class TrucoGameRepository {
  Future<DataState<TrucoGame>> createGame({
    required String name,
    required TrucoMode mode,
    required int targetScore,
    required TrucoTeam teamA,
    required TrucoTeam teamB,
    required List<String> seatingOrder,
    required String firstDealerId,
  });

  Future<DataState<TrucoGame>> getGame(String gameId);

  /// Emits the latest game (with hands) on every remote or local change.
  /// Errors are delivered as [DataFailed] without closing the stream.
  Stream<DataState<TrucoGame>> watchGame(String gameId);

  /// Every game, newest first.
  Future<DataState<List<TrucoGame>>> getGames();

  /// Persists a closed hand and the resulting game state in one atomic write.
  Future<DataState<void>> commitHand(TrucoHandCommit commit);
}
