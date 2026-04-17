import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/data_sources/remote/la_loba_firestore_data_source_impl.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/repository/game_repository_impl.dart';
import 'package:news_app_clean_architecture/features/la_loba/data/repository/participant_repository_impl.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/game_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/participant_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/bottom_nav_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_bloc.dart';

Future<void> registerLaLobaDependencies(GetIt sl) async {
  // Firestore Data Source
  sl.registerLazySingleton(
    () => LaLobaFirestoreDataSourceImpl(sl<FirebaseFirestore>()),
  );

  // Repositories
  sl.registerLazySingleton<GameRepository>(
    () => GameRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<ParticipantRepository>(
    () => ParticipantRepositoryImpl(sl<FirebaseFirestore>()),
  );

  // BLoCs
  sl.registerFactory(() => GameBloc(repository: sl()));

  sl.registerFactory(() => MultiGameBloc(sl<GameRepository>()));

  sl.registerFactory(
    () => ParticipantBloc(
      sl<ParticipantRepository>(),
      sl<FirebaseAuth>(),
    ),
  );

  sl.registerFactory(() => BottomNavBloc());
}
