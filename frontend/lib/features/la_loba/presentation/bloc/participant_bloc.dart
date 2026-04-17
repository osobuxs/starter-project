import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/entities/participant.dart';
import 'package:news_app_clean_architecture/features/la_loba/domain/repository/participant_repository.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_state.dart';

class ParticipantBloc extends Bloc<ParticipantEvent, ParticipantState> {
  final ParticipantRepository _repository;
  final FirebaseAuth _auth;

  ParticipantBloc(this._repository, this._auth) : super(const ParticipantState()) {
    on<CreateParticipantEvent>(_onCreateParticipant);
    on<UpdateParticipantEvent>(_onUpdateParticipant);
    on<DeleteParticipantEvent>(_onDeleteParticipant);
    on<FetchAllParticipantsEvent>(_onFetchAllParticipants);
    on<CheckAdminStatusEvent>(_onCheckAdminStatus);
  }

  Future<void> _onCreateParticipant(
    CreateParticipantEvent event,
    Emitter<ParticipantState> emit,
  ) async {
    if (!state.isAdmin) return;

    emit(state.copyWith(status: ParticipantBlocStatus.loading, clearError: true));

    final result = await _repository.createParticipant(event.name, event.email);
    if (result is DataSuccess<ParticipantEntity>) {
      final updated = [...state.participants, result.data!];
      emit(state.copyWith(
        status: ParticipantBlocStatus.created,
        participants: updated,
      ));
    } else {
      emit(state.copyWith(
        status: ParticipantBlocStatus.error,
        error: result.error?.toString() ?? 'Error creating participant',
      ));
    }
  }

  Future<void> _onUpdateParticipant(
    UpdateParticipantEvent event,
    Emitter<ParticipantState> emit,
  ) async {
    if (!state.isAdmin) return;

    emit(state.copyWith(status: ParticipantBlocStatus.loading, clearError: true));

    final result = await _repository.updateParticipant(
      event.id,
      email: event.email,
    );
    if (result is DataSuccess<ParticipantEntity>) {
      final updated = state.participants.map((p) => p.id == event.id ? result.data! : p).toList();
      emit(state.copyWith(
        status: ParticipantBlocStatus.updated,
        participants: updated,
      ));
    } else {
      emit(state.copyWith(
        status: ParticipantBlocStatus.error,
        error: result.error?.toString() ?? 'Error updating participant',
      ));
    }
  }

  Future<void> _onDeleteParticipant(
    DeleteParticipantEvent event,
    Emitter<ParticipantState> emit,
  ) async {
    if (!state.isAdmin) return;

    emit(state.copyWith(status: ParticipantBlocStatus.loading, clearError: true));

    final result = await _repository.deleteParticipant(event.id);
    if (result is DataSuccess) {
      final updated = state.participants.where((p) => p.id != event.id).toList();
      emit(state.copyWith(
        status: ParticipantBlocStatus.deleted,
        participants: updated,
      ));
    } else {
      emit(state.copyWith(
        status: ParticipantBlocStatus.error,
        error: result.error?.toString() ?? 'Error deleting participant',
      ));
    }
  }

  Future<void> _onFetchAllParticipants(
    FetchAllParticipantsEvent event,
    Emitter<ParticipantState> emit,
  ) async {
    emit(state.copyWith(status: ParticipantBlocStatus.loading, clearError: true));

    final result = await _repository.fetchAllParticipants();
    if (result is DataSuccess<List<ParticipantEntity>>) {
      emit(state.copyWith(
        status: ParticipantBlocStatus.loaded,
        participants: result.data,
      ));
    } else {
      emit(state.copyWith(
        status: ParticipantBlocStatus.error,
        error: result.error?.toString() ?? 'Error fetching participants',
      ));
    }
  }

  Future<void> _onCheckAdminStatus(
    CheckAdminStatusEvent event,
    Emitter<ParticipantState> emit,
  ) async {
    final currentUser = _auth.currentUser;
    final isAdmin = currentUser?.email == 'lfexevega95@gmail.com';

    emit(state.copyWith(isAdmin: isAdmin));
  }
}
