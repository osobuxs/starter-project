import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/truco/data/data_sources/remote/truco_firestore_data_source_impl.dart';
import 'package:news_app_clean_architecture/features/truco/data/repository/truco_game_repository_impl.dart';
import 'package:news_app_clean_architecture/features/truco/data/repository/truco_participant_repository_impl.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';

void main() {
  late TrucoFirestoreDataSourceImpl dataSource;

  setUp(() {
    dataSource = TrucoFirestoreDataSourceImpl(FakeFirebaseFirestore());
  });

  test('a missing game is reported as DataFailed', () async {
    final repository = TrucoGameRepositoryImpl(dataSource);

    final result = await repository.getGame('missing');

    expect(result, isA<DataFailed<TrucoGame>>());
  });

  test('watchGame wraps games in DataSuccess', () async {
    final repository = TrucoGameRepositoryImpl(dataSource);
    final created = await repository.createGame(
      mode: TrucoMode.oneVsOne,
      targetScore: 18,
      teamA: const TrucoTeam(name: 'Nosotros', playerIds: ['a']),
      teamB: const TrucoTeam(name: 'Ellos', playerIds: ['b']),
    );

    final first = await repository.watchGame(created.data!.id).first;

    expect(first, isA<DataSuccess<TrucoGame>>());
    expect(first.data!.targetScore, 18);
  });

  test('participant repository creates and lists players', () async {
    final repository = TrucoParticipantRepositoryImpl(dataSource);

    await repository.createParticipant('Ana');
    final result = await repository.fetchAllParticipants();

    expect(result.data!.single.name, 'Ana');
  });
}
