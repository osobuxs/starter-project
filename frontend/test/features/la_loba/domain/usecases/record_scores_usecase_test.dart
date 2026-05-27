import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/record_scores_usecase.dart';

@GenerateNiceMocks([MockSpec<GameRepository>()])
import 'record_scores_usecase_test.mocks.dart';

void main() {
  late RecordScoresUseCase useCase;
  late MockGameRepository mockRepository;

  setUp(() {
    mockRepository = MockGameRepository();
    useCase = RecordScoresUseCase(mockRepository);
  });

  group('RecordScoresUseCase', () {
    test('should record scores for all players in a partida', () async {
      when(mockRepository.recordScore(any, any, any))
          .thenAnswer((_) async => const DataSuccess(null));

      final result = await useCase(
        partidaId: 1,
        scores: {1: 25, 2: 30, 3: 15},
      );

      expect(result, isA<DataSuccess<void>>());
      verify(mockRepository.recordScore(1, 1, 25));
      verify(mockRepository.recordScore(2, 1, 30));
      verify(mockRepository.recordScore(3, 1, 15));
    });

    test('should return DataFailed if any score recording fails', () async {
      when(mockRepository.recordScore(1, 1, 25))
          .thenAnswer((_) async => const DataSuccess(null));
      when(mockRepository.recordScore(2, 1, 30))
          .thenAnswer((_) async => DataFailed(Exception('DB error')));

      final result = await useCase(
        partidaId: 1,
        scores: {1: 25, 2: 30},
      );

      expect(result, isA<DataFailed<void>>());
    });
  });
}
