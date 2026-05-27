import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/bloc/dardos_game/dardos_game_state.dart';
import 'package:news_app_clean_architecture/features/dardos/presentation/widgets/auto_advance_banner.dart';

void main() {
  group('AutoAdvanceBanner', () {
    testWidgets('not visible when bannerType is none', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoAdvanceBanner(
              bannerType: DardosBannerType.none,
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.byType(AutoAdvanceBanner), findsOneWidget);
      // No content should be shown
      expect(find.text('BUST!'), findsNothing);
      expect(find.text('¡Leg ganado!'), findsNothing);
    });

    testWidgets('shows bust text for bust banner type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoAdvanceBanner(
              bannerType: DardosBannerType.bust,
              bannerPayload: '501',
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('BUST!'), findsOneWidget);
      expect(find.textContaining('501'), findsOneWidget);
    });

    testWidgets('shows leg won text for legWon banner type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoAdvanceBanner(
              bannerType: DardosBannerType.legWon,
              bannerPayload: '¡Ganó Exe el Leg 1!',
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('¡Leg ganado!'), findsOneWidget);
      expect(find.textContaining('Exe'), findsOneWidget);
    });

    testWidgets('shows set won text for setWon banner type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoAdvanceBanner(
              bannerType: DardosBannerType.setWon,
              bannerPayload: 'Set 1 para Exe',
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('¡Set ganado!'), findsOneWidget);
    });

    testWidgets('auto-dismisses after exactly 2000ms via fakeAsync',
        (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoAdvanceBanner(
              bannerType: DardosBannerType.bust,
              onDismiss: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      expect(dismissed, isFalse);

      // Advance time by 1999ms — should NOT dismiss yet
      await tester.pump(const Duration(milliseconds: 1999));
      expect(dismissed, isFalse);

      // Advance by 1ms more (total 2000ms) — should dismiss
      await tester.pump(const Duration(milliseconds: 1));
      expect(dismissed, isTrue);
    });

    testWidgets('tap on banner dismisses immediately', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoAdvanceBanner(
              bannerType: DardosBannerType.bust,
              onDismiss: () {
                dismissed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(dismissed, isTrue);
    });
  });
}
