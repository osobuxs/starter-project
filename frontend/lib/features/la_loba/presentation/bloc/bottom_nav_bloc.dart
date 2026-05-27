import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/bottom_nav_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/bottom_nav_state.dart';

class BottomNavBloc extends Bloc<BottomNavEvent, BottomNavState> {
  BottomNavBloc() : super(const BottomNavState()) {
    on<ChangeTabEvent>(_onChangeTab);
    on<SelectGameInIniciarEvent>(_onSelectGameInIniciar);
    on<UpdateFilterEvent>(_onUpdateFilter);
  }

  Future<void> _onChangeTab(
    ChangeTabEvent event,
    Emitter<BottomNavState> emit,
  ) async {
    emit(state.copyWith(
      status: BottomNavBlocStatus.tabChanged,
      currentTabIndex: event.tabIndex,
    ));
  }

  Future<void> _onSelectGameInIniciar(
    SelectGameInIniciarEvent event,
    Emitter<BottomNavState> emit,
  ) async {
    emit(state.copyWith(
      selectedGameInIniciar: event.gameId,
    ));
  }

  Future<void> _onUpdateFilter(
    UpdateFilterEvent event,
    Emitter<BottomNavState> emit,
  ) async {
    final newFilters = {...state.filters};
    if (event.dateStart != null) newFilters['dateStart'] = event.dateStart;
    if (event.dateEnd != null) newFilters['dateEnd'] = event.dateEnd;
    if (event.participantId != null) newFilters['participantId'] = event.participantId;
    if (event.winnerId != null) newFilters['winnerId'] = event.winnerId;

    emit(state.copyWith(filters: newFilters));
  }
}
