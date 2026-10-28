import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/truco/data/data_sources/remote/truco_firestore_data_source.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_participant.dart';
import 'package:news_app_clean_architecture/features/truco/domain/repository/truco_participant_repository.dart';

class TrucoParticipantRepositoryImpl implements TrucoParticipantRepository {
  final TrucoFirestoreDataSource _dataSource;

  TrucoParticipantRepositoryImpl(this._dataSource);

  @override
  Future<DataState<TrucoParticipant>> createParticipant(String name) {
    return _guard(() => _dataSource.createParticipant(name));
  }

  @override
  Future<DataState<TrucoParticipant>> updateParticipant(
    String id, {
    required String name,
  }) {
    return _guard(() => _dataSource.updateParticipant(id, name: name));
  }

  @override
  Future<DataState<void>> deleteParticipant(String id) {
    return _guard(() => _dataSource.deleteParticipant(id));
  }

  @override
  Future<DataState<List<TrucoParticipant>>> fetchAllParticipants() {
    return _guard(_dataSource.fetchAllParticipants);
  }

  Future<DataState<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return DataSuccess(await action());
    } on Exception catch (e) {
      return DataFailed(e);
    }
  }
}
