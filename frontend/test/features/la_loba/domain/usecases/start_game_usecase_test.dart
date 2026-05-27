import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/partida.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/start_game_usecase.dart';

@GenerateNiceMocks([MockSpec<GameRepository>()])
import 'start_game_usecase_test.mocks.dart';

void main() {
  late StartGameUseCase useCase;
  late MockGameRepository mockRepository;

  setUp(() {
    mockRepository = MockGameRepository();
    useCase = StartGameUseCase(mockRepository);
  });

  group('StartGameUseCase', () {
    const tGameId = 1;
    final now = DateTime.now().millisecondsSinceEpoch;

    final tGameWith2Players = GameEntity(
      id: tGameId,
      name: 'Test Game',
      status: 'created',
      createdAt: now,
      players: const [
        PlayerEntity(id: 1, name: 'Juan', gameId: 1),
        PlayerEntity(id: 2, name: 'Maria', gameId: 1),
      ],
    );

    final tGameWith1Player = GameEntity(
      id: tGameId,
      name: 'Test Game',
      status: 'created',
      createdAt: now,
      players: const [
        PlayerEntity(id: 1, name: 'Juan', gameId: 1),
      ],
    );

    final tStartedGame = tGameWith2Players.copyWith(
      status: 'playing',
      partidas: [
        PartidaEntity(id: 1, partidaNumber: 1, gameId: 1, createdAt: now),
      ],
    );

    test('should start game when 2+ players exist', () async {
      when(mockRepository.getGame(tGameId))
          .thenAnswer((_) async => DataSuccess(tGameWith2Players));
      when(mockRepository.createPartida(tGameId, 1))
          .thenAnswer((_) async => DataSuccess(
            PartidaEntity(id: 1, partidaNumber: 1, gameId: 1, createdAt: now),
          ));
      when(mockRepository.updateGameStatus(tGameId, 'playing'))
          .thenAnswer((_) async => const DataSuccess(null));
      // Second getGame returns the started game
      when(mockRepository.getGame(tGameId))
          .thenAnswer((_) async => DataSuccess(tStartedGame));

      final result = await useCase(tGameId);

      expect(result, isA<DataSuccess<GameEntity>>());
      verify(mockRepository.createPartida(tGameId, 1));
      verify(mockRepository.updateGameStatus(tGameId, 'playing'));
    });

    test('should return DataFailed when less than 2 players', () async {
      when(mockRepository.getGame(tGameId))
          .thenAnswer((_) async => DataSuccess(tGameWith1Player));

      final result = await useCase(tGameId);

      expect(result, isA<DataFailed<GameEntity>>());
      verifyNever(mockRepository.createPartida(any, any));
      verifyNever(mockRepository.updateGameStatus(any, any));
    });
  });
}
