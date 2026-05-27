import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/fetch_game_history_usecase.dart';

@GenerateNiceMocks([MockSpec<GameRepository>()])
import 'fetch_game_history_usecase_test.mocks.dart';

void main() {
  late FetchGameHistoryUseCase useCase;
  late MockGameRepository mockRepository;

  setUp(() {
    mockRepository = MockGameRepository();
    useCase = FetchGameHistoryUseCase(mockRepository);
  });

  group('FetchGameHistoryUseCase', () {
    test('should return list of games from repository', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final tGames = [
        GameEntity(id: 1, name: 'Game 1', status: 'finished', createdAt: now),
        GameEntity(
          id: 2,
          name: 'Game 2',
          status: 'playing',
          createdAt: now - 1000,
        ),
      ];

      when(mockRepository.getGameHistory())
          .thenAnswer((_) async => DataSuccess(tGames));

      final result = await useCase();

      expect(result, isA<DataSuccess<List<GameEntity>>>());
      expect((result as DataSuccess).data!.length, 2);
      verify(mockRepository.getGameHistory());
    });

    test('should return empty list when no games exist', () async {
      when(mockRepository.getGameHistory())
          .thenAnswer((_) async => const DataSuccess(<GameEntity>[]));

      final result = await useCase();

      expect(result, isA<DataSuccess<List<GameEntity>>>());
      expect((result as DataSuccess).data!, isEmpty);
    });
  });
}
