import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:news_app_clean_architecture/features/dardos/data/data_sources/remote/dardos_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/dardos/data/data_sources/remote/dardos_firestore_data_source_impl.dart';
import 'package:news_app_clean_architecture/features/dardos/data/repository/dardos_game_repository_impl.dart';
import 'package:news_app_clean_architecture/features/dardos/data/repository/dardos_participant_repository_impl.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/repository/dardos_game_repository.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/repository/dardos_participant_repository.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_bottom_nav/dardos_bottom_nav_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_multi_game/dardos_multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_bloc.dart';

Future<void> registerDardosDependencies(GetIt sl) async {
  // Firestore Data Source
  sl.registerLazySingleton<DardosFirestoreDataSource>(
    () => DardosFirestoreDataSourceImpl(sl<FirebaseFirestore>()),
  );

  // Repositories
  sl.registerLazySingleton<DardosGameRepository>(
    () => DardosGameRepositoryImpl(sl<DardosFirestoreDataSource>()),
  );

  sl.registerLazySingleton<DardosParticipantRepository>(
    () => DardosParticipantRepositoryImpl(sl<DardosFirestoreDataSource>()),
  );

  // BLoCs
  sl.registerFactory(() => DardosBottomNavBloc());

  sl.registerFactory(
    () => DardosParticipantBloc(
      sl<DardosParticipantRepository>(),
      sl<FirebaseAuth>(),
    ),
  );

  sl.registerFactory(
    () => DardosMultiGameBloc(sl<DardosGameRepository>()),
  );

  sl.registerFactory(
    () => DardosGameBloc(repository: sl<DardosGameRepository>()),
  );
}
