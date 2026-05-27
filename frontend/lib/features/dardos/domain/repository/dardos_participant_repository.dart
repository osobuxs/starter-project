import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/dardos_participant.dart';

abstract class DardosParticipantRepository {
  Future<DataState<DardosParticipantEntity>> createParticipant(
    DardosParticipantEntity p,
  );

  Future<DataState<void>> updateParticipant(DardosParticipantEntity p);

  Future<DataState<void>> deleteParticipant(String id);

  Future<DataState<List<DardosParticipantEntity>>> fetchAllParticipants();

  Future<DataState<DardosParticipantEntity>> fetchParticipantById(String id);
}
