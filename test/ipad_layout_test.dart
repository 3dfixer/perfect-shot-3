import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_shot_app/screens/home_screen.dart';

void main() {
  // iPad mini (6th gen) logical size, in both orientations.
  const sizes = <String, Size>{
    'iPad mini portrait': Size(744, 1133),
    'iPad mini landscape': Size(1133, 744),
  };

  for (final entry in sizes.entries) {
    testWidgets('home screen has no layout errors (${entry.key})',
        (WidgetTester tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Run a few simulated shots so the target and score cards are drawn.
      await tester.tap(find.byTooltip('Start Simulation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(tester.takeException(), isNull);

      // Stop the simulation so no timers are left running.
      await tester.tap(find.byTooltip('Stop Simulation'));
      await tester.pump();
    });
  }
}
