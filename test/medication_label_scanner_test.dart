import 'package:ally/classes/medication_label_scanner.dart';
import 'package:ally/classes/medication_services.dart';
import 'package:flutter_test/flutter_test.dart';

// Transcriptions of what ML Kit actually returns for a dispensed label: all caps,
// line order roughly top-to-bottom, pharmacy furniture mixed in with the useful
// parts. The parser is a pure function over this string, so the whole read path
// can be exercised here without a camera.
void main() {
  group('parseLabelText', () {
    test('reads drug, strength and sig off a standard retail label', () {
      const label = '''
SHOPPERS DRUG MART #1234
123 MAIN ST, VANCOUVER BC
DALLEY, RICHARD
RX# 8842219
AMLODIPINE 5 MG TABLET
TAKE 1 TABLET BY MOUTH ONCE DAILY
QTY: 30
REFILLS: 2
DR. A. PATEL
''';

      final result = MedicationLabelScanner.parseLabelText(label);

      expect(result.name, 'Amlodipine');
      expect(result.amount, '5');
      expect(result.unit, DosageUnit.mg);
      expect(result.form, MedicationTypes.tablet);
      expect(result.directions, 'TAKE 1 TABLET BY MOUTH ONCE DAILY');
      expect(result.quantity, '30');
      expect(result.rxNumber, '8842219');
      expect(result.dosageLabel, '5 mg');
    });

    test('prefers the generic name when a brand precedes it in parentheses', () {
      const label = '''
NORVASC (AMLODIPINE) 10 MG TABLET
TAKE 1 TABLET DAILY
''';

      final result = MedicationLabelScanner.parseLabelText(label);

      expect(result.name, 'Amlodipine');
      expect(result.amount, '10');
    });

    test('does not mistake the sig dose for the pill strength', () {
      // "TAKE 2 TABLETS" carries a number and a unit-ish word, but it is how many
      // to take, not how strong each one is.
      const label = '''
METFORMIN 500 MG TABLET
TAKE 2 TABLETS BY MOUTH TWICE DAILY WITH FOOD
''';

      final result = MedicationLabelScanner.parseLabelText(label);

      expect(result.amount, '500');
      expect(result.unit, DosageUnit.mg);
      expect(result.name, 'Metformin');
    });

    test('falls back to the line above when the name is stacked over the strength', () {
      const label = '''
LONDON DRUGS PHARMACY
LEVOTHYROXINE
25 MCG TABLET
TAKE 1 TABLET EACH MORNING
''';

      final result = MedicationLabelScanner.parseLabelText(label);

      expect(result.name, 'Levothyroxine');
      expect(result.amount, '25');
      expect(result.unit, DosageUnit.mcg);
    });

    test('does not read the patient name as the drug', () {
      const label = '''
DALLEY, RICHARD
1234 SOMEWHERE AVE
RAMIPRIL 2.5 MG CAPSULE
''';

      final result = MedicationLabelScanner.parseLabelText(label);

      expect(result.name, 'Ramipril');
      expect(result.amount, '2.5');
      expect(result.form, MedicationTypes.capsule);
    });

    test('leaves the unit unset rather than guessing when it has no DosageUnit', () {
      // Grams have no entry in DosageUnit. Recording "2 mg" for a 2 g dose would
      // be a thousand-fold error, so the unit stays null and the review screen asks.
      const label = 'CALCIUM CARBONATE 2 G TABLET';

      final result = MedicationLabelScanner.parseLabelText(label);

      expect(result.amount, '2');
      expect(result.unit, isNull);
      expect(result.dosageLabel, isNull);
    });

    // The reported failure: scanning a real bottle came back with the pharmacy's name
    // as the medication, because the biggest, cleanest text on a dispensed label is the
    // chain's logo across the top and the name used to be searched for label-wide.
    test('never reports the pharmacy banner as the medication', () {
      const label = '''
SHOPPERS
DRUG MART
#2184  604-555-0134
1290 ROBSON ST
DALLEY, RICHARD
RAMIPRIL 10 MG CAPSULE
TAKE 1 CAPSULE DAILY
''';

      final result = MedicationLabelScanner.parseLabelText(label);

      expect(result.name, 'Ramipril');
      expect(result.name, isNot(contains('Shoppers')));
      expect(result.name, isNot(contains('Drug')));
    });

    test('leaves the name blank rather than guessing when there is no strength', () {
      // Nothing here anchors a drug name. Guessing would hand back "Shoppers" or the
      // prescriber; a blank field costs one typed word and is honest.
      const label = '''
SHOPPERS
DRUG MART
DALLEY, RICHARD
TAKE ONE DAILY
''';

      final result = MedicationLabelScanner.parseLabelText(label);

      expect(result.name, isNull);
    });

    test('does not take the pharmacy line even when it sits beside the strength', () {
      const label = '''
LONDON DRUGS
500 MG
''';

      final result = MedicationLabelScanner.parseLabelText(label);

      expect(result.amount, '500');
      expect(result.name, isNull);
    });

    test('reports emptiness for a label it could not read at all', () {
      final result = MedicationLabelScanner.parseLabelText('#### ~~~ ????');
      expect(result.isEmpty, isTrue);
    });

    test('picks up a liquid form and mL strength', () {
      const label = '''
AMOXICILLIN 250 MG/5 ML SUSPENSION
TAKE 5 ML BY MOUTH THREE TIMES DAILY
''';

      final result = MedicationLabelScanner.parseLabelText(label);

      expect(result.name, 'Amoxicillin');
      expect(result.form, MedicationTypes.liquid);
    });
  });
}
