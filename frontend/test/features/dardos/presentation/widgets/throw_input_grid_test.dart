import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/throw_input_grid.dart';

void main() {
  Widget _buildTestWidget({
    required void Function(int number, int multiplier) onThrow,
    bool enabled = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ThrowInputGrid(
            onThrow: onThrow,
            enabled: enabled,
          ),
        ),
      ),
    );
  }

  group('ThrowInputGrid', () {
    testWidgets('renders at least 21 buttons (20 numbers + bull + miss)',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(onThrow: (_, __) {}));

      // 20 numbers + Bull + Miss = 22 ElevatedButtons
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(21));
    });

    testWidgets('renders Miss button', (tester) async {
      await tester.pumpWidget(_buildTestWidget(onThrow: (_, __) {}));
      expect(find.textContaining('Miss'), findsOneWidget);
    });

    testWidgets('renders Bull button', (tester) async {
      await tester.pumpWidget(_buildTestWidget(onThrow: (_, __) {}));
      expect(find.textContaining('Bull'), findsOneWidget);
    });

    testWidgets('tap Miss fires callback with number=0 multiplier=1',
        (tester) async {
      int? tappedNumber;
      int? tappedMultiplier;

      await tester.pumpWidget(_buildTestWidget(
        onThrow: (number, multiplier) {
          tappedNumber = number;
          tappedMultiplier = multiplier;
        },
      ));

      // Find the Miss button by its predicate (text contains 'Miss')
      final missButton = find.byWidgetPredicate((widget) {
        if (widget is! ElevatedButton) return false;
        final child = widget.child;
        if (child is! Text) return false;
        return child.data?.contains('Miss') ?? false;
      });

      expect(missButton, findsOneWidget);
      await tester.ensureVisible(missButton);
      await tester.tap(missButton, warnIfMissed: false);
      await tester.pump();

      expect(tappedNumber, equals(0));
      expect(tappedMultiplier, equals(1));
    });

    testWidgets('buttons are disabled when enabled=false', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        enabled: false,
        onThrow: (_, __) {},
      ));

      // All ElevatedButtons should be disabled (onPressed == null)
      final buttons =
          tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
      for (final button in buttons) {
        expect(button.onPressed, isNull,
            reason:
                'Button "${(button.child as Text?)?.data}" should be disabled');
      }
    });
  });
}
