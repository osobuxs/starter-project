import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game_over_result.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/check_game_over_usecase.dart';

@GenerateNiceMocks([MockSpec<GameRepository>()])
import 'check_game_over_usecase_test.mocks.dart';

void main() {
  late CheckGameOverUseCase useCase;
  late MockGameRepository mockRepository;

  setUp(() {
    mockRepository = MockGameRepository();
    useCase = CheckGameOverUseCase(mockRepository);
  });

  group('CheckGameOverUseCase', () {
    const tGameId = 1;

    test('should return game continues when no one exceeds 100', () async {
      const activePlayers = [
        PlayerEntity(id: 1, name: 'Juan', gameId: 1, totalScore: 50),
        PlayerEntity(id: 2, name: 'Maria', gameId: 1, totalScore: 60),
        PlayerEntity(id: 3, name: 'Pedro', gameId: 1, totalScore: 30),
      ];

      when(mockRepository.getActivePlayers(tGameId))
          .thenAnswer((_) async => const DataSuccess(activePlayers));

      final result = await useCase(tGameId);

      expect(result, isA<DataSuccess<GameOverResult>>());
      final gameOver = (result as DataSuccess<GameOverResult>).data!;
      expect(gameOver.isGameOver, false);
      expect(gameOver.retryCandidates, isEmpty);
      expect(gameOver.autoEliminated, isEmpty);
    });

    test('should offer retry when player exceeds 100 and has not used retry',
        () async {
      const activePlayers = [
        PlayerEntity(id: 1, name: 'Juan', gameId: 1, totalScore: 110),
        PlayerEntity(id: 2, name: 'Maria', gameId: 1, totalScore: 60),
        PlayerEntity(id: 3, name: 'Pedro', gameId: 1, totalScore: 30),
      ];

      when(mockRepository.getActivePlayers(tGameId))
          .thenAnswer((_) async => const DataSuccess(activePlayers));

      final result = await useCase(tGameId);

      expect(result, isA<DataSuccess<GameOverResult>>());
      final gameOver = (result as DataSuccess<GameOverResult>).data!;
      expect(gameOver.isGameOver, false);
      expect(gameOver.retryCandidates.length, 1);
      expect(gameOver.retryCandidates.first.name, 'Juan');
    });

    test(
        'should auto-eliminate player who exceeds 100 and already used retry',
        () async {
      const activePlayers = [
        PlayerEntity(
          id: 1,
          name: 'Juan',
          gameId: 1,
          totalScore: 110,
          hasUsedRetry: true,
        ),
        PlayerEntity(id: 2, name: 'Maria', gameId: 1, totalScore: 60),
        PlayerEntity(id: 3, name: 'Pedro', gameId: 1, totalScore: 30),
      ];

      when(mockRepository.getActivePlayers(tGameId))
          .thenAnswer((_) async => const DataSuccess(activePlayers));
      when(mockRepository.eliminatePlayer(1))
          .thenAnswer((_) async => const DataSuccess(null));

      final result = await useCase(tGameId);

      expect(result, isA<DataSuccess<GameOverResult>>());
      final gameOver = (result as DataSuccess<GameOverResult>).data!;
      expect(gameOver.isGameOver, false); // 2 players remain
      expect(gameOver.autoEliminated.length, 1);
      expect(gameOver.autoEliminated.first.name, 'Juan');
      verify(mockRepository.eliminatePlayer(1));
    });

    test('should detect game over when only 1 player remains under 100',
        () async {
      const activePlayers = [
        PlayerEntity(
          id: 1,
          name: 'Juan',
          gameId: 1,
          totalScore: 110,
          hasUsedRetry: true,
        ),
        PlayerEntity(id: 2, name: 'Maria', gameId: 1, totalScore: 60),
      ];

      when(mockRepository.getActivePlayers(tGameId))
          .thenAnswer((_) async => const DataSuccess(activePlayers));
      when(mockRepository.eliminatePlayer(1))
          .thenAnswer((_) async => const DataSuccess(null));
      when(mockRepository.updateGameStatus(tGameId, 'finished'))
          .thenAnswer((_) async => const DataSuccess(null));

      final result = await useCase(tGameId);

      expect(result, isA<DataSuccess<GameOverResult>>());
      final gameOver = (result as DataSuccess<GameOverResult>).data!;
      expect(gameOver.isGameOver, true);
      expect(gameOver.winner!.name, 'Maria');
      verify(mockRepository.updateGameStatus(tGameId, 'finished'));
    });

    test('should handle multiple players exceeding 100 simultaneously',
        () async {
      const activePlayers = [
        PlayerEntity(id: 1, name: 'Juan', gameId: 1, totalScore: 105),
        PlayerEntity(id: 2, name: 'Maria', gameId: 1, totalScore: 108),
        PlayerEntity(id: 3, name: 'Pedro', gameId: 1, totalScore: 60),
      ];

      when(mockRepository.getActivePlayers(tGameId))
          .thenAnswer((_) async => const DataSuccess(activePlayers));

      final result = await useCase(tGameId);

      expect(result, isA<DataSuccess<GameOverResult>>());
      final gameOver = (result as DataSuccess<GameOverResult>).data!;
      expect(gameOver.isGameOver, false);
      expect(gameOver.retryCandidates.length, 2);
    });

    test(
        'should handle mix of retry candidates and auto-eliminated',
        () async {
      const activePlayers = [
        PlayerEntity(id: 1, name: 'Juan', gameId: 1, totalScore: 105),
        PlayerEntity(
          id: 2,
          name: 'Maria',
          gameId: 1,
          totalScore: 108,
          hasUsedRetry: true,
        ),
        PlayerEntity(id: 3, name: 'Pedro', gameId: 1, totalScore: 60),
      ];

      when(mockRepository.getActivePlayers(tGameId))
          .thenAnswer((_) async => const DataSuccess(activePlayers));
      when(mockRepository.eliminatePlayer(2))
          .thenAnswer((_) async => const DataSuccess(null));

      final result = await useCase(tGameId);

      expect(result, isA<DataSuccess<GameOverResult>>());
      final gameOver = (result as DataSuccess<GameOverResult>).data!;
      expect(gameOver.isGameOver, false);
      expect(gameOver.retryCandidates.length, 1);
      expect(gameOver.retryCandidates.first.name, 'Juan');
      expect(gameOver.autoEliminated.length, 1);
      expect(gameOver.autoEliminated.first.name, 'Maria');
    });
  });
}
