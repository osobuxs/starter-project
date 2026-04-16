import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/reject_retry_usecase.dart';

@GenerateNiceMocks([MockSpec<GameRepository>()])
import 'reject_retry_usecase_test.mocks.dart';

void main() {
  late RejectRetryUseCase useCase;
  late MockGameRepository mockRepository;

  setUp(() {
    mockRepository = MockGameRepository();
    useCase = RejectRetryUseCase(mockRepository);
  });

  group('RejectRetryUseCase', () {
    test('should eliminate the player', () async {
      when(mockRepository.eliminatePlayer(1))
          .thenAnswer((_) async => const DataSuccess(null));

      final result = await useCase(1);

      expect(result, isA<DataSuccess<void>>());
      verify(mockRepository.eliminatePlayer(1));
    });
  });
}
