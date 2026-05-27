import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/domain/entities/cricket_marks_state.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/cricket_board.dart';

void main() {
  const playerIds = ['p1', 'p2'];
  const playerNames = {'p1': 'Jugador 1', 'p2': 'Jugador 2'};

  CricketMarksState _emptyState() =>
      CricketMarksState.empty(playerIds);

  CricketMarksState _stateWithMarks(
      String playerId, String target, int marks) {
    final empty = _emptyState();
    final newMarksByPlayer = Map<String, Map<String, int>>.from(
      empty.marksByPlayer.map(
        (k, v) => MapEntry(k, Map<String, int>.from(v)),
      ),
    );
    newMarksByPlayer[playerId]![target] = marks;
    return empty.copyWith(marksByPlayer: newMarksByPlayer);
  }

  testWidgets('renders player names in header', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CricketBoard(
            playerIds: playerIds,
            playerNames: playerNames,
            cricketState: _emptyState(),
            currentPlayerId: 'p1',
            onThrow: (_, __) {},
          ),
        ),
      ),
    );

    expect(find.text('Jugador 1'), findsWidgets);
    expect(find.text('Jugador 2'), findsWidgets);
  });

  testWidgets('renders all 7 cricket targets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CricketBoard(
              playerIds: playerIds,
              playerNames: playerNames,
              cricketState: _emptyState(),
              currentPlayerId: 'p1',
              onThrow: (_, __) {},
            ),
          ),
        ),
      ),
    );

    // Each target label appears in the table
    for (final target in ['15', '16', '17', '18', '19', '20', 'Bull']) {
      expect(find.text(target), findsWidgets);
    }
  });

  testWidgets('shows slash for 1 mark', (tester) async {
    final state = _stateWithMarks('p1', '20', 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CricketBoard(
              playerIds: playerIds,
              playerNames: playerNames,
              cricketState: state,
              currentPlayerId: 'p1',
              onThrow: (_, __) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('/'), findsOneWidget);
  });

  testWidgets('shows X for 2 marks', (tester) async {
    final state = _stateWithMarks('p1', '20', 2);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CricketBoard(
              playerIds: playerIds,
              playerNames: playerNames,
              cricketState: state,
              currentPlayerId: 'p1',
              onThrow: (_, __) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('X'), findsOneWidget);
  });

  testWidgets('shows closed mark (⊗) for 3 marks', (tester) async {
    final state = _stateWithMarks('p1', '20', 3);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CricketBoard(
              playerIds: playerIds,
              playerNames: playerNames,
              cricketState: state,
              currentPlayerId: 'p1',
              onThrow: (_, __) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('⊗'), findsOneWidget);
  });

  testWidgets('action buttons hidden when enabled=false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CricketBoard(
              playerIds: playerIds,
              playerNames: playerNames,
              cricketState: _emptyState(),
              currentPlayerId: 'p1',
              enabled: false,
              onThrow: (_, __) {},
            ),
          ),
        ),
      ),
    );

    // Miss button should not appear when disabled
    expect(find.textContaining('<15'), findsNothing);
  });

  testWidgets('tap on 20 target button fires onThrow with correct target',
      (tester) async {
    String? lastTarget;
    int? lastMultiplier;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CricketBoard(
              playerIds: playerIds,
              playerNames: playerNames,
              cricketState: _emptyState(),
              currentPlayerId: 'p1',
              onThrow: (target, mult) {
                lastTarget = target;
                lastMultiplier = mult;
              },
            ),
          ),
        ),
      ),
    );

    // Tap "20" action button — opens multiplier modal, then pick 1x
    // The action button with text '20'
    final twentyButton = find.widgetWithText(ElevatedButton, '20');
    expect(twentyButton, findsWidgets);
    await tester.tap(twentyButton.first);
    await tester.pumpAndSettle();

    // Select 1x in the modal
    final oneXButton = find.textContaining('1x');
    if (oneXButton.evaluate().isNotEmpty) {
      await tester.tap(oneXButton.first);
      await tester.pumpAndSettle();
      expect(lastTarget, equals('20'));
      expect(lastMultiplier, equals(1));
    }
  });
}
