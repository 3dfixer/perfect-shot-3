import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_shot_app/models/series.dart';
import 'package:perfect_shot_app/screens/home_screen.dart';

void main() {
  testWidgets('simulation never scores below 2 and stops at 60 shots',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.tap(find.byTooltip('Start Simulation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pump();

    // Let the simulation run past 60 one-second ticks.
    for (var i = 0; i < 65; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // The session review screen opens on top when the 60th shot lands, so
    // the home screen is offstage by now.
    final state =
        tester.state(find.byType(HomeScreen, skipOffstage: false)) as dynamic;
    final List<Series> allSeries = state.allSeries as List<Series>;
    final shots = allSeries.expand((s) => s.shots).toList();

    expect(shots.length, 60);
    expect(shots.every((s) => s.score >= 2), isTrue);
    expect(allSeries.every((s) => s.shots.length == 10), isTrue);
  });
}
