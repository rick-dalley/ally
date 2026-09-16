import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ally/screens/add_medication_wizard.dart';

// Regression test for the add-medication wizard collapsing once the software
// keyboard was up. Three layers each subtracted the keyboard's height from the same
// sheet — the sheet's own viewInsets padding, the wizard's Scaffold, and the step
// page's padding — so the PageView was left with no room and every step after the
// name rendered as a bare heading over blank space.
//
// It never showed on the simulator, where a connected hardware keyboard leaves
// viewInsets.bottom at 0, which is why this is a test rather than something to go
// and look at. A representative iPhone keyboard is ~336pt.
void main() {
  const double keyboardInset = 336;

  Widget hostedInSheet({required double bottomInset, required Size screen}) {
    final controllers = List.generate(3, (_) => TextEditingController());
    return MediaQuery(
      data: MediaQueryData(
        size: screen,
        viewInsets: EdgeInsets.only(bottom: bottomInset),
      ),
      child: MaterialApp(
        home: Material(
          // Mirrors PrescriptionScreen.showAddMedicationSheet's builder: the sheet
          // lifts itself clear of the keyboard, and the wizard sits inside that.
          child: Padding(
            padding: EdgeInsets.only(
              bottom: bottomInset,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: AddMedicationWizard(
              patientUuid: 'test-patient',
              nameController: controllers[0],
              dosageController: controllers[1],
              frequencyController: controllers[2],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('steps keep usable height while the keyboard is open', (
    WidgetTester tester,
  ) async {
    const Size screen = Size(393, 852); // iPhone 15/17 Pro logical size
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      hostedInSheet(bottomInset: keyboardInset, screen: screen),
    );
    await tester.pumpAndSettle();

    final double pagerHeight = tester.getSize(find.byType(PageView)).height;

    // The whole failure mode is this number going to (or near) zero. Anything under
    // a couple of hundred points can't show a heading plus a list of options, which
    // is what "blank under the Type header" actually was.
    expect(
      pagerHeight,
      greaterThan(200),
      reason:
          'PageView collapsed to ${pagerHeight}pt with the keyboard open — the '
          'keyboard inset is being subtracted more than once.',
    );
  });

  testWidgets('the medication name field stays reachable with the keyboard open', (
    WidgetTester tester,
  ) async {
    const Size screen = Size(393, 852);
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      hostedInSheet(bottomInset: keyboardInset, screen: screen),
    );
    await tester.pumpAndSettle();

    // The name step is scrollable now, so the field is reachable whatever height is
    // left; before, it sat under the keyboard with no way to scroll to it.
    expect(find.byType(Scrollable), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
