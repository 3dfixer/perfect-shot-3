import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_shot_app/models/series.dart';
import 'package:perfect_shot_app/models/shot.dart';
import 'package:perfect_shot_app/screens/session_review_screen.dart';

void main() {
  // Logical screen sizes: Pixel 8, a small phone and a large phone.
  const sizes = <String, Size>{
    'Pixel 8': Size(412, 915),
    'small phone': Size(360, 640),
    'large phone': Size(480, 1000),
  };

  for (final targetType in TargetType.values) {
    for (final entry in sizes.entries) {
      testWidgets(
          'review screen has no layout overflow (${targetType.name}, ${entry.key})',
          (WidgetTester tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final allSeries = List.generate(6, (_) => Series());

        await tester.pumpWidget(MaterialApp(
          home: SessionReviewScreen(
            allSeries: allSeries,
            targetType: targetType,
            useDecimalScoring: true,
            totalScore: 0,
            totalDecimalScore: 0,
            sessionStartTime: DateTime(2026, 10, 2, 9, 5),
          ),
        ));
        await tester.pumpAndSettle();

        // A RenderFlex overflow is reported as a test exception.
        expect(tester.takeException(), isNull);
        expect(find.text('Perfect Shot'), findsOneWidget);
        expect(find.textContaining('ISSF'), findsNothing);
      });
    }
  }
}
