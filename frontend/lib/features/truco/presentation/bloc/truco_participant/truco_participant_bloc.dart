import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/truco/domain/repository/truco_participant_repository.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_event.dart';
import 'package:news_app_clean_architecture/features/truco/presentation/bloc/truco_participant/truco_participant_state.dart';

/// Same admin as La Loba and Dardos.
const _adminEmail = 'lfexevega95@gmail.com';

class TrucoParticipantBloc
    extends Bloc<TrucoParticipantEvent, TrucoParticipantState> {
  final TrucoParticipantRepository _repository;
  final FirebaseAuth _auth;

  TrucoParticipantBloc(this._repository, this._auth)
      : super(const TrucoParticipantState()) {
    on<FetchTrucoParticipantsEvent>(_onFetch);
    on<CreateTrucoParticipantEvent>(_onCreate);
    on<UpdateTrucoParticipantEvent>(_onUpdate);
    on<DeleteTrucoParticipantEvent>(_onDelete);
    on<CheckTrucoAdminStatusEvent>(_onCheckAdmin);
  }

  void _onCheckAdmin(
    CheckTrucoAdminStatusEvent event,
    Emitter<TrucoParticipantState> emit,
  ) {
    emit(state.copyWith(isAdmin: _auth.currentUser?.email == _adminEmail));
  }

  Future<void> _onFetch(
    FetchTrucoParticipantsEvent event,
    Emitter<TrucoParticipantState> emit,
  ) async {
    emit(state.copyWith(
      status: TrucoParticipantStatus.loading,
      clearError: true,
    ));
    final result = await _repository.fetchAllParticipants();
    if (result is DataSuccess) {
      emit(state.copyWith(
        status: TrucoParticipantStatus.loaded,
        participants: result.data,
      ));
    } else {
      _emitError(emit, result, 'No se pudieron cargar los jugadores');
    }
  }

  Future<void> _onCreate(
    CreateTrucoParticipantEvent event,
    Emitter<TrucoParticipantState> emit,
  ) async {
    if (!state.isAdmin) return;
    final name = event.name.trim();
    if (name.isEmpty) {
      emit(state.copyWith(
        status: TrucoParticipantStatus.error,
        error: 'El nombre no puede estar vacío.',
      ));
      return;
    }

    emit(state.copyWith(
      status: TrucoParticipantStatus.loading,
      clearError: true,
    ));
    final result = await _repository.createParticipant(name);
    if (result is DataSuccess) {
      final updated = [...state.participants, result.data!]
        ..sort((a, b) => a.name.compareTo(b.name));
      emit(state.copyWith(
        status: TrucoParticipantStatus.created,
        participants: updated,
      ));
    } else {
      _emitError(emit, result, 'No se pudo crear el jugador');
    }
  }

  Future<void> _onUpdate(
    UpdateTrucoParticipantEvent event,
    Emitter<TrucoParticipantState> emit,
  ) async {
    if (!state.isAdmin) return;
    final name = event.name.trim();
    if (name.isEmpty) {
      emit(state.copyWith(
        status: TrucoParticipantStatus.error,
        error: 'El nombre no puede estar vacío.',
      ));
      return;
    }

    emit(state.copyWith(
      status: TrucoParticipantStatus.loading,
      clearError: true,
    ));
    final result = await _repository.updateParticipant(event.id, name: name);
    if (result is DataSuccess) {
      emit(state.copyWith(
        status: TrucoParticipantStatus.updated,
        participants: state.participants
            .map((p) => p.id == event.id ? result.data! : p)
            .toList(),
      ));
    } else {
      _emitError(emit, result, 'No se pudo actualizar el jugador');
    }
  }

  Future<void> _onDelete(
    DeleteTrucoParticipantEvent event,
    Emitter<TrucoParticipantState> emit,
  ) async {
    if (!state.isAdmin) return;
    emit(state.copyWith(
      status: TrucoParticipantStatus.loading,
      clearError: true,
    ));
    final result = await _repository.deleteParticipant(event.id);
    if (result is DataSuccess) {
      emit(state.copyWith(
        status: TrucoParticipantStatus.deleted,
        participants:
            state.participants.where((p) => p.id != event.id).toList(),
      ));
    } else {
      _emitError(emit, result, 'No se pudo eliminar el jugador');
    }
  }

  void _emitError(
    Emitter<TrucoParticipantState> emit,
    DataState<dynamic> result,
    String fallback,
  ) {
    emit(state.copyWith(
      status: TrucoParticipantStatus.error,
      error: result.error?.toString() ?? fallback,
    ));
  }
}
