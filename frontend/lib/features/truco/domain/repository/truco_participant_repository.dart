import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/truco/domain/entities/truco_participant.dart';

abstract class TrucoParticipantRepository {
  Future<DataState<TrucoParticipant>> createParticipant(String name);

  Future<DataState<TrucoParticipant>> updateParticipant(
    String id, {
    required String name,
  });

  Future<DataState<void>> deleteParticipant(String id);

  /// Active players ordered by name.
  Future<DataState<List<TrucoParticipant>>> fetchAllParticipants();
}
