import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/participant.dart';

abstract class ParticipantRepository {
  Future<DataState<ParticipantEntity>> createParticipant(
    String name,
    String? email,
  );

  Future<DataState<ParticipantEntity>> updateParticipant(
    String id, {
    String? email,
  });

  Future<DataState<void>> deleteParticipant(String id);

  Future<DataState<List<ParticipantEntity>>> fetchAllParticipants();

  Future<DataState<ParticipantEntity>> fetchParticipantById(String id);
}
