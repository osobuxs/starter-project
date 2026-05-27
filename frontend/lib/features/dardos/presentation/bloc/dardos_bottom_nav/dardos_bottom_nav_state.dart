import 'package:equatable/equatable.dart';

class DardosBottomNavState extends Equatable {
  final int currentTabIndex;

  const DardosBottomNavState({this.currentTabIndex = 0});

  DardosBottomNavState copyWith({int? currentTabIndex}) {
    return DardosBottomNavState(
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
    );
  }

  @override
  List<Object?> get props => [currentTabIndex];
}
