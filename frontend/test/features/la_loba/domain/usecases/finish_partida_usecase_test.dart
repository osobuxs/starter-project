import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/finish_partida_usecase.dart';

@GenerateNiceMocks([MockSpec<GameRepository>()])
import 'finish_partida_usecase_test.mocks.dart';

void main() {
  late FinishPartidaUseCase useCase;
  late MockGameRepository mockRepository;

  setUp(() {
    mockRepository = MockGameRepository();
    useCase = FinishPartidaUseCase(mockRepository);
  });

  group('FinishPartidaUseCase', () {
    const tGameId = 1;
    const tPlayers = [
      PlayerEntity(id: 1, name: 'Juan', gameId: 1, totalScore: 20),
      PlayerEntity(id: 2, name: 'Maria', gameId: 1, totalScore: 30),
    ];
    const tUpdatedPlayers = [
      PlayerEntity(id: 1, name: 'Juan', gameId: 1, totalScore: 45),
      PlayerEntity(id: 2, name: 'Maria', gameId: 1, totalScore: 50),
    ];

    test('should update totalScores for active players', () async {
      var callCount = 0;
      when(mockRepository.getAllPlayers(tGameId)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return const DataSuccess(tPlayers);
        }
        return const DataSuccess(tUpdatedPlayers);
      });
      when(mockRepository.updatePlayerScore(any, any))
          .thenAnswer((_) async => const DataSuccess(null));

      final result = await useCase(
        gameId: tGameId,
        partidaScores: {1: 25, 2: 20},
      );

      expect(result, isA<DataSuccess<List<PlayerEntity>>>());
      verify(mockRepository.updatePlayerScore(1, 45)); // 20 + 25
      verify(mockRepository.updatePlayerScore(2, 50)); // 30 + 20
    });

    test('should skip eliminated players', () async {
      const playersWithEliminated = [
        PlayerEntity(id: 1, name: 'Juan', gameId: 1, totalScore: 20),
        PlayerEntity(
          id: 2,
          name: 'Maria',
          gameId: 1,
          totalScore: 110,
          isEliminated: true,
        ),
      ];

      when(mockRepository.getAllPlayers(tGameId))
          .thenAnswer((_) async => const DataSuccess(playersWithEliminated));
      when(mockRepository.updatePlayerScore(any, any))
          .thenAnswer((_) async => const DataSuccess(null));

      await useCase(
        gameId: tGameId,
        partidaScores: {1: 25, 2: 10},
      );

      verify(mockRepository.updatePlayerScore(1, 45)); // 20 + 25
      verifyNever(mockRepository.updatePlayerScore(2, any)); // skipped
    });
  });
}
