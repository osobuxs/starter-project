import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/do_retry_usecase.dart';

@GenerateNiceMocks([MockSpec<GameRepository>()])
import 'do_retry_usecase_test.mocks.dart';

void main() {
  late DoRetryUseCase useCase;
  late MockGameRepository mockRepository;

  setUp(() {
    mockRepository = MockGameRepository();
    useCase = DoRetryUseCase(mockRepository);
  });

  group('DoRetryUseCase', () {
    const tGameId = 1;
    const tPlayerId = 1;
    final now = DateTime.now().millisecondsSinceEpoch;

    test('should reset score to highest active player score under 100',
        () async {
      const activePlayers = [
        PlayerEntity(id: 1, name: 'Juan', gameId: 1, totalScore: 110),
        PlayerEntity(id: 2, name: 'Maria', gameId: 1, totalScore: 80),
        PlayerEntity(id: 3, name: 'Pedro', gameId: 1, totalScore: 60),
      ];
      const updatedJuan = PlayerEntity(
        id: 1,
        name: 'Juan',
        gameId: 1,
        totalScore: 80,
        hasUsedRetry: true,
      );

      when(mockRepository.getActivePlayers(tGameId))
          .thenAnswer((_) async => const DataSuccess(activePlayers));
      when(mockRepository.updatePlayerScore(tPlayerId, 80))
          .thenAnswer((_) async => const DataSuccess(null));
      when(mockRepository.updatePlayerRetry(tPlayerId))
          .thenAnswer((_) async => const DataSuccess(null));
      when(mockRepository.getGame(tGameId)).thenAnswer(
        (_) async => DataSuccess(GameEntity(
          id: tGameId,
          name: 'Test',
          createdAt: now,
          players: [updatedJuan, activePlayers[1], activePlayers[2]],
        )),
      );

      final result = await useCase(tGameId, tPlayerId);

      expect(result, isA<DataSuccess<PlayerEntity>>());
      verify(mockRepository.updatePlayerScore(tPlayerId, 80));
      verify(mockRepository.updatePlayerRetry(tPlayerId));
    });

    test('should reset to 0 when no other active player under 100', () async {
      const activePlayers = [
        PlayerEntity(id: 1, name: 'Juan', gameId: 1, totalScore: 110),
        PlayerEntity(id: 2, name: 'Maria', gameId: 1, totalScore: 105),
      ];
      const updatedJuan = PlayerEntity(
        id: 1,
        name: 'Juan',
        gameId: 1,
        totalScore: 0,
        hasUsedRetry: true,
      );

      when(mockRepository.getActivePlayers(tGameId))
          .thenAnswer((_) async => const DataSuccess(activePlayers));
      when(mockRepository.updatePlayerScore(tPlayerId, 0))
          .thenAnswer((_) async => const DataSuccess(null));
      when(mockRepository.updatePlayerRetry(tPlayerId))
          .thenAnswer((_) async => const DataSuccess(null));
      when(mockRepository.getGame(tGameId)).thenAnswer(
        (_) async => DataSuccess(GameEntity(
          id: tGameId,
          name: 'Test',
          createdAt: now,
          players: [updatedJuan, activePlayers[1]],
        )),
      );

      final result = await useCase(tGameId, tPlayerId);

      expect(result, isA<DataSuccess<PlayerEntity>>());
      verify(mockRepository.updatePlayerScore(tPlayerId, 0));
    });
  });
}
