import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Drug-drug interactions from US FDA labels, built by the medications pipeline
/// (~/Code/medications) and shipped as a read-only SQLite asset. Every row quotes the
/// label it came from; "avoid" rows ship only after a person has reviewed them.
///
/// Kept apart from ally.db on purpose: a new build of the data is a new asset in the
/// next app version, with no schemaVersion bump and no onUpgrade anywhere near the
/// patient's own records.
class InteractionStore {
  InteractionStore({Future<Database> Function()? opener}) : _opener = opener ?? _openBundled;

  static final InteractionStore instance = InteractionStore();

  static const String assetPath = 'assets/medications/interactions.db';
  static const String versionAssetPath = 'assets/medications/interactions.version';

  final Future<Database> Function() _opener;
  Future<Database>? _db;
  Future<Database> get database => _db ??= _opener();

  // sqflite can't open a database inside the asset bundle, so the bundled file is
  // copied out — on first launch, and again whenever the app ships a different build
  // (the .version file carries the pipeline's build id). Written to a temporary name
  // and renamed, so an interrupted copy never leaves a truncated database in place.
  static Future<Database> _openBundled() async {
    final String dir = await getDatabasesPath();
    final String path = join(dir, 'interactions.db');
    final File versionFile = File(join(dir, 'interactions.version'));
    final String bundled = (await rootBundle.loadString(versionAssetPath)).trim();
    String? installed;
    try {
      installed = (await versionFile.readAsString()).trim();
    } on FileSystemException {
      installed = null;
    }
    if (installed != bundled || !await File(path).exists()) {
      final ByteData data = await rootBundle.load(assetPath);
      final File tmp = File('$path.tmp');
      await tmp.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
      await tmp.rename(path);
      await versionFile.writeAsString(bundled, flush: true);
    }
    return openDatabase(path, readOnly: true);
  }

  static String _norm(String name) => name.trim().toLowerCase();

  /// RxNorm ingredient ids a medication name resolves to — generic names, salts
  /// ("warfarin sodium"), the FDA's own substance names and Ally's reviewed
  /// international names ("aciclovir") all resolve.
  Future<List<String>> ingredientIds(String name) async {
    final Database db = await database;
    final rows = await db.query('ingredient_name', columns: ['rxcui'], where: 'name = ?', whereArgs: [_norm(name)]);
    return rows.map((r) => r['rxcui'] as String).toList();
  }

  /// Interactions between two medications, from either one's label, strongest first.
  Future<List<InteractionRow>> between(String medicationA, String medicationB) async {
    final Database db = await database;
    final List<String> a = await ingredientIds(medicationA);
    final List<String> b = await ingredientIds(medicationB);
    final List<InteractionRow> rows = [
      ...await _fromLabelOf(db, a, b, _norm(medicationB)),
      ...await _fromLabelOf(db, b, a, _norm(medicationA)),
    ];
    rows.sort(InteractionRow.strongestFirst);
    return rows;
  }

  /// Everything a medication's own label says about other drugs, strongest first.
  Future<List<InteractionRow>> forMedication(String medication) async {
    final Database db = await database;
    final List<String> ids = await ingredientIds(medication);
    if (ids.isEmpty) return [];
    final rows = await db.rawQuery('''
      SELECT i.action, s.name AS subject, i.interactant, i.effect, i.quote, l.title
      FROM interaction i
      JOIN ingredient s ON s.rxcui = i.subject_rxcui
      JOIN label l ON l.set_id = i.set_id
      WHERE i.subject_rxcui IN (${_marks(ids.length)})
      ORDER BY i.interactant''', ids);
    final List<InteractionRow> out = rows.map(InteractionRow.fromRow).toList();
    out.sort(InteractionRow.strongestFirst);
    return out;
  }

  // Rows from the subject drug's label that name the other drug — as the interactant
  // or as a listed member of a class ("NSAIDs: ibuprofen, naproxen, …") — matched on
  // ingredient id where RxNorm knows the name, on the name itself otherwise.
  Future<List<InteractionRow>> _fromLabelOf(Database db, List<String> subject, List<String> other, String otherName) async {
    if (subject.isEmpty) return [];
    final String match = other.isEmpty ? 't.term = ?' : '(t.rxcui IN (${_marks(other.length)}) OR t.term = ?)';
    final rows = await db.rawQuery('''
      SELECT DISTINCT i.id, i.action, s.name AS subject, i.interactant, i.effect, i.quote, l.title
      FROM interaction i
      JOIN interaction_term t ON t.interaction_id = i.id
      JOIN ingredient s ON s.rxcui = i.subject_rxcui
      JOIN label l ON l.set_id = i.set_id
      WHERE i.subject_rxcui IN (${_marks(subject.length)}) AND $match''', [...subject, ...other, otherName]);
    return rows.map(InteractionRow.fromRow).toList();
  }

  static String _marks(int n) => List.filled(n, '?').join(', ');
}

/// One interaction as the label states it.
class InteractionRow {
  const InteractionRow({
    required this.action,
    required this.subject,
    required this.interactant,
    required this.effect,
    required this.quote,
    required this.labelTitle,
  });

  factory InteractionRow.fromRow(Map<String, Object?> r) => InteractionRow(
    action: r['action'] as String,
    subject: r['subject'] as String,
    interactant: r['interactant'] as String,
    effect: r['effect'] as String,
    quote: r['quote'] as String,
    labelTitle: r['title'] as String,
  );

  /// avoid, adjust_dose, monitor or info — the label's own instruction.
  final String action;
  final String subject;
  final String interactant;
  final String effect;
  final String quote;
  final String labelTitle;

  static const List<String> _order = ['avoid', 'adjust_dose', 'monitor', 'info'];

  static int strongestFirst(InteractionRow a, InteractionRow b) =>
      _order.indexOf(a.action).compareTo(_order.indexOf(b.action));

  /// What the label asks for, in plain words.
  String get instruction => switch (action) {
    'avoid' => 'The label says not to combine these',
    'adjust_dose' => 'The label says a dose may need adjusting',
    'monitor' => 'The label says to monitor when combined',
    _ => 'The label notes an effect',
  };

  /// A self-contained description: the instruction, the effect, and the label's
  /// own words, so a patient or pharmacist can see exactly what it's based on.
  String get explanation {
    final String what = effect.isEmpty ? '$instruction.' : '$instruction: $effect.';
    return '$what\n\nFrom the $subject label ($labelTitle): "$quote"';
  }
}
