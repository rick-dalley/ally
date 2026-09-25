import 'package:ally/classes/drug_name_matcher.dart';
import 'package:ally/screens/get_medication_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Proves the wiring, not the matcher — that the medication name field is actually
// backed by the vocabulary, that picking a suggestion lands in the controller the
// wizard saves from, and that a scanned value can still be pushed into the field.
void main() {
  late TextEditingController nameController;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadDrugNames();
  });

  setUp(() => nameController = TextEditingController());
  tearDown(() => nameController.dispose());

  Future<void> pumpField(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GetMedicationName(
            nameController: nameController,
            onAddMedication: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the vocabulary actually loaded from the bundle', (tester) async {
    expect(drugNames.isLoaded, isTrue);
    expect(drugNames.size, greaterThan(250));
  });

  testWidgets('typing a few letters suggests the full drug name', (tester) async {
    await pumpField(tester);

    await tester.enterText(find.byType(TextField).first, 'hydro');
    await tester.pumpAndSettle();

    expect(
      find.text('Hydrochlorothiazide'),
      findsOneWidget,
      reason: 'five letters should be enough to offer the name nobody wants to type',
    );
  });

  testWidgets('picking a suggestion fills the controller the wizard saves from', (tester) async {
    await pumpField(tester);

    await tester.enterText(find.byType(TextField).first, 'hydro');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hydrochlorothiazide'));
    await tester.pumpAndSettle();

    expect(nameController.text, 'Hydrochlorothiazide');
  });

  testWidgets('a label fragment resolves to the whole name', (tester) async {
    // The curved-bottle case, through the real field rather than the matcher alone.
    await pumpField(tester);

    await tester.enterText(find.byType(TextField).first, 'HYDROCHLOROT');
    await tester.pumpAndSettle();

    expect(find.text('Hydrochlorothiazide'), findsOneWidget);
  });

  testWidgets('a value pushed into the controller shows in the field', (tester) async {
    // This is how a scan result reaches the field; it only works because the caller
    // owns the controller rather than CarbonAutocomplete keeping its own.
    await pumpField(tester);

    nameController.text = 'Ramipril';
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Ramipril'), findsOneWidget);
  });

  testWidgets('offers nothing for a pharmacy name', (tester) async {
    await pumpField(tester);

    await tester.enterText(find.byType(TextField).first, 'shoppers');
    await tester.pumpAndSettle();

    expect(find.text('Shoppers'), findsNothing);
  });
}
