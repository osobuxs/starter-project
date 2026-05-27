import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_bottom_nav/dardos_bottom_nav_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_bottom_nav/dardos_bottom_nav_state.dart';

class DardosBottomNavBloc
    extends Bloc<DardosBottomNavEvent, DardosBottomNavState> {
  DardosBottomNavBloc() : super(const DardosBottomNavState()) {
    on<ChangeTabEvent>(_onChangeTab);
  }

  void _onChangeTab(
    ChangeTabEvent event,
    Emitter<DardosBottomNavState> emit,
  ) {
    emit(state.copyWith(currentTabIndex: event.index));
  }
}
