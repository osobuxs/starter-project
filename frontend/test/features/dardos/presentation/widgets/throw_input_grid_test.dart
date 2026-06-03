import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/throw_input_grid.dart';

void main() {
  Widget buildTestWidget({
    required void Function(int number, int multiplier) onThrow,
    bool enabled = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 600,
          child: ThrowInputGrid(
            onThrow: onThrow,
            enabled: enabled,
          ),
        ),
      ),
    );
  }

  group('ThrowInputGrid', () {
    testWidgets(
        'renders number tiles for 20 numbers, bull, double bull and miss',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(onThrow: (_, __) {}));

      // 20 numbers + 25 + 50 + 0.
      expect(find.byType(InkWell), findsNWidgets(23));
    });

    testWidgets('renders miss tile', (tester) async {
      await tester.pumpWidget(buildTestWidget(onThrow: (_, __) {}));
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('renders bull tiles', (tester) async {
      await tester.pumpWidget(buildTestWidget(onThrow: (_, __) {}));
      expect(find.text('25'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('tap miss fires callback with number=0 multiplier=1',
        (tester) async {
      int? tappedNumber;
      int? tappedMultiplier;

      await tester.pumpWidget(buildTestWidget(
        onThrow: (number, multiplier) {
          tappedNumber = number;
          tappedMultiplier = multiplier;
        },
      ));

      final missButton = find.ancestor(
        of: find.text('0'),
        matching: find.byType(InkWell),
      );

      expect(missButton, findsOneWidget);
      await tester.ensureVisible(missButton);
      await tester.tap(missButton, warnIfMissed: false);
      await tester.pump();

      expect(tappedNumber, equals(0));
      expect(tappedMultiplier, equals(1));
    });

    testWidgets('buttons are disabled when enabled=false', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        enabled: false,
        onThrow: (_, __) {},
      ));

      // All tiles should be disabled (onTap == null).
      final buttons = tester.widgetList<InkWell>(find.byType(InkWell));
      for (final button in buttons) {
        expect(button.onTap, isNull, reason: 'Tile should be disabled');
      }
    });
  });
}
