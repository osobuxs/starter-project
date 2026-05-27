import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/cricket_marks_state.dart';

void main() {
  group('CricketMarksState', () {
    final targets = ['15', '16', '17', '18', '19', '20', 'bull'];
    final playerIds = ['p1', 'p2'];

    group('empty factory', () {
      test('creates zero marks for all targets per player', () {
        final state = CricketMarksState.empty(playerIds);

        for (final pid in playerIds) {
          expect(state.marksByPlayer.containsKey(pid), isTrue);
          for (final t in targets) {
            expect(state.marksByPlayer[pid]![t], 0);
          }
        }
      });

      test('creates zero points for all players', () {
        final state = CricketMarksState.empty(playerIds);

        for (final pid in playerIds) {
          expect(state.pointsByPlayer[pid], 0);
        }
      });

      test('works with single player list', () {
        final state = CricketMarksState.empty(['p1']);
        expect(state.marksByPlayer['p1'], isNotNull);
        expect(state.pointsByPlayer['p1'], 0);
      });

      test('works with 3 players', () {
        final state = CricketMarksState.empty(['p1', 'p2', 'p3']);
        expect(state.marksByPlayer.keys.length, 3);
        expect(state.pointsByPlayer.keys.length, 3);
      });
    });

    group('equality (Equatable)', () {
      test('two empty states with same players are equal', () {
        final s1 = CricketMarksState.empty(playerIds);
        final s2 = CricketMarksState.empty(playerIds);
        expect(s1, equals(s2));
      });

      test('states with different marks are not equal', () {
        final s1 = CricketMarksState.empty(playerIds);
        final s2 = CricketMarksState(
          marksByPlayer: {
            'p1': {'15': 1, '16': 0, '17': 0, '18': 0, '19': 0, '20': 0, 'bull': 0},
            'p2': {'15': 0, '16': 0, '17': 0, '18': 0, '19': 0, '20': 0, 'bull': 0},
          },
          pointsByPlayer: {'p1': 0, 'p2': 0},
        );
        expect(s1, isNot(equals(s2)));
      });
    });

    group('copyWith', () {
      test('copyWith returns same values when nothing is overridden', () {
        final state = CricketMarksState.empty(playerIds);
        final copy = state.copyWith();
        expect(copy, equals(state));
      });

      test('copyWith changes marksByPlayer', () {
        final state = CricketMarksState.empty(playerIds);
        final newMarks = {
          'p1': {'15': 3, '16': 0, '17': 0, '18': 0, '19': 0, '20': 0, 'bull': 0},
          'p2': {'15': 0, '16': 0, '17': 0, '18': 0, '19': 0, '20': 0, 'bull': 0},
        };
        final copy = state.copyWith(marksByPlayer: newMarks);
        expect(copy.marksByPlayer['p1']!['15'], 3);
      });

      test('copyWith changes pointsByPlayer', () {
        final state = CricketMarksState.empty(playerIds);
        final copy = state.copyWith(pointsByPlayer: {'p1': 45, 'p2': 0});
        expect(copy.pointsByPlayer['p1'], 45);
      });
    });
  });
}
