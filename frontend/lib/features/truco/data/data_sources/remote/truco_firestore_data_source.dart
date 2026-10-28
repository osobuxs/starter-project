import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_hand_commit.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_participant.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';

abstract class TrucoFirestoreDataSource {
  Future<TrucoGame> createGame({
    required String name,
    required TrucoMode mode,
    required int targetScore,
    required TrucoTeam teamA,
    required TrucoTeam teamB,
    required List<String> seatingOrder,
    required String firstDealerId,
  });

  Future<TrucoGame> getGame(String gameId);

  /// Live view of a game: emits whenever the game document or any of its
  /// hands change (including local pending writes).
  Stream<TrucoGame> watchGame(String gameId);

  /// Every game with its hands, newest first.
  Future<List<TrucoGame>> getGames();

  Future<void> commitHand(TrucoHandCommit commit);

  Future<TrucoParticipant> createParticipant(String name);
  Future<TrucoParticipant> updateParticipant(String id, {required String name});
  Future<void> deleteParticipant(String id);
  Future<List<TrucoParticipant>> fetchAllParticipants();
}
