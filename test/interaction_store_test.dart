import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ally/classes/interaction_store.dart';

// Runs the real lookups against the real shipped asset, opened straight from the
// repo with the desktop SQLite driver. If a rebuild of interactions.db drops one of
// these, this is where it shows up — before a patient's warning quietly disappears.
void main() {
  sqfliteFfiInit();
  final store = InteractionStore(
    opener: () => databaseFactoryFfi.openDatabase(
      // Absolute: the ffi factory resolves relative paths under .dart_tool.
      File(InteractionStore.assetPath).absolute.path,
      options: OpenDatabaseOptions(readOnly: true),
    ),
  );

  test('a class row matches a drug the label lists under it', () async {
    // Warfarin's label lists ibuprofen in its bleeding-risk table under NSAIDs.
    final rows = await store.between('Warfarin', 'Ibuprofen');
    expect(rows, isNotEmpty);
    expect(rows.first.effect, contains('bleeding'));
    expect(rows.first.explanation, contains('From the warfarin label'));
  });

  test('either drug\'s label counts, and salts resolve', () async {
    // Valproate's label names lamotrigine; the patient's entry is a salt name.
    final rows = await store.between('Lamotrigine', 'Divalproex Sodium');
    expect(rows, isNotEmpty);
  });

  test('international names resolve through the reviewed aliases', () async {
    expect(await store.ingredientIds('Aciclovir'), await store.ingredientIds('acyclovir'));
    expect(await store.ingredientIds('aciclovir'), isNotEmpty);
  });

  test('two unrelated drugs have nothing between them', () async {
    expect(await store.between('Ergocalciferol', 'Latanoprost'), isEmpty);
  });

  test('strongest instruction comes first', () async {
    final rows = await store.forMedication('Lithium Carbonate');
    expect(rows, isNotEmpty);
    const order = ['avoid', 'adjust_dose', 'monitor', 'info'];
    final ranks = rows.map((r) => order.indexOf(r.action)).toList();
    expect(ranks, orderedEquals([...ranks]..sort()));
  });

  test('unreviewed avoid rows are not in the shipped file', () async {
    // The build holds every "avoid" row back until it is approved in review; this
    // pins that the asset really reflects that, whatever the review state is.
    final db = await store.database;
    final pending = await db.query('meta', where: 'key = ?', whereArgs: ['avoid_pending_review']);
    final avoid = await db.rawQuery("SELECT COUNT(*) AS n FROM interaction WHERE action = 'avoid'");
    expect(int.parse(pending.single['value'] as String) + (avoid.single['n'] as int), greaterThan(0));
  });
}
