import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'medication_services.dart';

/// What a single pass over a dispensed pill-bottle label managed to read.
///
/// Deliberately all-nullable apart from [rawText]: a label read is a best effort,
/// not a contract. A field this couldn't find stays null so the review screen can
/// say "I didn't get this one" rather than showing a confidently wrong guess —
/// which, for a dose, is the difference between a slow entry and a dangerous one.
class ScannedMedicationLabel {
  final String? name;
  final String? amount; // the numeric part of the strength, e.g. "5"
  final DosageUnit? unit;
  final MedicationTypes? form;
  final String? directions; // the sig line, e.g. "TAKE 1 TABLET BY MOUTH DAILY"
  final String? quantity;
  final String? rxNumber;
  final String rawText;

  const ScannedMedicationLabel({
    this.name,
    this.amount,
    this.unit,
    this.form,
    this.directions,
    this.quantity,
    this.rxNumber,
    this.rawText = '',
  });

  /// The strength as the wizard's dosage step would phrase it ("5 mg"), or null
  /// when either half is missing — half a dose is worse than no dose.
  String? get dosageLabel {
    if (amount == null || unit == null) return null;
    return '$amount ${unit!.label}';
  }

  /// True when nothing usable came back, so the caller can offer a retake instead
  /// of dropping the person into an empty "confirm" form.
  bool get isEmpty => name == null && amount == null && directions == null;

  ScannedMedicationLabel copyWith({String? name, String? amount, DosageUnit? unit}) {
    return ScannedMedicationLabel(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      form: form,
      directions: directions,
      quantity: quantity,
      rxNumber: rxNumber,
      rawText: rawText,
    );
  }
}

/// Reads the printed text off a dispensed medication label.
///
/// Note what this deliberately does NOT do: read the barcode. The barcode on a
/// bottle handed to a patient is the pharmacy's own fill number (Code 128), which
/// identifies the prescription inside that one pharmacy's system and carries no
/// drug identity at all. The DIN/NDC barcode lives on the manufacturer's stock
/// bottle, which the patient never sees. Everything actually worth capturing —
/// drug, strength, form, directions — is printed as plain text right next to it,
/// and reading it needs no lookup table and no network, which is the only version
/// of this feature that fits an on-device app.
class MedicationLabelScanner {
  final TextRecognizer _recognizer = TextRecognizer();

  /// OCRs a still photo of a label. A still is used rather than a live camera
  /// stream on purpose: label print is small and often curved around the bottle,
  /// and a full-resolution capture reads far more reliably than a downscaled
  /// preview frame.
  Future<ScannedMedicationLabel?> scanImageFile(String filePath) async {
    if (!await File(filePath).exists()) {
      debugPrint('MedicationLabelScanner: no file at $filePath');
      return null;
    }

    try {
      final RecognizedText recognized = await _recognizer.processImage(InputImage.fromFilePath(filePath));
      if (recognized.text.trim().isEmpty) {
        debugPrint('MedicationLabelScanner: image read, but no legible text.');
        return null;
      }
      return parseLabelText(recognized.text);
    } catch (error) {
      debugPrint('MedicationLabelScanner: OCR failed: $error');
      return null;
    }
  }

  void dispose() => _recognizer.close();

  // --- Parsing -------------------------------------------------------------
  // Split out as a pure function over a string so it can be exercised in tests
  // against real label transcriptions without a camera anywhere in the picture.

