import 'package:get_it/get_it.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/data_sources/local/la_loba_local_data_source.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/repository/game_repository_impl.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/add_player_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/check_game_over_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/create_game_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/do_retry_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/fetch_game_history_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/fetch_game_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/finish_partida_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/record_scores_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/reject_retry_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/usecases/start_game_usecase.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_bloc.dart';

Future<void> registerLaLobaDependencies(GetIt sl) async {
  // Data Sources
  final dataSource = LaLobaLocalDataSourceImpl();
  await dataSource.initDb();
  sl.registerLazySingleton<LaLobaLocalDataSource>(() => dataSource);

  // Repository
  sl.registerLazySingleton<GameRepository>(
    () => GameRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => CreateGameUseCase(sl()));
  sl.registerLazySingleton(() => AddPlayerUseCase(sl()));
  sl.registerLazySingleton(() => StartGameUseCase(sl()));
  sl.registerLazySingleton(() => RecordScoresUseCase(sl()));
  sl.registerLazySingleton(() => FinishPartidaUseCase(sl()));
  sl.registerLazySingleton(() => CheckGameOverUseCase(sl()));
  sl.registerLazySingleton(() => DoRetryUseCase(sl()));
  sl.registerLazySingleton(() => RejectRetryUseCase(sl()));
  sl.registerLazySingleton(() => FetchGameUseCase(sl()));
  sl.registerLazySingleton(() => FetchGameHistoryUseCase(sl()));

  // BLoC
  sl.registerFactory(() => GameBloc(
    createGame: sl(),
    addPlayer: sl(),
    startGame: sl(),
    recordScores: sl(),
    finishPartida: sl(),
    checkGameOver: sl(),
    doRetry: sl(),
    rejectRetry: sl(),
    fetchGame: sl(),
    fetchHistory: sl(),
    repository: sl(),
  ));
}
