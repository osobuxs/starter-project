import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_bottom_nav/dardos_bottom_nav_bloc.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_bottom_nav/dardos_bottom_nav_event.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_bottom_nav/dardos_bottom_nav_state.dart';

void main() {
  group('DardosBottomNavBloc', () {
    test('initial state is tab 0', () {
      final bloc = DardosBottomNavBloc();
      expect(bloc.state.currentTabIndex, 0);
      bloc.close();
    });

    blocTest<DardosBottomNavBloc, DardosBottomNavState>(
      'ChangeTabEvent(0) emits state with currentTabIndex = 0',
      build: () => DardosBottomNavBloc(),
      act: (bloc) => bloc.add(const ChangeTabEvent(0)),
      expect: () => [const DardosBottomNavState(currentTabIndex: 0)],
    );

    blocTest<DardosBottomNavBloc, DardosBottomNavState>(
      'ChangeTabEvent(1) emits state with currentTabIndex = 1',
      build: () => DardosBottomNavBloc(),
      act: (bloc) => bloc.add(const ChangeTabEvent(1)),
      expect: () => [const DardosBottomNavState(currentTabIndex: 1)],
    );

    blocTest<DardosBottomNavBloc, DardosBottomNavState>(
      'ChangeTabEvent(2) emits state with currentTabIndex = 2',
      build: () => DardosBottomNavBloc(),
      act: (bloc) => bloc.add(const ChangeTabEvent(2)),
      expect: () => [const DardosBottomNavState(currentTabIndex: 2)],
    );

    blocTest<DardosBottomNavBloc, DardosBottomNavState>(
      'sequential tab changes: 0->1->2 emits correct states in order',
      build: () => DardosBottomNavBloc(),
      act: (bloc) {
        bloc.add(const ChangeTabEvent(1));
        bloc.add(const ChangeTabEvent(2));
      },
      expect: () => [
        const DardosBottomNavState(currentTabIndex: 1),
        const DardosBottomNavState(currentTabIndex: 2),
      ],
    );
  });
}
