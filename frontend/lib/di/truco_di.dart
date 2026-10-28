import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:news_app_clean_architecture/features/truco/data/data_sources/remote/truco_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/truco/data/data_sources/remote/truco_firestore_data_source_impl.dart';
import 'package:news_app_clean_architecture/features/truco/data/repository/truco_game_repository_impl.dart';
import 'package:news_app_clean_architecture/features/truco/data/repository/truco_participant_repository_impl.dart';
import 'package:news_app_clean_architecture/features/truco/domain/repository/truco_game_repository.dart';
import 'package:news_app_clean_architecture/features/truco/domain/repository/truco_participant_repository.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_create_game/truco_create_game_cubit.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_game/truco_game_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_multi_game/truco_multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_bloc.dart';

Future<void> registerTrucoDependencies(GetIt sl) async {
  // Firestore Data Source
  sl.registerLazySingleton<TrucoFirestoreDataSource>(
    () => TrucoFirestoreDataSourceImpl(sl<FirebaseFirestore>()),
  );

  // Repositories
  sl.registerLazySingleton<TrucoGameRepository>(
    () => TrucoGameRepositoryImpl(sl<TrucoFirestoreDataSource>()),
  );

  sl.registerLazySingleton<TrucoParticipantRepository>(
    () => TrucoParticipantRepositoryImpl(sl<TrucoFirestoreDataSource>()),
  );

  // BLoCs
  sl.registerFactory(
    () => TrucoParticipantBloc(
      sl<TrucoParticipantRepository>(),
      sl<FirebaseAuth>(),
    ),
  );

  sl.registerFactory(() => TrucoMultiGameBloc(sl<TrucoGameRepository>()));

  sl.registerFactory(() => TrucoCreateGameCubit(sl<TrucoGameRepository>()));

  sl.registerFactory(
    () => TrucoGameBloc(repository: sl<TrucoGameRepository>()),
  );
}
