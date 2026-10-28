import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_game.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_team.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_event.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_state.dart';

import '../../support/truco_fakes.dart';

TrucoGame _game(String id, {bool finished = false}) => TrucoGame(
      id: id,
      mode: TrucoMode.oneVsOne,
      targetScore: 30,
      teamA: const TrucoTeam(name: 'Nosotros', playerIds: ['a']),
      teamB: const TrucoTeam(name: 'Ellos', playerIds: ['b']),
      date: 1,
      status: finished ? TrucoGameStatus.finished : TrucoGameStatus.playing,
    );

void main() {
  late FakeTrucoGameRepository repository;

  setUp(() {
    repository = FakeTrucoGameRepository()
      ..games = [_game('g3'), _game('g2', finished: true), _game('g1')];
  });

  blocTest<TrucoMultiGameBloc, TrucoMultiGameState>(
    'splits games into playing and finished, keeping the order',
    build: () => TrucoMultiGameBloc(repository),
    act: (bloc) => bloc.add(const LoadTrucoGamesEvent()),
    expect: () => [
      const TrucoMultiGameState(status: TrucoMultiGameStatus.loading),
      TrucoMultiGameState(
        status: TrucoMultiGameStatus.loaded,
        playingGames: [_game('g3'), _game('g1')],
        finishedGames: [_game('g2', finished: true)],
      ),
    ],
  );
}