  /// Strength as printed: a number, then a unit, with optional space between.
  /// Matched case-insensitively because labels are inconsistent about MG vs mg.
  static final RegExp _strengthPattern = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(mcg|ug|mg|g|ml|l|units?|iu)\b',
    caseSensitive: false,
  );

  /// The sig usually opens with an imperative verb. Anchored to the start of the
  /// line so a stray "use" mid-sentence elsewhere doesn't hijack it.
  static final RegExp _directionsPattern = RegExp(
    r'^(take|takes|apply|instill|inhale|inject|use|place|insert|chew|dissolve|swallow|give)\b',
    caseSensitive: false,
  );

  static final RegExp _quantityPattern = RegExp(r'\b(?:qty|quantity)\.?:?\s*(\d+)\b', caseSensitive: false);
  static final RegExp _rxNumberPattern = RegExp(r'\brx\s*#?\.?:?\s*(\d{4,})\b', caseSensitive: false);

  /// Words that appear on every label but are never part of the drug name. Used
  /// to strip a name line down and to reject lines outright.
  static const List<String> _noiseWords = [
    'pharmacy', 'pharmacist', 'drug mart', 'drugmart', 'refill', 'refills',
    'discard', 'expires', 'exp', 'dispensed', 'prescriber', 'dr.', 'doctor',
    'phone', 'tel', 'caution', 'keep out of reach', 'federal law', 'no refills',
    'date filled', 'filled', 'store', 'manufacturer', 'mfg', 'lot',
    // Chains whose name is the largest text on the bottle, and the generic words
    // that mark a line as a business rather than a drug. These only ever matter for
    // a line sitting directly beside the strength — the name is never searched for
    // further afield than that — but that line can still be a logo or a footer.
    'shoppers', 'walmart', 'costco', 'safeway', 'save-on', 'save on',
    'london drugs', 'rexall', 'walgreens', 'cvs', 'rite aid', 'loblaw',
    'superstore', 'sobeys', 'jean coutu', 'uniprix', 'familiprix',
    'inc', 'ltd', 'llc', 'corp', 'co.', 'clinic', 'hospital', 'medical centre',
    'medical center', 'ave', 'avenue', 'street', ' st ', ' rd ', 'road', 'blvd',
    'suite', 'unit', 'www', 'http', '.com', '.ca',
  ];

  /// Form words, longest-first so "transdermal patch" wins over "patch".
  static const Map<String, MedicationTypes> _formWords = {
    'transdermal patch': MedicationTypes.transdermalPatch,
    'nebulizer': MedicationTypes.nebulizer,
    'suppository': MedicationTypes.suppository,
    'intravenous': MedicationTypes.iv,
    'injection': MedicationTypes.injection,
    'inhaler': MedicationTypes.inhaler,
    'ointment': MedicationTypes.ointment,
    'solution': MedicationTypes.liquid,
    'suspension': MedicationTypes.liquid,
    'capsule': MedicationTypes.capsule,
    'topical': MedicationTypes.topical,
    'patch': MedicationTypes.transdermalPatch,
    'tablet': MedicationTypes.tablet,
    'liquid': MedicationTypes.liquid,
    'syrup': MedicationTypes.liquid,
    'spray': MedicationTypes.spray,
    'drops': MedicationTypes.drops,
    'cream': MedicationTypes.topical,
    'gel': MedicationTypes.gel,
    'tab': MedicationTypes.tablet,
    'cap': MedicationTypes.capsule,
  };

  static ScannedMedicationLabel parseLabelText(String rawText) {
    final List<String> lines = rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    String? amount;
    DosageUnit? unit;
    String? name;
    String? directions;

    // Find the strength, and take the name from the text around it.
    //
    // The name is ALWAYS anchored to the strength — same line, or the line directly
    // above or below it. It is never searched for across the whole label. An earlier
    // version did exactly that as a fallback, and since the biggest, cleanest text on
    // a dispensed bottle is the pharmacy's own name across the top, it confidently
    // reported "Shoppers Drug Mart" as the medication. A search that ranges over the
    // whole label always finds something, and whatever it finds it presents as fact.
    // No strength found means no confident name: leave it null and let the review
    // screen ask. A blank field costs one typed word; a wrong one goes into a
    // medication record.
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      if (_looksLikeNoise(line)) continue;
      final RegExpMatch? match = _strengthPattern.firstMatch(line);
      if (match == null) continue;

      // A sig line carries a dose too ("TAKE 1 TABLET"), but that's how much to
      // take, not the strength of the pill. Skip it here; it's read separately.
      if (_directionsPattern.hasMatch(line)) continue;

      amount = match.group(1)!.replaceAll(',', '.');
      unit = _unitFor(match.group(2)!);

      // Same line first ("AMLODIPINE 5 MG TABLET"), then the line above and the line
      // below, which is how labels that stack the name over the strength read.
      name = _cleanNameCandidate(line.substring(0, match.start));
      name ??= _adjacentName(lines, i - 1);
      name ??= _adjacentName(lines, i + 1);
      break;
    }

    // Pass 3: the sig.
    for (final String line in lines) {
      if (_directionsPattern.hasMatch(line)) {
        directions = line;
        break;
      }
    }

    final String haystack = rawText.toLowerCase();
    return ScannedMedicationLabel(
      name: name,
      amount: amount,
      unit: unit,
      form: _formFor(haystack),
      directions: directions,
      quantity: _quantityPattern.firstMatch(rawText)?.group(1),
      rxNumber: _rxNumberPattern.firstMatch(rawText)?.group(1),
      rawText: rawText,
    );
  }

  static bool _looksLikeNoise(String line) {
    final String lower = line.toLowerCase();
    return _noiseWords.any(lower.contains);
  }

  /// Strips a name candidate down to the drug itself, or returns null when what's
  /// left isn't plausibly one.
  static String? _cleanNameCandidate(String candidate) {
    String cleaned = candidate;

    // A brand name often precedes the generic in parentheses — "NORVASC
    // (AMLODIPINE)". The generic is the more useful of the two to record.
    final RegExpMatch? parenthesised = RegExp(r'\(([A-Za-z][A-Za-z \-]{2,})\)').firstMatch(cleaned);
    if (parenthesised != null) {
      cleaned = parenthesised.group(1)!;
    }

    cleaned = cleaned.replaceAll(RegExp(r'[^A-Za-z \-/]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    // Drop a leading form word ("TABLET AMLODIPINE") and anything too short to be
    // a drug name once the noise is gone.
    for (final String formWord in _formWords.keys) {
      final RegExp leading = RegExp('^$formWord\\b', caseSensitive: false);
      if (leading.hasMatch(cleaned)) {
        cleaned = cleaned.replaceFirst(leading, '').trim();
      }
    }

    if (cleaned.length < 3) return null;
    return _titleCase(cleaned);
  }

  /// The line at [index], if it exists and reads like a drug name rather than a
  /// person, an address or a pharmacy banner. Deliberately checks ONE line — this is
  /// a neighbour check, not a search.
  static String? _adjacentName(List<String> lines, int index) {
    if (index < 0 || index >= lines.length) return null;
    final String line = lines[index];

    if (_looksLikeNoise(line)) return null;
    if (line.contains(',')) return null; // "DALLEY, RICHARD" — the patient, not the drug
    if (RegExp(r'\d').hasMatch(line)) return null; // dates, phone numbers, store numbers
    if (line.length < 4 || line.length > 40) return null;
    return _cleanNameCandidate(line);
  }

  static MedicationTypes? _formFor(String lowercaseText) {
    for (final MapEntry<String, MedicationTypes> entry in _formWords.entries) {
      if (lowercaseText.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static DosageUnit? _unitFor(String rawUnit) {
    switch (rawUnit.toLowerCase()) {
      case 'mg':
        return DosageUnit.mg;
      case 'mcg':
      case 'ug':
        return DosageUnit.mcg;
      case 'ml':
        return DosageUnit.mL;
      case 'unit':
      case 'units':
      case 'iu':
        return DosageUnit.units;
      // Grams and litres have no entry in DosageUnit. Rather than silently
      // mislabel a gram as a milligram, leave the unit unset so the review screen
      // asks for it.
      default:
        return null;
    }
  }

  static String _titleCase(String input) {
    return input
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
