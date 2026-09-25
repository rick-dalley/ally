import 'package:ally/classes/drug_name_matcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// The type-ahead exists to serve two callers that look different and are the same
// problem: someone who doesn't want to spell "hydrochlorothiazide", and a label scan
// that only saw "HYDROCHLOROT" because the rest wrapped around the back of the bottle.
void main() {
  late DrugNameMatcher matcher;

  setUp(() {
    matcher = DrugNameMatcher();
    matcher.loadFromLines(const [
      '# a comment, and a blank line, both skipped',
      '',
      'hydrochlorothiazide',
      'hydrocortisone',
      'hydromorphone',
      'hydralazine',
      'metformin',
      'methylprednisolone',
      'metoprolol',
      'methotrexate',
      'levothyroxine',
      'amlodipine',
      'amoxicillin',
      'acetylsalicylic acid',
      'vitamin d3',
    ]);
  });

  test('skips comments and blank lines when loading', () {
    expect(matcher.size, 13);
    expect(matcher.isLoaded, isTrue);
  });

  group('typing', () {
    test('completes a short prefix', () {
      final names = matcher.suggest('hydro').map((s) => s.name).toList();
      expect(names, contains('Hydrochlorothiazide'));
      expect(names, contains('Hydrocortisone'));
    });

    test('orders equal prefix matches alphabetically, not by length', () {
      // Ranking shorter names higher buried Hydrochlorothiazide under Hydromorphone
      // and Hydrocortisone — the one name in that list nobody wants to spell, pushed
      // out of the visible dropdown. Length is a bad proxy for likelihood.
      final names = matcher.suggest('hydro').map((s) => s.name).toList();
      expect(names.first, 'Hydrochlorothiazide');
      expect(
        names.take(3).toList(),
        ['Hydrochlorothiazide', 'Hydrocortisone', 'Hydromorphone'],
      );

      final mets = matcher.suggest('met').map((s) => s.name).toList();
      expect(mets.first, 'Metformin');
      expect(mets, contains('Methylprednisolone'));
    });

    test('an exact name outranks everything it is a prefix of', () {
      final top = matcher.suggest('metformin').first;
      expect(top.name, 'Metformin');
      expect(top.kind, DrugMatchKind.exact);
      expect(top.score, 1);
    });

    test('tolerates a typo', () {
      // A dropped 'h' — not a prefix and not a substring of anything.
      final names = matcher.suggest('hydroclorothiazide').map((s) => s.name).toList();
      expect(names, contains('Hydrochlorothiazide'));
    });

    test('ignores spacing and punctuation', () {
      final names = matcher.suggest('acetylsalicylic-acid').map((s) => s.name).toList();
      expect(names.first, 'Acetylsalicylic Acid');
    });

    test('says nothing at all for one or two characters', () {
      expect(matcher.suggest('h'), isEmpty);
      expect(matcher.suggest('hy'), isEmpty);
    });

    test('returns nothing rather than a wild guess for an unrelated word', () {
      expect(matcher.suggest('shoppers'), isEmpty);
      expect(matcher.suggest('pharmacy'), isEmpty);
    });
  });

  group('label fragments', () {
    test('resolves a name truncated by the curve of the bottle', () {
      // The reported case: the label wraps and the camera only ever sees the front.
      final suggestions = matcher.suggest('HYDROCHLOROT');
      expect(suggestions.first.name, 'Hydrochlorothiazide');
      expect(suggestions.first.kind, DrugMatchKind.prefix);
    });

    test('resolves a fragment with digits OCR mistook for letters', () {
      // 0 for O is the classic misread on small, curved, low-contrast print.
      final suggestions = matcher.suggest('HYDR0CHL0R0T');
      expect(suggestions.first.name, 'Hydrochlorothiazide');
    });

    test('resolves a fragment that is both truncated and misread', () {
      // Truncated AND a wrong character — the usual case off a real bottle, and the
      // reason a fragment is compared against the candidate's prefix rather than the
      // whole name.
      final suggestions = matcher.suggest('LEV0THYR0X');
      expect(suggestions.map((s) => s.name), contains('Levothyroxine'));
    });

    test('a very short fragment still narrows the field usefully', () {
      final suggestions = matcher.suggest('amlo');
      expect(suggestions.first.name, 'Amlodipine');
    });

    test('honours the limit', () {
      expect(matcher.suggest('hydro', limit: 2).length, 2);
    });
  });

  group('whole labels', () {
    // The real job: hand it every line OCR returned and let the vocabulary decide
    // which of them is a drug. No parsing, no layout assumptions, no noise lists.
    test('finds the drug among the pharmacy furniture', () {
      final lines = '''
SHOPPERS
DRUG MART #2184
1290 ROBSON ST  604-555-0134
DALLEY, RICHARD
HYDROCHLOROTHIAZIDE 25 MG TABLET
TAKE 1 TABLET BY MOUTH DAILY
DR. A. PATEL
REFILLS: 2
'''
          .trim()
          .split('\n');

      final names = matcher.suggestFromLines(lines).map((s) => s.name).toList();

      expect(names.first, 'Hydrochlorothiazide');
      expect(names, isNot(contains('Shoppers')));
    });

    test('finds a drug whose name was cut off by the curve of the bottle', () {
      // The reported failure: most of the name was visible and it still came back
      // as nothing, because the old path needed to parse a strength to anchor a name.
      final lines = ['HYDROCHLOROT', '25 MG TABLET', 'TAKE 1 DAILY'];

      final names = matcher.suggestFromLines(lines).map((s) => s.name).toList();

      expect(names, contains('Hydrochlorothiazide'));
    });

    test('works when the name shares a line with strength and form', () {
      final names = matcher.suggestFromLines(['AMLODIPINE 5MG TAB']).map((s) => s.name).toList();
      expect(names.first, 'Amlodipine');
    });

    test('offers nothing at all for a label with no drug on it', () {
      final lines = ['SHOPPERS', 'DRUG MART', '1290 ROBSON ST', 'DALLEY, RICHARD'];
      expect(matcher.suggestFromLines(lines), isEmpty);
    });

    test('ignores scraps too short to nominate anything', () {
      expect(matcher.suggestFromLines(['MG', 'TAB', 'QTY', '30']), isEmpty);
    });
  });

  group('the bundled asset', () {
    testWidgets('loads and resolves a real fragment end to end', (tester) async {
      final DrugNameMatcher real = DrugNameMatcher();
      await real.load(bundle: rootBundle);

      expect(real.size, greaterThan(250));
      expect(real.suggest('HYDROCHLOROT').first.name, 'Hydrochlorothiazide');
      expect(real.suggest('levothyr').first.name, 'Levothyroxine');
      expect(real.suggest('pantopraz').first.name, 'Pantoprazole');
    });
  });
}
