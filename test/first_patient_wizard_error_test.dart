import 'package:ally/screens/first_patient_wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression test for the name step's validation error shoving the page around.
//
// The error used to be spliced into the column only once it was set, so the first tap
// on Next pushed Next/Skip/Back down the screen — the button moved out from under the
// thumb at the moment the person was looking at it. It was also drawn in white on a
// white background, so what they actually saw was the button jumping for no reason.
//
// Sized to the Galaxy A17 that is the real test device (~360dp wide), because that is
// the width where the message wraps to two lines and the shift was worst.
void main() {
  const Size galaxyA17 = Size(360, 800);
  const String requiredMessage = 'First name, last name, and date of birth are all required.';

  Future<void> pumpWizard(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(galaxyA17);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: Material(child: FirstPatientWizard())));
    await tester.pumpAndSettle();
  }

  // Both of these steps run taller than the viewport, so their buttons start below the
  // fold and have to be scrolled to before they can be tapped.
  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  // Step 0 is the welcome screen; the name step sits behind "Get Started".
  Future<void> advanceToNameStep(WidgetTester tester) async {
    await tapButton(tester, 'Get Started');
    expect(find.text("Let's get started"), findsOneWidget);
  }

  // The gap between the last field on the step and the Next button, which is what the
  // error slot is there to hold constant. Measured as a distance rather than as an
  // absolute position so that scrolling the button into view can't affect the result.
  double gapBelowFields(WidgetTester tester) {
    final double dobBottom = tester.getBottomLeft(find.text('Date of Birth')).dy;
    final double nextTop = tester.getTopLeft(find.text('Next')).dy;
    return nextTop - dobBottom;
  }

  testWidgets('showing the required-fields error does not move the Next button', (tester) async {
    await pumpWizard(tester);
    await advanceToNameStep(tester);

    final double before = gapBelowFields(tester);

    // Tap Next with every field still empty — the path that raises the error.
    await tapButton(tester, 'Next');

    expect(find.text(requiredMessage), findsOneWidget, reason: 'the error should actually be shown');
    expect(
      gapBelowFields(tester),
      before,
      reason: 'the error slot is reserved, so Next must not be pushed down when the error appears',
    );
  });

  testWidgets('the error is legible rather than white on white', (tester) async {
    await pumpWizard(tester);
    await advanceToNameStep(tester);
    await tapButton(tester, 'Next');

    final Text error = tester.widget<Text>(find.text(requiredMessage));
    expect(error.style?.color, isNotNull);
    expect(
      error.style!.color,
      isNot(const Color(0xFFFFFFFF)),
      reason: 'dangerTextStyle used the on-danger-button token, which is pure white',
    );
  });

  testWidgets('the error stays up while the thing it complains about is still missing', (tester) async {
    await pumpWizard(tester);
    await advanceToNameStep(tester);
    await tapButton(tester, 'Next');
    expect(find.text(requiredMessage), findsOneWidget);

    // Filling in only the names leaves the date of birth outstanding, so the message
    // is still true and should stay put. (It clears on the date being picked, which
    // needs the platform date picker and so isn't reachable from a widget test.)
    // CarbonTextInput draws its label as a sibling Text rather than an InputDecoration
    // label, so the fields are addressed by position: first name then last name, the
    // only two on this step.
    final Finder fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'Richard');
    await tester.enterText(fields.at(1), 'Dalley');
    await tester.pumpAndSettle();

    expect(find.text(requiredMessage), findsOneWidget, reason: 'date of birth is still missing');
  });
}
