import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/core/resources/data_state.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/repository/dardos_participant_repository.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_participant/dardos_participant_state.dart';

const _adminEmail = 'lfexevega95@gmail.com';

class DardosParticipantBloc
    extends Bloc<DardosParticipantEvent, DardosParticipantState> {
  final DardosParticipantRepository _repository;
  final FirebaseAuth _auth;

  DardosParticipantBloc(this._repository, this._auth)
      : super(const DardosParticipantState()) {
    on<FetchAllParticipantsEvent>(_onFetchAll);
    on<CreateParticipantEvent>(_onCreate);
    on<UpdateParticipantEvent>(_onUpdate);
    on<DeleteParticipantEvent>(_onDelete);
    on<CheckAdminStatusEvent>(_onCheckAdmin);
  }

  bool get _isAdmin =>
      _auth.currentUser?.email == _adminEmail;

  Future<void> _onFetchAll(
    FetchAllParticipantsEvent event,
    Emitter<DardosParticipantState> emit,
  ) async {
    emit(state.copyWith(status: DardosParticipantStatus.loading));

    final result = await _repository.fetchAllParticipants();
    if (result is DataSuccess) {
      emit(state.copyWith(
        status: DardosParticipantStatus.success,
        participants: result.data ?? [],
      ));
    } else {
      emit(state.copyWith(
        status: DardosParticipantStatus.error,
        error: result.error?.toString() ?? 'Error al cargar participantes',
      ));
    }
  }

  Future<void> _onCreate(
    CreateParticipantEvent event,
    Emitter<DardosParticipantState> emit,
  ) async {
    if (!_isAdmin) {
      emit(state.copyWith(
        status: DardosParticipantStatus.error,
        error: 'Solo el administrador puede crear participantes',
      ));
      return;
    }

    emit(state.copyWith(status: DardosParticipantStatus.loading));

    final result = await _repository.createParticipant(event.participant);
    if (result is DataSuccess) {
      // Refresh list
      final listResult = await _repository.fetchAllParticipants();
      emit(state.copyWith(
        status: DardosParticipantStatus.success,
        participants: listResult.data ?? state.participants,
      ));
    } else {
      emit(state.copyWith(
        status: DardosParticipantStatus.error,
        error: result.error?.toString() ?? 'Error al crear participante',
      ));
    }
  }

  Future<void> _onUpdate(
    UpdateParticipantEvent event,
    Emitter<DardosParticipantState> emit,
  ) async {
    if (!_isAdmin) {
      emit(state.copyWith(
        status: DardosParticipantStatus.error,
        error: 'Solo el administrador puede actualizar participantes',
      ));
      return;
    }

    emit(state.copyWith(status: DardosParticipantStatus.loading));

    final result = await _repository.updateParticipant(event.participant);
    if (result is DataSuccess) {
      final listResult = await _repository.fetchAllParticipants();
      emit(state.copyWith(
        status: DardosParticipantStatus.success,
        participants: listResult.data ?? state.participants,
      ));
    } else {
      emit(state.copyWith(
        status: DardosParticipantStatus.error,
        error: result.error?.toString() ?? 'Error al actualizar participante',
      ));
    }
  }

  Future<void> _onDelete(
    DeleteParticipantEvent event,
    Emitter<DardosParticipantState> emit,
  ) async {
    if (!_isAdmin) {
      emit(state.copyWith(
        status: DardosParticipantStatus.error,
        error: 'Solo el administrador puede eliminar participantes',
      ));
      return;
    }

    emit(state.copyWith(status: DardosParticipantStatus.loading));

    final result = await _repository.deleteParticipant(event.participantId);
    if (result is DataSuccess) {
      final listResult = await _repository.fetchAllParticipants();
      emit(state.copyWith(
        status: DardosParticipantStatus.success,
        participants: listResult.data ?? state.participants,
      ));
    } else {
      emit(state.copyWith(
        status: DardosParticipantStatus.error,
        error: result.error?.toString() ?? 'Error al eliminar participante',
      ));
    }
  }

  void _onCheckAdmin(
    CheckAdminStatusEvent event,
    Emitter<DardosParticipantState> emit,
  ) {
    emit(state.copyWith(isAdmin: _isAdmin));
  }
}
