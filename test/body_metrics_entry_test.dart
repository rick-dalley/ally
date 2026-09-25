import 'package:ally/widgets/body_metrics_entry_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The step used to carry its own SAVE button, so height and weight were only ever
// published to the wizard if the person noticed it and tapped it — on a step whose
// own subtitle invites them to skip. Values now leave on every edit and again on
// focus loss, and the button is gone.
void main() {
  double? lastWeight;
  double? lastHeight;
  int emitCount = 0;

  setUp(() {
    lastWeight = null;
    lastHeight = null;
    emitCount = 0;
  });

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BodyMetricsEntryWidget(
            onMetricsChanged: (weight, height) {
              lastWeight = weight;
              lastHeight = height;
              emitCount++;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('has no SAVE button', (tester) async {
    await pumpWidget(tester);
    expect(find.text('SAVE'), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('publishes both metrics as they are typed, with no button tapped', (tester) async {
    await pumpWidget(tester);

    final Finder fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));

    await tester.enterText(fields.at(0), '178');
    await tester.pumpAndSettle();
    expect(lastHeight, 178);

    await tester.enterText(fields.at(1), '82.5');
    await tester.pumpAndSettle();
    expect(lastWeight, 82.5);

    // Both travel together on every emit, so editing one never publishes a stale
    // value for the other — the one guarantee the SAVE button was there to provide.
    expect(lastHeight, 178);
    expect(emitCount, greaterThan(0));
  });

  testWidgets('publishes again when a field loses focus', (tester) async {
    await pumpWidget(tester);

    final Finder fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '165');
    await tester.pumpAndSettle();

    final int countBeforeFocusChange = emitCount;

    // Move focus to the other field — leaving the first one.
    await tester.tap(fields.at(1));
    await tester.pumpAndSettle();

    expect(emitCount, greaterThan(countBeforeFocusChange));
    expect(lastHeight, 165);
  });

  testWidgets('clearing a field publishes null rather than keeping the old value', (tester) async {
    await pumpWidget(tester);

    final Finder fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '178');
    await tester.pumpAndSettle();
    expect(lastHeight, 178);

    await tester.enterText(fields.at(0), '');
    await tester.pumpAndSettle();
    expect(lastHeight, isNull);
  });
}
