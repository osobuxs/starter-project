import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/dardos/data/data_sources/remote/dardos_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/dardos/data/repository/dardos_participant_repository_impl.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_participant.dart';

@GenerateNiceMocks([MockSpec<DardosFirestoreDataSource>()])
import 'dardos_participant_repository_impl_test.mocks.dart';

// ---------------------------------------------------------------------------
// Fixture
// ---------------------------------------------------------------------------
DardosParticipantEntity makeParticipant({
  String id = 'p1',
  String name = 'Test Player',
  bool isActive = true,
}) {
  return DardosParticipantEntity(
    id: id,
    name: name,
    isActive: isActive,
    createdAt: 1000,
    totalGamesPlayed: 0,
    totalGamesWon: 0,
    statsByMode: const {},
  );
}

void main() {
  late MockDardosFirestoreDataSource mockDataSource;
  late DardosParticipantRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockDardosFirestoreDataSource();
    repository = DardosParticipantRepositoryImpl(mockDataSource);
  });

  // -----------------------------------------------------------------------
  // createParticipant
  // -----------------------------------------------------------------------
  group('createParticipant', () {
    test('happy path: returns DataSuccess with participant', () async {
      final participant = makeParticipant();
      when(mockDataSource.createParticipant(any))
          .thenAnswer((_) async => participant);

      final result = await repository.createParticipant(participant);

      expect(result, isA<DataSuccess<DardosParticipantEntity>>());
      expect(result.data!.id, 'p1');
    });

    test('error path: returns DataFailed on exception', () async {
      when(mockDataSource.createParticipant(any))
          .thenThrow(Exception('create error'));

      final result = await repository.createParticipant(makeParticipant());

      expect(result, isA<DataFailed<DardosParticipantEntity>>());
    });
  });

  // -----------------------------------------------------------------------
  // fetchAllParticipants
  // -----------------------------------------------------------------------
  group('fetchAllParticipants', () {
    test('happy path: returns DataSuccess with list', () async {
      final participants = [makeParticipant(), makeParticipant(id: 'p2')];
      when(mockDataSource.fetchAllParticipants())
          .thenAnswer((_) async => participants);

      final result = await repository.fetchAllParticipants();

      expect(result, isA<DataSuccess<List<DardosParticipantEntity>>>());
      expect(result.data!.length, 2);
    });

    test('error path: returns DataFailed on exception', () async {
      when(mockDataSource.fetchAllParticipants())
          .thenThrow(Exception('fetch error'));

      final result = await repository.fetchAllParticipants();

      expect(result, isA<DataFailed<List<DardosParticipantEntity>>>());
    });
  });

  // -----------------------------------------------------------------------
  // deleteParticipant — soft-delete sets isActive=false
  // -----------------------------------------------------------------------
  group('deleteParticipant (soft-delete)', () {
    test('calls datasource.deleteParticipant with the id', () async {
      when(mockDataSource.deleteParticipant(any)).thenAnswer((_) async {});

      final result = await repository.deleteParticipant('p1');

      expect(result, isA<DataSuccess<void>>());
      verify(mockDataSource.deleteParticipant('p1')).called(1);
    });

    test('error path: returns DataFailed on exception', () async {
      when(mockDataSource.deleteParticipant(any))
          .thenThrow(Exception('delete error'));

      final result = await repository.deleteParticipant('p1');

      expect(result, isA<DataFailed<void>>());
    });
  });

  // -----------------------------------------------------------------------
  // error wrapping consistency
  // -----------------------------------------------------------------------
  group('error wrapping', () {
    test('fetchParticipantById wraps exception in DataFailed', () async {
      when(mockDataSource.fetchParticipantById(any))
          .thenThrow(Exception('not found'));

      final result = await repository.fetchParticipantById('p99');

      expect(result, isA<DataFailed<DardosParticipantEntity>>());
      expect(result.error, isNotNull);
    });
  });
}
