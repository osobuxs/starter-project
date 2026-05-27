import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/game.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/create_game_usecase.dart';

@GenerateNiceMocks([MockSpec<GameRepository>()])
import 'create_game_usecase_test.mocks.dart';

void main() {
  late CreateGameUseCase useCase;
  late MockGameRepository mockRepository;

  setUp(() {
    mockRepository = MockGameRepository();
    useCase = CreateGameUseCase(mockRepository);
  });

  group('CreateGameUseCase', () {
    final tGame = GameEntity(
      id: 1,
      name: 'Viernes Loba',
      status: 'created',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    test('should create a game when name is valid', () async {
      when(mockRepository.createGame('Viernes Loba'))
          .thenAnswer((_) async => DataSuccess(tGame));

      final result = await useCase('Viernes Loba');

      expect(result, isA<DataSuccess<GameEntity>>());
      expect((result as DataSuccess).data!.name, 'Viernes Loba');
      verify(mockRepository.createGame('Viernes Loba'));
    });

    test('should trim whitespace from name', () async {
      when(mockRepository.createGame('Viernes Loba'))
          .thenAnswer((_) async => DataSuccess(tGame));

      await useCase('  Viernes Loba  ');

      verify(mockRepository.createGame('Viernes Loba'));
    });

    test('should return DataFailed when name is empty', () async {
      final result = await useCase('');

      expect(result, isA<DataFailed<GameEntity>>());
      verifyNever(mockRepository.createGame(any));
    });

    test('should return DataFailed when name is only whitespace', () async {
      final result = await useCase('   ');

      expect(result, isA<DataFailed<GameEntity>>());
      verifyNever(mockRepository.createGame(any));
    });
  });
}
