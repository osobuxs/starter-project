import 'package:equatable/equatable.dart';

enum BottomNavBlocStatus {
  initial,
  tabChanged,
}

class BottomNavState extends Equatable {
  final BottomNavBlocStatus status;
  final int currentTabIndex;
  final String? selectedGameInIniciar;
  final Map<String, dynamic> filters;

  const BottomNavState({
    this.status = BottomNavBlocStatus.initial,
    this.currentTabIndex = 0,
    this.selectedGameInIniciar,
    this.filters = const {},
  });

  BottomNavState copyWith({
    BottomNavBlocStatus? status,
    int? currentTabIndex,
    String? selectedGameInIniciar,
    bool clearSelectedGame = false,
    Map<String, dynamic>? filters,
  }) {
    return BottomNavState(
      status: status ?? this.status,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      selectedGameInIniciar: clearSelectedGame ? null : (selectedGameInIniciar ?? this.selectedGameInIniciar),
      filters: filters ?? this.filters,
    );
  }

  @override
  List<Object?> get props => [status, currentTabIndex, selectedGameInIniciar, filters];
}
