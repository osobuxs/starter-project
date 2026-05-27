import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/dardos/data/data_sources/remote/dardos_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_participant.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/repository/dardos_participant_repository.dart';

class DardosParticipantRepositoryImpl implements DardosParticipantRepository {
  final DardosFirestoreDataSource _dataSource;

  DardosParticipantRepositoryImpl(this._dataSource);

  @override
  Future<DataState<DardosParticipantEntity>> createParticipant(
    DardosParticipantEntity p,
  ) async {
    try {
      final participant = await _dataSource.createParticipant(p);
      return DataSuccess(participant);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> updateParticipant(DardosParticipantEntity p) async {
    try {
      await _dataSource.updateParticipant(p);
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<void>> deleteParticipant(String id) async {
    try {
      await _dataSource.deleteParticipant(id);
      return const DataSuccess(null);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<List<DardosParticipantEntity>>>
      fetchAllParticipants() async {
    try {
      final participants = await _dataSource.fetchAllParticipants();
      return DataSuccess(participants);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }

  @override
  Future<DataState<DardosParticipantEntity>> fetchParticipantById(
    String id,
  ) async {
    try {
      final participant = await _dataSource.fetchParticipantById(id);
      return DataSuccess(participant);
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }
}
