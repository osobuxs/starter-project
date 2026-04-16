import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/player.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/add_player_usecase.dart';

@GenerateNiceMocks([MockSpec<GameRepository>()])
import 'add_player_usecase_test.mocks.dart';

void main() {
  late AddPlayerUseCase useCase;
  late MockGameRepository mockRepository;

  setUp(() {
    mockRepository = MockGameRepository();
    useCase = AddPlayerUseCase(mockRepository);
  });

  group('AddPlayerUseCase', () {
    const tGameId = 1;
    const tPlayer = PlayerEntity(
      id: 1,
      name: 'Juan',
      gameId: 1,
    );

    test('should add player when name is valid and unique', () async {
      when(mockRepository.playerNameExists(tGameId, 'Juan'))
          .thenAnswer((_) async => const DataSuccess(false));
      when(mockRepository.addPlayer(tGameId, 'Juan'))
          .thenAnswer((_) async => const DataSuccess(tPlayer));

      final result = await useCase(tGameId, 'Juan');

      expect(result, isA<DataSuccess<PlayerEntity>>());
      expect((result as DataSuccess).data!.name, 'Juan');
      verify(mockRepository.addPlayer(tGameId, 'Juan'));
    });

    test('should return DataFailed when name is empty', () async {
      final result = await useCase(tGameId, '');

      expect(result, isA<DataFailed<PlayerEntity>>());
      verifyNever(mockRepository.addPlayer(any, any));
    });

    test('should return DataFailed when name already exists', () async {
      when(mockRepository.playerNameExists(tGameId, 'Juan'))
          .thenAnswer((_) async => const DataSuccess(true));

      final result = await useCase(tGameId, 'Juan');

      expect(result, isA<DataFailed<PlayerEntity>>());
      verifyNever(mockRepository.addPlayer(any, any));
    });

    test('should trim whitespace from name', () async {
      when(mockRepository.playerNameExists(tGameId, 'Juan'))
          .thenAnswer((_) async => const DataSuccess(false));
      when(mockRepository.addPlayer(tGameId, 'Juan'))
          .thenAnswer((_) async => const DataSuccess(tPlayer));

      await useCase(tGameId, '  Juan  ');

      verify(mockRepository.playerNameExists(tGameId, 'Juan'));
      verify(mockRepository.addPlayer(tGameId, 'Juan'));
    });
  });
}
