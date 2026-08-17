import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:triage/classes/allergen.dart';
import 'package:triage/classes/blood_type.dart';
import 'package:triage/classes/patient_condition.dart';
import 'package:triage/classes/patient_supply.dart';
import 'package:triage/classes/provider.dart';
import 'package:triage/classes/questionnaire.dart';
import 'package:triage/classes/vision_prescription.dart';
import 'package:uuid/uuid.dart';
import 'acuity.dart';
import 'data_seeder.dart';
import 'medication_services.dart';
import 'metric_value.dart';

bool overWrite = false;

class DatabaseManager {
  // Singleton pattern
  static final DatabaseManager _instance = DatabaseManager._internal();

  Database? _db;
  static const uuid = Uuid();

  // The Gatekeeper: This prevents multiple calls to init()
  Completer<Database>? _dbCompleter;

  // Cache the SQL configuration in memory
  Map<String, dynamic>? sqlConfig;

  // DatabaseManager._internal();
  DatabaseManager._internal();

  factory DatabaseManager() => _instance;

  Future<Database> get database async {
    // Double-checked locking
    if (_db != null && _db!.isOpen) return _db!;

    // Return existing future if in progress
    if (_dbCompleter != null) return _dbCompleter!.future;

    // Create the completer immediately
    _dbCompleter = Completer<Database>();

    try {
      // Perform the init
      final db = await _init(overwrite: overWrite);

      // CRITICAL: Assign _db BEFORE completing the future
      _db = db;
      _dbCompleter!.complete(db);

      return db;
    } catch (e) {
      _dbCompleter = null;
      rethrow;
    }
  }

  Future<Database> _init({bool overwrite = true}) async {
    final String response = await rootBundle.loadString('assets/sql/sql.json');
    sqlConfig = json.decode(response);

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'triage_data.db');

    if (overwrite) {
      await deleteDatabase(path);
    }

    // CRITICAL: You must await this call.
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 4. Ensure Foreign Keys are enabled for the session
        await db.execute('PRAGMA foreign_keys = ON;');
        await createSqlObjects(db);
        await DataSeeder.seed(db);
      },
    );
    return db;
  }

  Future<void> createSqlObjects(Database db) async {
    if (sqlConfig == null) return;
    // 2. Extract the CREATE array
    final List<dynamic> createScripts = sqlConfig?['CREATE'];

    // 3. Execute each query in the order provided in the JSON
    for (var entry in createScripts) {
      final String query = entry['query'];
      debugPrint(entry['table']);
      if (query.isNotEmpty) {
        await db.execute(query);
      }
    }
  }

  Future<void> updateAboType(String patientUuid, int aboType) async {
    final db = await database;
    await db.update('patient', {'abo_type': aboType}, where: 'patient_uuid = ?', whereArgs: [patientUuid]);
  }

  Future<void> updateRhFactor(String patientUuid, int rhFactor) async {
    final db = await database;
    await db.update('patient', {'rh_factor': rhFactor}, where: 'patient_uuid = ?', whereArgs: [patientUuid]);
  }

  // Stored as a BLOB directly on the patient row, same convention AvatarPicker already
  // established for provider photos (see provider.dart's `image` field / `avatar`
  // column) — not a file path, so there's nothing to keep in sync with the filesystem.
  Future<void> updatePatientAvatar(String patientUuid, Uint8List? avatar) async {
    final db = await database;
    await db.update('patient', {'avatar': avatar}, where: 'patient_uuid = ?', whereArgs: [patientUuid]);
  }

  // The handful of clerical fields UserScreen only ever displayed until now — PHN,
  // emergency contact, primary caregiver, pharmacy. phn is UNIQUE, so a collision with
  // another patient's card number throws; callers should catch and surface that rather
  // than let it look like a generic save failure.
  Future<void> updatePatientDetails({
    required String patientUuid,
    required String phn,
    required String contactName,
    required String contactPhone,
    required String familyDoctorName,
    required String familyDoctorPhone,
    required String pharmacyPhone,
    required String pharmacyFax,
  }) async {
    final db = await database;
    await db.update(
      'patient',
      {
        'phn': phn,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'family_doctor_name': familyDoctorName,
        'family_doctor_phone': familyDoctorPhone,
        'pharmacy_phone': pharmacyPhone,
        'pharmacy_fax': pharmacyFax,
      },
      where: 'patient_uuid = ?',
      whereArgs: [patientUuid],
    );
  }

  Future<bool> trackMoodChange(String patientUuid, int mood) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. Get the latest mood
      final List<Map<String, dynamic>> latest = await txn.query(
        'patient_mood',
        where: 'patient_uuid = ?',
        whereArgs: [patientUuid],
        orderBy: 'start_date DESC',
        limit: 1,
      );

      final now = DateTime.now().toUtc().toIso8601String();

      if (latest.isNotEmpty) {
        final lastMood = latest.first;
        final lastMoodValue = lastMood['mood'] as int;

        // 2. If it's different, close the old one
        if (lastMoodValue != mood) {
          await txn.update('patient_mood', {'end_date': now}, where: 'id = ?', whereArgs: [lastMood['id']]);

          // 3. Insert the new one
          await txn.insert('patient_mood', {
            'patient_uuid': patientUuid,
            'mood': mood,
            'start_date': now,
            'end_date': null, // Open-ended
          });
        }
        // Else: mood is the same, do nothing (as you requested)
      } else {
        // 4. First time ever logging? Just insert.
        await txn.insert('patient_mood', {'patient_uuid': patientUuid, 'mood': mood, 'start_date': now});
      }
    });
    return true;
  }

  // The current (still-open) mood period, if one exists — null only means this
  // patient has never logged a mood at all yet.
  Future<Map<String, dynamic>?> getCurrentMood(String patientUuid) async {
    final db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      'patient_mood',
      where: 'patient_uuid = ?',
      whereArgs: [patientUuid],
      orderBy: 'start_date DESC',
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  // Attaches a reason to whichever mood period is currently open — not necessarily
  // tied to the moment the mood last changed, since a long-press to explain "why" can
  // happen any time during that period.
  Future<void> setMoodReason(String patientUuid, String reason) async {
    final current = await getCurrentMood(patientUuid);
    if (current == null) return;
    final db = await database;
    await db.update('patient_mood', {'reason': reason}, where: 'id = ?', whereArgs: [current['id']]);
  }

  Future<List<Map<String, dynamic>>> getPatientVaccinations(String patientUuid) async {
    final db = await database;
    dynamic result = await db.query(
      'patient_vaccination',
      where: 'patient_uuid = ?',
      whereArgs: [patientUuid],
      orderBy: 'received DESC', // You can adjust this to your custom sorting logic
    );
    return result;
  }

  Future<int> insertVaccination(
    String patientUuid,
    String name,
    String protection,
    DateTime? received, {
    DateTime? nextDue,
  }) async {
    final db = await database;
    return await db.insert('patient_vaccination', {
      'patient_uuid': patientUuid,
      'name': name,
      'protection': protection,
      'received': received?.toIso8601String(), // Store as ISO string for SQLite
      'next_due': nextDue?.toIso8601String(),
    });
  }

  // Vaccinations with a next-due date set. next_due is auto-computed from the schedule's
  // interval_between_shots when a dose is recorded (see ImmunizationScreen.onTookVaccineHandler /
  // Vaccine.expirationDate) — but TODO(data): that interval field is currently placeholder data
  // (uniformly 1 year for every vaccine in immunizations.json, not clinically reviewed), so due
  // dates surfaced here may be wrong until that data is corrected.
  Future<List<Map<String, dynamic>>> getVaccinationsWithReminders(String patientUuid) async {
    final db = await database;
    return await db.query(
      'patient_vaccination',
      where: 'patient_uuid = ? AND next_due IS NOT NULL',
      whereArgs: [patientUuid],
    );
  }

  // Clears next_due (stops reminding) and records the actual received date — "Done"
  // on an immunization reminder.
  Future<void> markVaccinationReceived(int vaccinationId, DateTime receivedOn) async {
    final db = await database;
    await db.update(
      'patient_vaccination',
      {'received': receivedOn.toIso8601String(), 'next_due': null},
      where: 'id = ?',
      whereArgs: [vaccinationId],
    );
  }

  Future<void> rescheduleVaccinationReminder(int vaccinationId, DateTime newDueDate) async {
    final db = await database;
    await db.update(
      'patient_vaccination',
      {'next_due': newDueDate.toIso8601String()},
      where: 'id = ?',
      whereArgs: [vaccinationId],
    );
  }

  Future<int> deleteVaccination(String vaccinationName, String patientUuid) async {
    final db = await database;
    return await db.delete(
      'patient_vaccination',
      where: 'name = ? and patient_uuid = ?',
      whereArgs: [vaccinationName, patientUuid],
    );
  }

  // Tests
  Future<List<Map<String, dynamic>>> getTestCatalog() async {
    final db = await database;
    return await db.query('test_catalog', orderBy: 'category, name');
  }

  Future<List<Map<String, dynamic>>> getPatientTests(String patientUuid) async {
    final db = await database;
    return await db.query('patient_test', where: 'patient_uuid = ?', whereArgs: [patientUuid], orderBy: 'name');
  }

  Future<int> addPatientTest(String patientUuid, Map<String, dynamic> row) async {
    final db = await database;
    final Map<String, dynamic> withPatient = Map<String, dynamic>.from(row)..['patient_uuid'] = patientUuid;
    return await db.insert('patient_test', withPatient);
  }

  // Tests with a next-due date set — same "explicitly set, not derived from a
  // clinical schedule" honesty as getVaccinationsWithReminders; this catalog has no
  // recommended-frequency data to compute one from.
  Future<List<Map<String, dynamic>>> getTestsWithReminders(String patientUuid) async {
    final db = await database;
    return await db.query('patient_test', where: 'patient_uuid = ? AND next_due IS NOT NULL', whereArgs: [patientUuid]);
  }

  // Clears next_due (stops reminding) and records the actual done date — "Done" on a
  // test reminder.
  Future<void> markTestDone(int testId, DateTime doneOn) async {
    final db = await database;
    await db.update(
      'patient_test',
      {'last_done': doneOn.toIso8601String(), 'next_due': null},
      where: 'id = ?',
      whereArgs: [testId],
    );

    // Recurring tests (rheumatology's quarterly bloodwork, for instance) need every
    // occurrence on record, not just "when was it most recently done" — patient_test
    // only ever holds the latest date, so this is the only place a full history exists.
    final List<Map<String, dynamic>> rows = await db.query(
      'patient_test',
      columns: ['patient_uuid', 'name', 'category'],
      where: 'id = ?',
      whereArgs: [testId],
    );
    if (rows.isEmpty) return;
    await db.insert('test_completion_log', {
      'id': uuid.v4(),
      'patient_uuid': rows.first['patient_uuid'],
      'name': rows.first['name'],
      'category': rows.first['category'],
      'completed_on': doneOn.toIso8601String(),
    });
  }

  Future<void> rescheduleTestReminder(int testId, DateTime newDueDate) async {
    final db = await database;
    await db.update('patient_test', {'next_due': newDueDate.toIso8601String()}, where: 'id = ?', whereArgs: [testId]);
  }

  Future<void> deletePatientTest(int testId) async {
    final db = await database;
    await db.delete('patient_test', where: 'id = ?', whereArgs: [testId]);
  }

  // Supplies — consumables only (needles, swabs, test strips, catheters), never
  // durable equipment. See patient_supply.dart for the full reasoning.

  Future<List<Map<String, dynamic>>> getSupplyCatalog() async {
    final db = await database;
    return await db.query('supply', orderBy: 'category, name');
  }

  // Supplies typically used for whatever conditions this patient has actually logged
  // (via condition_supply), minus anything they're already tracking — so a diabetes
  // diagnosis can surface "test strips, lancets" as one-tap suggestions instead of
  // making the patient dig through the full catalog.
  Future<List<Map<String, dynamic>>> getSuggestedSupplies(String patientUuid) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT DISTINCT s.id, s.name, s.category
      FROM supply s
      JOIN condition_supply cs ON cs.supply_id = s.id
      JOIN patient_condition pc ON pc.condition_id = cs.condition_id
      WHERE pc.patient_uuid = ?
        AND s.name NOT IN (SELECT name FROM patient_supply WHERE patient_uuid = ?)
      ORDER BY s.category, s.name
      ''',
      [patientUuid, patientUuid],
    );
  }

  Future<List<Map<String, dynamic>>> getPatientSupplies(String patientUuid) async {
    final db = await database;
    return await db.query('patient_supply', where: 'patient_uuid = ?', whereArgs: [patientUuid], orderBy: 'name');
  }

  Future<int> insertPatientSupply(String patientUuid, PatientSupply record) async {
    final db = await database;
    final Map<String, dynamic> row = Map<String, dynamic>.from(record.toRow())..['patient_uuid'] = patientUuid;
    return await db.insert('patient_supply', row);
  }

  Future<void> updatePatientSupply(PatientSupply record) async {
    final db = await database;
    await db.update('patient_supply', record.toRow(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<void> deletePatientSupply(int id) async {
    final db = await database;
    await db.delete('patient_supply', where: 'id = ?', whereArgs: [id]);
  }

  // "Don't remind me again" on a low-supply reminder — zeroes the threshold rather than
  // deleting the row, so it still tracks quantity, just only alerts once truly at zero.
  Future<void> updateSupplyThreshold(int id, int threshold) async {
    final db = await database;
    await db.update('patient_supply', {'reorder_threshold': threshold}, where: 'id = ?', whereArgs: [id]);
  }

  // Due for a reorder right now — not a forecast, a plain threshold check. See
  // SupplyReminder in remindable.dart for why no predicted "runs out on" date exists.
  Future<List<Map<String, dynamic>>> getLowSupplies(String patientUuid) async {
    final db = await database;
    return await db.rawQuery(
      'SELECT * FROM patient_supply WHERE patient_uuid = ? AND quantity_on_hand <= reorder_threshold',
      [patientUuid],
    );
  }

  // Eye Care — vision prescriptions are a static credential (sphere/cylinder/axis/PD),
  // not a tracked/dosed thing, deliberately kept out of the medication wizard. See
  // vision_prescription.dart for the full reasoning.

  Future<List<Map<String, dynamic>>> getVisionPrescriptionsForPatient(String patientUuid) async {
    final db = await database;
    return await db.query(
      'vision_prescription',
      where: 'patient_uuid = ?',
      whereArgs: [patientUuid],
      orderBy: 'issued_date DESC',
    );
  }

  Future<int> insertVisionPrescription(VisionPrescription record) async {
    final db = await database;
    return await db.insert('vision_prescription', record.toRow());
  }

  Future<void> updateVisionPrescription(VisionPrescription record) async {
    final db = await database;
    await db.update('vision_prescription', record.toRow(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<void> deleteVisionPrescription(int id) async {
    final db = await database;
    await db.delete('vision_prescription', where: 'id = ?', whereArgs: [id]);
  }

  // Patient Diary
  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<Map<String, dynamic>?> getDiaryEntry(String patientUuid, DateTime date) async {
    final db = await database;
    final rows = await db.query(
      'patient_diary_entry',
      where: 'patient_uuid = ? AND entry_date = ?',
      whereArgs: [patientUuid, _dateOnly(date)],
    );
    return rows.isEmpty ? null : rows.first;
  }

  // Upsert keyed on the (patient_uuid, entry_date) unique constraint — one entry per
  // patient per day, matching the "no entry for a day you didn't write in" rule.
  Future<void> saveDiaryEntry(String patientUuid, DateTime date, String content) async {
    final db = await database;
    final String now = DateTime.now().toIso8601String();
    final existing = await getDiaryEntry(patientUuid, date);
    if (existing != null) {
      await db.update(
        'patient_diary_entry',
        {'content': content, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [existing['id']],
      );
    } else {
      await db.insert('patient_diary_entry', {
        'patient_uuid': patientUuid,
        'entry_date': _dateOnly(date),
        'content': content,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  // Clearing an entry back to empty removes the row outright rather than leaving a
  // blank one behind — a day with no text is a day with no entry, full stop.
  Future<void> deleteDiaryEntry(String patientUuid, DateTime date) async {
    final db = await database;
    await db.delete(
      'patient_diary_entry',
      where: 'patient_uuid = ? AND entry_date = ?',
      whereArgs: [patientUuid, _dateOnly(date)],
    );
  }

  Future<Set<String>> getDiaryEntryDatesForMonth(String patientUuid, int year, int month) async {
    final db = await database;
    final String prefix = '$year-${month.toString().padLeft(2, '0')}';
    final rows = await db.query(
      'patient_diary_entry',
      columns: ['entry_date'],
      where: "patient_uuid = ? AND entry_date LIKE ?",
      whereArgs: [patientUuid, '$prefix%'],
    );
    return rows.map((r) => r['entry_date'] as String).toSet();
  }

  // Everything that happened on one specific day, across every event source the diary
  // pulls from — medication doses, appointments, symptoms, mood, and test completions.
  // Returned as raw rows per category (not a unified model) so DiaryDayEvent's factory
  // constructors stay the single place that knows how to render each shape.
  Future<Map<String, List<Map<String, dynamic>>>> getDayEvents(String patientUuid, DateTime date) async {
    final db = await database;
    final DateTime start = DateTime(date.year, date.month, date.day);
    final DateTime end = start.add(const Duration(days: 1));
    final String startIso = start.toIso8601String();
    final String endIso = end.toIso8601String();
    final int startEpoch = start.millisecondsSinceEpoch ~/ 1000;
    final int endEpoch = end.millisecondsSinceEpoch ~/ 1000;

    final doses = await db.rawQuery(
      '''
      SELECT d.*, m.name AS medication_name, m.dose AS dose
      FROM medication_dose_log d
      JOIN medication m ON m.id = d.medication_id
      WHERE d.patient_uuid = ? AND d.scheduled_for >= ? AND d.scheduled_for < ?
      ORDER BY d.scheduled_for
      ''',
      [patientUuid, startIso, endIso],
    );

    final appointments = await db.rawQuery(
      '''
      SELECT a.*, p.first_name || ' ' || p.last_name AS provider_name
      FROM appointment a
      LEFT JOIN provider p ON p.provider_uuid = a.provider_uuid
      WHERE a.patient_uuid = ? AND a.scheduled_for >= ? AND a.scheduled_for < ?
      ORDER BY a.scheduled_for
      ''',
      [patientUuid, startIso, endIso],
    );

    final symptoms = await db.query(
      'markers',
      where: 'patient_uuid = ? AND recorded >= ? AND recorded < ?',
      whereArgs: [patientUuid, startEpoch, endEpoch],
      orderBy: 'recorded',
    );

    // A mood *period* overlapping the day, not just one that started that day —
    // "what was my mood on this day" should answer correctly even if it didn't change.
    final moods = await db.query(
      'patient_mood',
      where: 'patient_uuid = ? AND start_date < ? AND (end_date IS NULL OR end_date >= ?)',
      whereArgs: [patientUuid, endIso, startIso],
      orderBy: 'start_date',
    );

    final tests = await db.query(
      'test_completion_log',
      where: 'patient_uuid = ? AND completed_on >= ? AND completed_on < ?',
      whereArgs: [patientUuid, startIso, endIso],
      orderBy: 'completed_on',
    );

    return {'doses': doses, 'appointments': appointments, 'symptoms': symptoms, 'moods': moods, 'tests': tests};
  }

  // Which dates in a month have at least one event, across all five sources — for the
  // month view's "something happened" marker, shown independent of whether a diary
  // entry was ever written for that day.
  Future<Set<String>> getEventDatesForMonth(String patientUuid, int year, int month) async {
    final db = await database;
    final DateTime monthStart = DateTime(year, month);
    final DateTime monthEnd = DateTime(year, month + 1);
    final String startIso = monthStart.toIso8601String();
    final String endIso = monthEnd.toIso8601String();
    final int startEpoch = monthStart.millisecondsSinceEpoch ~/ 1000;
    final int endEpoch = monthEnd.millisecondsSinceEpoch ~/ 1000;

    final Set<String> dates = {};

    void addDatesFromIso(List<Map<String, dynamic>> rows, String column) {
      for (final row in rows) {
        final DateTime? parsed = DateTime.tryParse(row[column] as String? ?? '');
        if (parsed != null) dates.add(_dateOnly(parsed));
      }
    }

    addDatesFromIso(
      await db.rawQuery(
        'SELECT scheduled_for FROM medication_dose_log WHERE patient_uuid = ? AND scheduled_for >= ? AND scheduled_for < ?',
        [patientUuid, startIso, endIso],
      ),
      'scheduled_for',
    );
    addDatesFromIso(
      await db.rawQuery(
        'SELECT scheduled_for FROM appointment WHERE patient_uuid = ? AND scheduled_for >= ? AND scheduled_for < ?',
        [patientUuid, startIso, endIso],
      ),
      'scheduled_for',
    );
    addDatesFromIso(
      await db.rawQuery(
        'SELECT completed_on FROM test_completion_log WHERE patient_uuid = ? AND completed_on >= ? AND completed_on < ?',
        [patientUuid, startIso, endIso],
      ),
      'completed_on',
    );

    final symptomRows = await db.rawQuery(
      'SELECT recorded FROM markers WHERE patient_uuid = ? AND recorded >= ? AND recorded < ?',
      [patientUuid, startEpoch, endEpoch],
    );
    for (final row in symptomRows) {
      dates.add(_dateOnly(DateTime.fromMillisecondsSinceEpoch((row['recorded'] as int) * 1000)));
    }

    // Only the day a mood actually *changed*, not every day of an ongoing period —
    // otherwise a single weeks-long calm streak would light up the entire month with
    // "something happened" markers for days nothing new occurred on. A period that
    // started in an earlier month but is still running isn't marked at all here; it
    // has no in-month change-day to point to.
    addDatesFromIso(
      await db.rawQuery(
        'SELECT start_date FROM patient_mood WHERE patient_uuid = ? AND start_date >= ? AND start_date < ?',
        [patientUuid, startIso, endIso],
      ),
      'start_date',
    );

    return dates;
  }

  // Drugs
  Future<String?> getInteractions(String drugNameA, String drugNameB) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'interaction',
      columns: ['explanation'],
      where: '(name_a = ? AND name_b = ?) OR (name_a = ? AND name_b = ?)',
      whereArgs: [drugNameA, drugNameB, drugNameB, drugNameA],
    );
    // Return the interaction description if found, otherwise the default message
    if (results.isNotEmpty) {
      String explanation = results.first['explanation'] as String;
      return explanation;
    } else {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllInteractionsForDrug(String drugName) async {
    final db = await database;

    // Query both columns to capture every interaction regardless of entry order
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
    SELECT 
      CASE 
        WHEN name_a = ? THEN name_b 
        ELSE name_a 
      END AS interacting_drug,
      explanation
    FROM interaction
    WHERE name_a = ? OR name_b = ?
  ''',
      [drugName, drugName, drugName],
    );

    return results;
  }

  // Returns the generated row id (BodyMarker.id) — needed later to mark a marker
  // resolved or record that we've checked in on it.
  Future<int> insertBodyMarker(String patientUuid, Map<String, dynamic> marker) async {
    final db = await database;
    Map<String, dynamic> row = Map<String, dynamic>.from(marker);
    row['patient_uuid'] = patientUuid;
    return await db.insert('markers', row);
  }

  // Edits an existing marker (tapped from the body map to update a symptom already
  // logged) rather than inserting a duplicate row — id must come from a previously
  // loaded BodyMarker, not a freshly-created one.
  Future<void> updateBodyMarker(int id, Map<String, dynamic> marker) async {
    final db = await database;
    await db.update('markers', marker, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertMarkersBatch(String tableName, List<Map<String, dynamic>> rows) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var row in rows) {
        await txn.insert(tableName, row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getMarkersForPatient(String patientUuid) async {
    final db = await database;

    // Fetch all markers for the patient, sorted by most recent first
    return await db.query('markers', where: 'patient_uuid = ?', whereArgs: [patientUuid], orderBy: 'recorded DESC');
  }

  // Markers due for an "is this still bothering you?" check-in: not yet resolved,
  // first recorded at least [minAge] ago, and (if we've asked before) not asked again
  // within [minAge] — spaces repeat check-ins out instead of asking every app open.
  Future<List<Map<String, dynamic>>> getMarkersDueForFollowUp(
    String patientUuid, {
    Duration minAge = const Duration(days: 3),
  }) async {
    final db = await database;
    final DateTime cutoff = DateTime.now().subtract(minAge);
    final int recordedCutoff = cutoff.millisecondsSinceEpoch ~/ 1000;

    return await db.query(
      'markers',
      where:
          'patient_uuid = ? AND resolved = 0 AND recorded <= ? '
          'AND (last_checked_at IS NULL OR last_checked_at <= ?)',
      whereArgs: [patientUuid, recordedCutoff, cutoff.toIso8601String()],
      orderBy: 'recorded ASC',
    );
  }

  // reason is optional since the days-later follow-up check-in's "It's Better" answer
  // (SymptomFollowUpDialog) doesn't collect one — only a deliberate dismissal via the
  // marker modal's X button does.
  Future<void> resolveBodyMarker(int markerId, {String? reason}) async {
    final db = await database;
    await db.update(
      'markers',
      {'resolved': 1, 'resolved_at': DateTime.now().toIso8601String(), 'dismissal_reason': reason},
      where: 'id = ?',
      whereArgs: [markerId],
    );
  }

  // "Created this by mistake" — an erroneous entry has no clinical meaning to keep
  // around resolved, unlike the other dismissal reasons.
  Future<void> deleteBodyMarker(int markerId) async {
    final db = await database;
    await db.delete('markers', where: 'id = ?', whereArgs: [markerId]);
  }

  Future<void> markBodyMarkerChecked(int markerId) async {
    final db = await database;
    await db.update(
      'markers',
      {'last_checked_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [markerId],
    );
  }

  // Inside your classes/database_manager.dart file
  Future<bool> updatePatientProcessStep({required String uuid, required int targetStepId}) async {
    try {
      // 1. Get a handle to your initialized database engine instance
      final db = await database;

      // 2. Execute a targeted update on the specific patient row matching the UUID
      final int rowsAffected = await db.update(
        'patient',
        {
          'phase_step_id': targetStepId,
          'last_update': DateTime.now().toIso8601String(), // Optional: if you track transaction records
        },
        where: 'patient_uuid = ?',
        whereArgs: [uuid],
      );

      // 3. Return true only if at least one record was successfully modified in the schema
      return rowsAffected > 0;
    } catch (e) {
      debugPrint("Database Engine Error: Failed to write step transition: $e");
      return false; // Safely fail without crashing the app thread
    }
  }

  // The New Patient Retrieval Function
  // The Clean Patient Retrieval Function
  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final db = await database;

    // Directly pull every row from the patient table
    return await db.query('patient');
  }

  Future<List<Map<String, dynamic>>> getAllPatientsWithVitals() async {
    final db = await database;
    return await db.query('patient');
  }

  // Retired the LEFT JOIN patient_metrics (2026-08-14) — that table and the vitals
  // subsystem built on it are gone; current-reading data now lives entirely in the
  // catalog-driven metric/patient_metric tables (see getPatientMetricRanges etc.).
  Future<List<Map<String, dynamic>>> getPatientWithVitals({required String patientUuid}) async {
    final db = await database;
    return await db.query('patient', where: 'patient_uuid = ?', whereArgs: [patientUuid]);
  }

  // Adding a new family member from the patient wheel's center "+" button — deliberately
  // minimal (first/last name, DOB), matching what a home-care patient actually needs to
  // start tracking someone, not the full ward-triage-era clerical intake form this
  // schema still carries columns for (government health card number, address, primary
  // caregiver, etc. — that's the separate "clerical screen needs love" task, not this
  // one). Every text column gets an explicit empty string rather than being left NULL:
  // Patient.fromJson reads most of them straight into non-nullable String fields with no
  // ?? fallback, so a NULL here wouldn't just look empty in the UI, it would throw and
  // take down patient loading entirely the next time the app started.
  Future<String> insertPatient({
    required String firstName,
    required String lastName,
    required DateTime dob,
    // All optional — FirstPatientWizard is the only caller (both the first-run flow and
    // the "add a family member" flow reuse it now), and every one of these is skippable
    // there. phn is UNIQUE, so an explicit blank string can't be used as "not
    // provided" (every skip would collide) — falling back to the generated uuid, same
    // as before, keeps that guarantee without a real card number.
    String? phn,
    AboType? abo,
    RhFactor? rh,
    String? streetAddress,
    String? city,
    String? province,
    String? postalCode,
    String? country,
    String? relation,
  }) async {
    final db = await database;
    final String newPatientUuid = uuid.v4();
    await db.insert('patient', {
      'patient_uuid': newPatientUuid,
      'first_name': firstName,
      'last_name': lastName,
      'acuity': 0,
      'phn': (phn == null || phn.isEmpty) ? newPatientUuid : phn,
      'phase_step_id': 0,
      'email': '',
      'ssn': '',
      'title': '',
      'country': country ?? '',
      'dob': dob.toIso8601String(),
      'status': '',
      'path': '',
      'street_address': streetAddress ?? '',
      'city': city ?? '',
      'province': province ?? '',
      'postal_code': postalCode ?? '',
      'phone': '',
      'contact_name': '',
      'relation': relation ?? '',
      'contact_phone': '',
      'family_doctor_name': '',
      'family_doctor_phone': '',
      'pharmacy_name': '',
      'pharmacy_phone': '',
      'pharmacy_fax': '',
      'narrative_hint': '',
      'abo_type': (abo ?? AboType.o).index,
      'rh_factor': (rh ?? RhFactor.positive).index,
    });
    return newPatientUuid;
  }

  Future<void> insertAcuity({
    required String patientUuid,
    required AcuityLevel acuityLevel,
    required String rationale,
    required String encounterId,
    required String setBu, // Assuming this is the 'set by user' identifier
  }) async {
    final db = await database;
    await updatePatientAcuity(patientUuid: patientUuid, newAcuityLevel: acuityLevel);

    // Use a UUID package to generate the primary key
    final String id = const Uuid().v4();

    try {
      await db.insert('acuity_log', {
        'id': id,
        'patient_uuid': patientUuid,
        'acuity_level': acuityLevel.index,
        'encounter_id': encounterId,
        'rationale': rationale,
        'set_bu': setBu,
        // 'set_at' is handled by DEFAULT CURRENT_TIMESTAMP in your SQL
      });
    } catch (e) {
      debugPrint("Error logging acuity change: $e");
      // Handle or rethrow based on your app's error policy
    }
  }

  Future<void> updatePatientAcuity({required String patientUuid, required AcuityLevel newAcuityLevel}) async {
    final db = await database; // Or your specific DB instance accessor

    try {
      await db.update(
        'patient', // Replace with your actual table name
        {'acuity': newAcuityLevel.index},
        where: 'patient_uuid = ?',
        whereArgs: [patientUuid],
      );
    } catch (e) {
      debugPrint("Error updating database: $e");
    }
  }

  // Inside your DatabaseManager class:
  Future<Map<String, List<ConditionReference>>> getConditionsCatalog() async {
    final db = await database;

    // Fetch all conditions ordered alphabetically by category and name
    final List<Map<String, dynamic>> maps = await db.query('condition', orderBy: 'category ASC, name ASC');

    // Reconstruct our grouped layout pattern dynamically
    final Map<String, List<ConditionReference>> catalog = {};

    for (final Map<String, dynamic> row in maps) {
      final reference = ConditionReference.fromMap(row);

      // Initialize the list for this category slot if it doesn't exist yet
      if (!catalog.containsKey(reference.category)) {
        catalog[reference.category] = [];
      }

      catalog[reference.category]!.add(reference);
    }

    return catalog;
  }

  Future<void> insertPatientMetric(String patientUuid, double value, String metricType) async {
    final db = await database;
    final sanitizedType = metricType.toLowerCase().trim();
    final String metricEventUuid = const Uuid().v4();
    final int readingId = await getNextReadingId(db, patientUuid);
    // Execute the database write.
    // Note: This insert will instantly trigger your SQLite triggers on the backend
    // to update the flat fast-cache on the patients table automatically
    await db.execute(
      '''
    INSERT INTO patient_metrics (
      id, 
      patient_uuid, 
      reading_id,
      metric_type, 
      metric_value
    ) VALUES (?, ?, ?, ?, ?)
  ''',
      [metricEventUuid, patientUuid, readingId, sanitizedType, value],
    );
  }

  // If you are using the standard 'uuid' package, import it at the top of your database file:
  // import 'package:uuid/uuid.dart';
  Future<int> getNextReadingId(Database db, String patientUuid) async {
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COALESCE(MAX(reading_id), 0) + 1 as next_id FROM patient_metrics WHERE patient_uuid = ?',
      [patientUuid],
    );

    return result.first['next_id'] as int;
  }

  // insertVitalsBatch, getCurrentVitals, and getVitalsForPatient were retired
  // 2026-08-14 along with the rest of the legacy vitals subsystem (see
  // MEMORY: project-ally-data-model-gaps) — getCurrentVitals queried a
  // patient_current_metrics table that never existed in the schema, and
  // getVitalsForPatient queried a bare "vitals" table that never existed either.
  // insertPatientMetric/getLatestMetric/getNextReadingId below are unrelated —
  // real, live methods still used by user_screen.dart for height/weight — kept.

  Future<MetricValue?> getLatestMetric(String patientUuid, String metricType) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'patient_metrics',
      columns: ['metric_value', 'recorded_at'],
      where: 'patient_uuid = ? AND metric_type = ?',
      whereArgs: [patientUuid, metricType],
      orderBy: 'recorded_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null; // Return null if the user has no history yet
    }

    // Instantly map the database row to our strongly typed data model object
    return MetricValue.fromMap(maps.first);
  }

  // Looks up a condition the patient typed in free-hand rather than picking from the
  // catalog, reusing it if it already exists (case-sensitive — matches the catalog's
  // own UNIQUE(name) constraint) rather than throwing on a duplicate insert. Filed
  // under a dedicated "Custom" category so it renders alongside the real body-system
  // categories without needing a special icon/color lookup path.
  Future<int> getOrCreateCustomCondition(String name) async {
    final db = await database;
    final existing = await db.query('condition', where: 'name = ?', whereArgs: [name], limit: 1);
    if (existing.isNotEmpty) return existing.first['id'] as int;
    return await db.insert('condition', {'name': name, 'category': 'Custom'});
  }

  // Allergies — same chip-toggle catalog shape as Conditions (see allergen.dart).

  Future<Map<String, List<AllergenReference>>> getAllergensCatalog() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('allergen', orderBy: 'category ASC, name ASC');
    final Map<String, List<AllergenReference>> catalog = {};
    for (final row in maps) {
      final reference = AllergenReference.fromMap(row);
      catalog.putIfAbsent(reference.category, () => []).add(reference);
    }
    return catalog;
  }

  Future<int> getOrCreateCustomAllergen(String name) async {
    final db = await database;
    final existing = await db.query('allergen', where: 'name = ?', whereArgs: [name], limit: 1);
    if (existing.isNotEmpty) return existing.first['id'] as int;
    return await db.insert('allergen', {'name': name, 'category': 'Custom'});
  }

  Future<List<PatientAllergy>> getAllergiesForPatient(String patientUuid) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'patient_allergy',
      where: 'patient_uuid = ?',
      whereArgs: [patientUuid],
    );
    return List.generate(maps.length, (i) => PatientAllergy.fromMap(maps[i]));
  }

  Future<int> insertPatientAllergy(PatientAllergy record) async {
    final db = await database;
    return await db.insert('patient_allergy', record.toMap());
  }

  Future<void> updatePatientAllergy(PatientAllergy record) async {
    final db = await database;
    await db.update('patient_allergy', record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<void> deletePatientAllergy(int id) async {
    final db = await database;
    await db.delete('patient_allergy', where: 'id = ?', whereArgs: [id]);
  }

  // The names + severities behind the drug-allergy cross-check on the medication safety
  // audit (see prescription_screen.dart) — a patient's recorded allergies, joined back
  // to the catalog for the actual allergen name (patient_allergy only stores allergen_id).
  Future<List<Map<String, dynamic>>> getPatientAllergyNames(String patientUuid) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT a.name, pa.severity
      FROM patient_allergy pa
      JOIN allergen a ON a.id = pa.allergen_id
      WHERE pa.patient_uuid = ?
      ''',
      [patientUuid],
    );
  }

  // Records that a patient was shown a specific drug-drug interaction warning and chose
  // to continue anyway — the audit trail a doctor may later want ("was the patient warned
  // about this combination"). Keyed on a sorted name pair (via ConflictAlgorithm.replace on
  // the table's UNIQUE constraint) so acknowledging from either medication's card hits the
  // same row, and re-acknowledging after a dismissal cleanly clears dismissed_at again.
  Future<void> acknowledgeInteraction({
    required String patientUuid,
    required String medicationA,
    required String medicationB,
  }) async {
    final db = await database;
    final List<String> sorted = [medicationA.toLowerCase().trim(), medicationB.toLowerCase().trim()]..sort();
    await db.insert('interaction_acknowledgment', {
      'patient_uuid': patientUuid,
      'medication_a': sorted[0],
      'medication_b': sorted[1],
      'acknowledged_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Hides an already-acknowledged interaction chip. Doesn't delete the acknowledgment
  // record — the "we showed them, they accepted it" audit trail should survive dismissal.
  Future<void> dismissInteractionAcknowledgment({
    required String patientUuid,
    required String medicationA,
    required String medicationB,
  }) async {
    final db = await database;
    final List<String> sorted = [medicationA.toLowerCase().trim(), medicationB.toLowerCase().trim()]..sort();
    await db.update(
      'interaction_acknowledgment',
      {'dismissed_at': DateTime.now().toIso8601String()},
      where: 'patient_uuid = ? AND medication_a = ? AND medication_b = ?',
      whereArgs: [patientUuid, sorted[0], sorted[1]],
    );
  }

  Future<List<Map<String, dynamic>>> getInteractionAcknowledgments(String patientUuid) async {
    final db = await database;
    return await db.query('interaction_acknowledgment', where: 'patient_uuid = ?', whereArgs: [patientUuid]);
  }

  Future<void> deletePatientCondition(int id) async {
    // Guard clause: If the record doesn't have a database ID, there's nothing to drop
    final db = await database;

    await db.delete('patient_condition', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertPatientCondition(PatientCondition record) async {
    final db = await database;

    await db.insert(
      'patient_condition',
      record.toMap(),
      // ConflictAlgorithm.replace ensures if the record somehow already exists,
      // it overwrites it cleanly without throwing an exception
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePatientCondition(PatientCondition record) async {
    final db = await database;

    await db.update(
      'patient_condition',
      record.toMap(),
      // We target the specific record using its unique ID to avoid accidental overwrites
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> markConditionTreatmentReviewed(int patientConditionId) async {
    final db = await database;
    await db.update(
      'patient_condition',
      {'treatment_reviewed_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [patientConditionId],
    );
  }

  Future<List<PatientCondition>> getConditionsForPatient(String patientUuid) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'patient_condition',
      where: 'patient_uuid = ?',
      whereArgs: [patientUuid],
      // Sort by timestamp descending so the latest data is at the top of the list
      orderBy: 'onset DESC',
    );

    // Convert the List<Map<String, dynamic>> into a List<PatientCondition>
    return List.generate(maps.length, (i) {
      return PatientCondition.fromMap(maps[i]);
    });
  }

  // For the Emergency QR card — real names only, joined against the catalog directly
  // rather than round-tripping through the full PatientCondition/PatientAllergy models
  // (which don't carry name as a stored column — see physical_health.dart's manual
  // catalog join for why). Only active conditions: something resolved years ago isn't
  // relevant to a first responder in a crisis.
  Future<List<String>> getActiveConditionNames(String patientUuid) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT c.name FROM patient_condition pc JOIN condition c ON c.id = pc.condition_id '
      'WHERE pc.patient_uuid = ? AND pc.status = ?',
      [patientUuid, ConditionStatus.active.index],
    );
    return rows.map((r) => r['name'] as String).toList();
  }

  Future<List<String>> getAllergyNames(String patientUuid) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT a.name FROM patient_allergy pa JOIN allergen a ON a.id = pa.allergen_id WHERE pa.patient_uuid = ?',
      [patientUuid],
    );
    return rows.map((r) => r['name'] as String).toList();
  }

  // Reports — data assembled for the three doctor-facing PDF reports (see
  // pdf_report_builder.dart and the report generators in lib/classes/reports/).

  // Full history, every status — a new doctor reading a letter of introduction wants
  // the whole picture, not just what's currently active (unlike the Emergency QR,
  // which deliberately only shows active conditions for a fast-triage context).
  Future<List<Map<String, dynamic>>> getConditionHistoryRows(String patientUuid) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT c.name, pc.status, pc.onset, pc.status_date
      FROM patient_condition pc
      JOIN condition c ON c.id = pc.condition_id
      WHERE pc.patient_uuid = ?
      ORDER BY pc.onset DESC
      ''',
      [patientUuid],
    );
  }

  Future<List<Map<String, dynamic>>> getActiveMedicationRows(String patientUuid) async {
    final db = await database;
    return await db.query(
      'medication',
      columns: ['id', 'name', 'dose', 'freq'],
      where: 'patient_uuid = ? AND stopped_taking IS NULL',
      whereArgs: [patientUuid],
      orderBy: 'name',
    );
  }

  Future<List<Map<String, dynamic>>> getAllergyDetailRows(String patientUuid) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT a.name, pa.severity, pa.reaction
      FROM patient_allergy pa
      JOIN allergen a ON a.id = pa.allergen_id
      WHERE pa.patient_uuid = ?
      ''',
      [patientUuid],
    );
  }

  // "Current concerns" for the letter of introduction — whatever's still bothering the
  // patient right now, not the full symptom history.
  Future<List<Map<String, dynamic>>> getActiveSymptomRows(String patientUuid) async {
    final db = await database;
    return await db.query(
      'markers',
      where: 'patient_uuid = ? AND (resolved IS NULL OR resolved = 0)',
      whereArgs: [patientUuid],
      orderBy: 'recorded DESC',
    );
  }

  // Any medication that overlapped the report window at all — not just what's active
  // today, since a therapy stopped partway through the window still needs its
  // adherence shown for the days it was actually being taken.
  Future<List<Map<String, dynamic>>> getMedicationsActiveInRange(
    String patientUuid,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT id, name, dose, freq, started_taking, stopped_taking
      FROM medication
      WHERE patient_uuid = ? AND started_taking <= ? AND (stopped_taking IS NULL OR stopped_taking >= ?)
      ''',
      [patientUuid, end.toIso8601String(), start.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> getMedicationDoseCountsInRange(
    String patientUuid,
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT medication_id, COUNT(*) as taken_count
      FROM medication_dose_log
      WHERE patient_uuid = ? AND status = 'taken' AND scheduled_for BETWEEN ? AND ?
      GROUP BY medication_id
      ''',
      [patientUuid, start.toIso8601String(), end.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> getMetricReadingsInRange(String patientUuid, DateTime start, DateTime end) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT pm.value, pm.measured, pm.unit_of_measure, m.id AS metric_id, m.name AS metric_name,
             m.safe_lower_limit, m.safe_upper_limit, m.healthy_lower_limit, m.healthy_upper_limit
      FROM patient_metric pm
      JOIN metric m ON m.id = pm.metric_id
      WHERE pm.patient_uuid = ? AND pm.measured BETWEEN ? AND ?
      ORDER BY pm.measured
      ''',
      [patientUuid, start.toIso8601String(), end.toIso8601String()],
    );
  }

  Future<List<Map<String, dynamic>>> getMoodEntriesInRange(String patientUuid, DateTime start, DateTime end) async {
    final db = await database;
    return await db.query(
      'patient_mood',
      where: 'patient_uuid = ? AND start_date BETWEEN ? AND ?',
      whereArgs: [patientUuid, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'start_date',
    );
  }

  Future<List<Map<String, dynamic>>> getSymptomEntriesInRange(String patientUuid, DateTime start, DateTime end) async {
    final db = await database;
    return await db.query(
      'markers',
      where: 'patient_uuid = ? AND recorded BETWEEN ? AND ?',
      whereArgs: [patientUuid, start.millisecondsSinceEpoch ~/ 1000, end.millisecondsSinceEpoch ~/ 1000],
      orderBy: 'recorded',
    );
  }

  Future<List<Map<String, dynamic>>> getTestsCompletedInRange(String patientUuid, DateTime start, DateTime end) async {
    final db = await database;
    return await db.query(
      'test_completion_log',
      where: 'patient_uuid = ? AND completed_on BETWEEN ? AND ?',
      whereArgs: [patientUuid, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'completed_on',
    );
  }

  Future<List<Map<String, dynamic>>> getDiaryEntriesInRange(String patientUuid, DateTime start, DateTime end) async {
    final db = await database;
    return await db.query(
      'patient_diary_entry',
      where: "patient_uuid = ? AND entry_date BETWEEN ? AND ? AND content != ''",
      whereArgs: [patientUuid, _dateOnly(start), _dateOnly(end)],
      orderBy: 'entry_date',
    );
  }

  Future<List<Map<String, dynamic>>> getObservationsForPatient(String patientUuid) async {
    final db = await database;

    return await db.query(
      'observations',
      where: 'patient_uuid = ?',
      whereArgs: [patientUuid],
      // Sort by timestamp descending so the latest data is at the top of the list
      orderBy: 'time_stamp DESC',
    );
  }

  Future<int> deleteObservation(int id) async {
    final db = await database;
    return await db.delete(
      'observations', // Your database table name
      where: 'id = ?', // Target row filter
      whereArgs: [id],
    );
  }

  Future<int> insertObservation(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('observations', row);
  }

  Future<int> updateObservation(int id, Map<String, dynamic> row) async {
    final db = await database;
    return await db.update('observations', row, where: 'id = ?', whereArgs: [id]);
  }

  // Retrieve all vital readings for a specific patient, newest first
  Future<List<Map<String, dynamic>>> getPatientEvents(String uuid) async {
    final db = await database;
    return await db.query('patient_events', where: 'patient_uuid = ?', whereArgs: [uuid], orderBy: 'timestamp DESC');
  }

  Future<Map<String, dynamic>?> getStoredDatasheet(String setId) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'datasheet',
      where: 'set_id = ?',
      whereArgs: [setId],
      limit: 1,
    );
    if (results.isEmpty) return null;

    // 1. Start with the database row (includes 'classes', 'set_id', etc.)
    final Map<String, dynamic> fullRow = Map<String, dynamic>.from(results.first);

    final String? blob = fullRow['raw_json_blob'];

    if (blob != null && blob.isNotEmpty) {
      try {
        // 2. Decode the FDA JSON
        final Map<String, dynamic> decodedJson = json.decode(blob);

        // 3. MERGE: This puts all keys from the JSON into the fullRow map.
        // If there are duplicate keys, the JSON blob values win.
        fullRow.addAll(decodedJson);
      } catch (e) {
        debugPrint('Error decoding stored blob for $setId: $e');
      }
    }

    // Now returns a map containing BOTH DB columns and FDA JSON keys
    return fullRow;
  }

  // Internal helper to avoid calling 'await database' during initialization
  Future<void> rawInsertMedication(Database db, Map<String, dynamic> medication) async {
    await db.insert('medication', {
      'id': medication['id'],
      'patient_uuid': medication['patient_uuid'],
      'name': medication['name'],
      'dose': medication['dose'],
      'freq': medication['freq'],
      'set_id': medication['set_id'] ?? '',
      'has_local_datasheet': medication['has_local_datasheet'] ?? '',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertMedication(Map<String, dynamic> medication) async {
    final db = await database;

    // Since we generate the UUID in the UI, it's already in the map
    await db.insert('medication', {
      'id': medication['id'], // Our Flutter-generated UUID
      'patient_uuid': medication['patient_uuid'],
      'name': medication['name'],
      'dose': medication['dose'],
      'freq': medication['freq'],
      'set_id': medication['set_id'] ?? '',
      'has_local_datasheet': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // The Tether (Updating the set_id)
  Future<void> updateMedicationSetId(String localUuid, String newSetId) async {
    final db = await database;
    await db.update(
      'medication',
      {'set_id': newSetId, 'has_local_datasheet': 1},
      where: 'id = ?',
      whereArgs: [localUuid],
    );
  }

  Future<int> deleteMedication(String medUuid) async {
    final db = await database;
    return await db.delete('medication', where: 'id = ?', whereArgs: [medUuid]);
  }

  // "Removing" a medication from the active list doesn't mean it's gone — the patient
  // may go back on it later, and the history (what they took, for how long) matters for
  // the therapy-impact timeline. This just closes it out rather than deleting the row.
  Future<void> archiveMedication(String medicationId) async {
    final db = await database;
    await db.update(
      'medication',
      {'stopped_taking': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [medicationId],
    );
  }

  // Logs a dosage/frequency change (with the patient/doctor's reason) and updates the
  // medication's live dose/freq to match, atomically — the log is the history, the
  // medication row stays "current," same pattern as patient_mood. Ordered by changed_at,
  // consecutive rows in getMedicationChangeHistory give "how long were they on this dose"
  // for a titration timeline, even though nothing renders that yet.
  Future<void> recordMedicationChange({
    required String medicationId,
    required String patientUuid,
    String? previousDose,
    String? newDose,
    String? previousFreq,
    String? newFreq,
    required String reason,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('medication_change_log', {
        'id': uuid.v4(),
        'medication_id': medicationId,
        'patient_uuid': patientUuid,
        'previous_dose': previousDose,
        'new_dose': newDose,
        'previous_freq': previousFreq,
        'new_freq': newFreq,
        'reason': reason,
      });

      await txn.update('medication', {'dose': ?newDose, 'freq': ?newFreq}, where: 'id = ?', whereArgs: [medicationId]);
    });
  }

  Future<List<Map<String, dynamic>>> getMedicationChangeHistory(String medicationId) async {
    final db = await database;
    return await db.query(
      'medication_change_log',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
      orderBy: 'changed_at ASC',
    );
  }

  // A preference, not a clinical event — one current row per medication (unlike
  // medication_change_log), so a plain upsert is enough; no reason/history needed.
  Future<void> saveMedicationReminderPreference({
    required String medicationId,
    required String patientUuid,
    required bool enabled,
    required Set<ReminderChannel> channels,
    WearableAlertMode? wearableMode,
    required int leadMinutes,
  }) async {
    final db = await database;
    await db.insert('medication_reminder_preference', {
      'medication_id': medicationId,
      'patient_uuid': patientUuid,
      'enabled': enabled ? 1 : 0,
      'chime_enabled': channels.contains(ReminderChannel.chime) ? 1 : 0,
      'text_enabled': channels.contains(ReminderChannel.text) ? 1 : 0,
      'email_enabled': channels.contains(ReminderChannel.email) ? 1 : 0,
      'wearable_enabled': channels.contains(ReminderChannel.wearable) ? 1 : 0,
      'wearable_mode': wearableMode?.name,
      'lead_minutes': leadMinutes,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getMedicationReminderPreference(String medicationId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'medication_reminder_preference',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  Future<void> saveDatasheet(Map<String, dynamic> fdaJson, String? classes) async {
    final db = await database;

    // Extract metadata for dedicated columns
    final openfda = fdaJson['openfda'] ?? {};

    await db.insert('datasheet', {
      'set_id': fdaJson['set_id'],
      'version': fdaJson['version'],
      'classes': classes,
      // RXCUI is often an array in openfda, grab the first one
      'rxcui': (openfda['rxcui'] != null && openfda['rxcui'].isNotEmpty) ? openfda['rxcui'][0] : null,
      'brand_name': (openfda['brand_name'] != null && openfda['brand_name'].isNotEmpty)
          ? openfda['brand_name'][0]
          : null,
      'generic_name': (openfda['generic_name'] != null && openfda['generic_name'].isNotEmpty)
          ? openfda['generic_name'][0]
          : null,
      'raw_json_blob': json.encode(fdaJson),
      'last_synced_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getDatasheetByName(String name) async {
    final db = await database;

    // We use COLLATE NOCASE to ensure the lookup is case-insensitive
    final List<Map<String, dynamic>> results = await db.query(
      'datasheet',
      where: 'generic_name = ? COLLATE NOCASE OR brand_name = ? COLLATE NOCASE',
      whereArgs: [name, name],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first;
    }

    debugPrint('DatabaseManager: No local datasheet found for $name');
    return null;
  }

  Future<void> updateDatasheetClasses(String setId, String classes) async {
    final db = await database;
    await db.update('datasheet', {'classes': classes}, where: 'set_id = ?', whereArgs: [setId]);
  }

  Future<List<Map<String, dynamic>>> scanLocalDatasheetsForContraindications(List<String> drugNames) async {
    List<Map<String, dynamic>> found = [];
    for (var name in drugNames) {
      // 1. Get the local blob for this drug
      // Ensure getDatasheetByName handles the case-insensitive lookup
      final Map<String, dynamic>? blob = await getDatasheetByName(name);
      if (blob == null) continue;

      // 2. Normalize the haystack (The FDA Label Text)
      // We combine the high-risk fields into one searchable string
      final String contra = blob['contraindications']?.toString() ?? "";
      final String interactions = blob['drug_interactions']?.toString() ?? "";

      final String haystack = (contra + interactions).toLowerCase();

      for (var otherName in drugNames) {
        // Don't compare a drug against itself
        if (name.toLowerCase() == otherName.toLowerCase()) continue;

        // 3. Normalize the needle
        final String needle = otherName.toLowerCase().trim();

        // 4. Perform the Scan
        if (needle.isNotEmpty && haystack.contains(needle)) {
          found.add({
            'drugA': name,
            'drugB': otherName,
            'severity': 'high', // Contraindications are always high risk
            'type': 'contraindication',
            'description': 'Interaction found in $name label regarding $otherName.',
          });
        }
      }
    }
    return found;
  }

  // Active by default — archived (stopped_taking set) medications are excluded so a
  // patient who tried something before and stopped doesn't see it mixed into their
  // current list. Pass includeArchived for a future medication-history view.
  Future<List<Map<String, dynamic>>> getMedicationsForPatient(
    String patientUuid, {
    bool includeArchived = false,
  }) async {
    final db = await database;

    return await db.query(
      'medication',
      where: includeArchived ? 'patient_uuid = ?' : 'patient_uuid = ? AND stopped_taking IS NULL',
      whereArgs: [patientUuid],
      // Optional: Sort by name so the list doesn't jump around
      orderBy: 'name ASC',
    );
  }

  Future<String?> getSetIdByName(String medName) async {
    final db = await database;

    // We use LIKE with wildcards to handle minor naming variations
    // (e.g., "Metformin" matching "Metformin Hydrochloride")
    final List<Map<String, dynamic>> results = await db.query(
      'datasheet',
      columns: ['set_id'],
      where: 'generic_name LIKE ? OR brand_name LIKE ?',
      whereArgs: ['%$medName%', '%$medName%'],
      limit: 1, // We only need one valid tether
    );

    if (results.isNotEmpty) {
      return results.first['set_id'] as String;
    }
    return null;
  }

  Future<int> updateMedicationName(String medicationId, String newQuery) async {
    final db = await database; // Assuming your getter is named 'database'

    return await db.update(
      'medication', // Your table name
      {'name': newQuery},
      where: 'id = ?',
      whereArgs: [medicationId],
    );
  }

  Future<Map<String, dynamic>?> getMedicationById(String id) async {
    final db = await database; // Your getter for the Database instance

    // We query the specific table for the single row matching the ID
    final List<Map<String, dynamic>> results = await db.query('medication', where: 'id = ?', whereArgs: [id], limit: 1);

    if (results.isNotEmpty) {
      return results.first;
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> getPatientConditions(String uuid) async {
    final db = await database;
    return await db.query(
      'patient_condition',
      where: 'patient_uuid = ? AND status = ?',
      whereArgs: [uuid, ConditionStatus.active.index],
    );
  }

  Future<Map<String, dynamic>?> getDatasheetBySetId(String setId) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'datasheet',
      where: 'set_id = ?',
      whereArgs: [setId],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, int>> countCompletedAssessments(String patientId) async {
    final db = await database;

    // We query the table directly using the assessment_id column as our key
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
    SELECT assessment_id, COUNT(*) as total
    FROM completed_assessment
    WHERE patient_id = ? AND complete = 1
    GROUP BY assessment_id
  ''',
      [patientId],
    );

    // Convert the list of rows into a Map: {'PHQ-9': 1, 'GAD-7': 0, ...}
    return {for (var row in results) row['assessment_id'] as String: row['total'] as int};
  }

  Future<Map<String, CompletedQuestionnaire>> getCompletedAssessments(String patientId) async {
    final db = await database;

    // We query the table directly using the assessment_id column as our key
    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
   SELECT 
    assessment_id, 
    MAX(last_modified) as last_modified, 
    COUNT(*) as total
  FROM completed_assessment
  WHERE patient_id = ? AND complete = 1
  GROUP BY assessment_id
  ''',
      [patientId],
    );

    // Convert the list of rows into a Map: {'PHQ-9': 1, 'GAD-7': 0, ...}
    return {for (var row in results) row['assessment_id'] as String: CompletedQuestionnaire.fromJson(row)};
  }

  Future<void> saveAssessmentResults({
    required String assessmentId,
    required String patientId,
    required Map<String, String> answers, // Map of question_id -> answer_text
    bool isComplete = true,
  }) async {
    final db = await database;
    final String completedAssessmentId = uuid.v4();
    final String now = DateTime.now().toIso8601String();
    // Use a transaction to ensure data integrity across both tables
    await db.transaction((txn) async {
      // 1. Insert the parent record into completed_assessment
      await txn.insert('completed_assessment', {
        'id': completedAssessmentId,
        'assessment_id': assessmentId,
        'patient_id': patientId,
        'date_started': now, // In a real flow, you might track actual start time
        'complete': isComplete ? 1 : 0,
        'date_completed': isComplete ? now : null,
        'last_modified': now,
      });

      // 2. Insert each individual answer into completed_question
      for (var entry in answers.entries) {
        await txn.insert('completed_question', {
          'completed_assessment_id': completedAssessmentId,
          'question_id': entry.key,
          'answer': entry.value,
        });
      }
    });
  }

  Future<Map<String, String>?> getLatestAssessmentResults({
    required String assessmentId,
    required String patientId,
  }) async {
    final db = await database;
    // Find the ID of the most recent completed assessment for this patient/scale
    final List<Map<String, dynamic>> assessmentMaps = await db.query(
      'completed_assessment',
      where: 'assessment_id = ? AND patient_id = ? AND complete = 1',
      whereArgs: [assessmentId, patientId],
      orderBy: 'date_completed DESC',
      limit: 1,
    );

    if (assessmentMaps.isEmpty) return null;

    final String completedId = assessmentMaps.first['id'];

    // 2. Fetch all answers associated with that specific completion ID
    final List<Map<String, dynamic>> questionMaps = await db.query(
      'completed_question',
      where: 'completed_assessment_id = ?',
      whereArgs: [completedId],
    );

    // Reconstruct the Map<String, String> (question_id -> answer)
    return {for (var row in questionMaps) row['question_id'] as String: row['answer'] as String};
  }
  //
  // Future<(bool, String)> checkInteractions(String primarySetId, String otherSetId) async {
  //   final db = await database;
  //
  //   // The Full CTE
  //   final List<Map<String, dynamic>> result = await db.rawQuery(
  //     r'''
  //   WITH RECURSIVE split_classes(class_name, remainder) AS (
  //     SELECT
  //       trim(substr(classes || ',', 1, instr(classes || ',', ',') - 1)),
  //       substr(classes || ',', instr(classes || ',', ',') + 1)
  //     FROM datasheet WHERE set_id = ?
  //     UNION ALL
  //     SELECT
  //       trim(substr(remainder, 1, instr(remainder, ',') - 1)),
  //       substr(remainder, instr(remainder, ',') + 1)
  //     FROM split_classes
  //     WHERE remainder != ''
  //   )
  //   SELECT class_name FROM split_classes WHERE class_name != '';
  // ''',
  //     [otherSetId],
  //   );
  //
  //   if (result.isNotEmpty) {
  //     List<String> list = result.map((e) => e['class_name'].toString()).toList();
  //     return (true, list.first);
  //   }
  //   return (false, "");
  // }

  Future<List<Map<String, dynamic>>> getProviders(String patientUuid) async {
    final db = await database;

    // Use a LEFT JOIN to ensure we get the patient even if they have no vitals yet
    return await db.rawQuery(
      '''
    SELECT p.*
    FROM provider p WHERE patient_uuid = ?
    ORDER BY p.last_name, p.first_name
  ''',
      [patientUuid],
    );
  }

  // A local record only — nothing here actually books anything with the provider's
  // real scheduling system, since this app has no such integration. It's a note-to-
  // self the patient can act on (call/email the office), not a synced calendar entry.
  Future<String> insertAppointment({
    required String patientUuid,
    required String providerUuid,
    required DateTime scheduledFor,
    String? reason,
    String? notes,
  }) async {
    final db = await database;
    final String id = uuid.v4();
    await db.insert('appointment', {
      'id': id,
      'patient_uuid': patientUuid,
      'provider_uuid': providerUuid,
      'scheduled_for': scheduledFor.toIso8601String(),
      'reason': reason,
      'notes': notes,
    });
    return id;
  }

  Future<List<Map<String, dynamic>>> getAppointmentsForPatient(String patientUuid) async {
    final db = await database;
    return await db.query(
      'appointment',
      where: 'patient_uuid = ?',
      whereArgs: [patientUuid],
      orderBy: 'scheduled_for ASC',
    );
  }

  // Every appointment booked with one specific provider — used by the caregiver card
  // to find the one worth showing as a chip (soonest upcoming, or most recent past if
  // nothing's upcoming) without pulling every appointment across every provider.
  Future<List<Map<String, dynamic>>> getAppointmentsForProvider(String patientUuid, String providerUuid) async {
    final db = await database;
    return await db.query(
      'appointment',
      where: 'patient_uuid = ? AND provider_uuid = ?',
      whereArgs: [patientUuid, providerUuid],
      orderBy: 'scheduled_for ASC',
    );
  }

  // Active medications that have reminders turned on, joined with their preference row
  // — the Remindable feed's source for medication reminders.
  Future<List<Map<String, dynamic>>> getMedicationsWithReminders(String patientUuid) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT m.*, r.chime_enabled, r.text_enabled, r.email_enabled, r.wearable_enabled, r.wearable_mode, r.lead_minutes
    FROM medication m
    JOIN medication_reminder_preference r ON r.medication_id = m.id
    WHERE m.patient_uuid = ? AND m.stopped_taking IS NULL AND r.enabled = 1
  ''',
      [patientUuid],
    );
  }

  // The actual record a missed dose/appointment/shot needs — "Done"/"Skipped" on a
  // reminder write here, not just dismiss the on-screen card.
  Future<void> logMedicationDose({
    required String medicationId,
    required String patientUuid,
    required DateTime scheduledFor,
    required String status, // 'taken' | 'missed' | 'snoozed' | 'skipped'
  }) async {
    final db = await database;
    await db.insert('medication_dose_log', {
      'id': uuid.v4(),
      'medication_id': medicationId,
      'patient_uuid': patientUuid,
      'scheduled_for': scheduledFor.toIso8601String(),
      'status': status,
      'responded_at': DateTime.now().toIso8601String(),
    });

    // A dose actually taken consumes one unit of whatever supply is linked to this
    // medication (e.g. an insulin syringe) — real observed usage, not a guessed daily
    // rate, and the only case a supply's count changes without the patient touching
    // the Supplies screen at all. MAX(...,0) floors it rather than going negative.
    if (status == 'taken') {
      await db.rawUpdate(
        'UPDATE patient_supply SET quantity_on_hand = MAX(quantity_on_hand - 1, 0) '
        'WHERE patient_uuid = ? AND linked_medication_id = ?',
        [patientUuid, medicationId],
      );
    }
  }

  // Today's logged doses for every medication a patient has — used to keep a reminder
  // from resurfacing once that specific dose has already been marked done/skipped.
  Future<List<Map<String, dynamic>>> getTodaysMedicationDoseLog(String patientUuid) async {
    final db = await database;
    final DateTime now = DateTime.now();
    final String todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final String todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();
    return await db.query(
      'medication_dose_log',
      where: 'patient_uuid = ? AND scheduled_for >= ? AND scheduled_for <= ?',
      whereArgs: [patientUuid, todayStart, todayEnd],
    );
  }

  // "Don't remind me again" — turns the reminder off without touching whether the
  // patient is still taking the medication (that's archiveMedication's job).
  Future<void> muteMedicationReminder(String medicationId) async {
    final db = await database;
    await db.update(
      'medication_reminder_preference',
      {'enabled': 0},
      where: 'medication_id = ?',
      whereArgs: [medicationId],
    );
  }

  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    final db = await database;
    await db.update('appointment', {'status': status}, where: 'id = ?', whereArgs: [appointmentId]);
  }

  Future<void> rescheduleAppointment(String appointmentId, DateTime newTime) async {
    final db = await database;
    await db.update(
      'appointment',
      {'scheduled_for': newTime.toIso8601String(), 'status': 'scheduled'},
      where: 'id = ?',
      whereArgs: [appointmentId],
    );
  }

  // Full edit — time, reason, and notes together — for when the patient got a detail
  // wrong or wants to change it, distinct from rescheduleAppointment (time only, used
  // by the reminder "bump" action) and updateAppointmentStatus (status only).
  Future<void> updateAppointmentDetails(
    String appointmentId, {
    required DateTime scheduledFor,
    String? reason,
    String? notes,
  }) async {
    final db = await database;
    await db.update(
      'appointment',
      {'scheduled_for': scheduledFor.toIso8601String(), 'reason': reason, 'notes': notes, 'status': 'scheduled'},
      where: 'id = ?',
      whereArgs: [appointmentId],
    );
  }

  Future<void> addPatientMedicalDevice(String deviceId, String patientId) async {
    final db = await database;

    // Use a LEFT JOIN to ensure we get the patient even if they have no vitals yet
    await db.rawInsert(
      '''
    INSERT INTO patient_device
    (device_id, patient_uuid) VALUES(?, ?)
  ''',
      [deviceId, patientId],
    );
  }

  Future<void> deletePatientMedicalDevice(String deviceId, String patientId) async {
    final db = await database;

    // Use a LEFT JOIN to ensure we get the patient even if they have no vitals yet
    await db.rawDelete(
      '''
    DELETE FROM patient_device
    WHERE device_id = ? AND patient_uuid = ?
  ''',
      [deviceId, patientId],
    );
  }

  Future<void> insertTrackingMetric({required int metricId, required String patientUuid}) async {
    final db = await database;
    db.rawInsert(
      '''
    INSERT INTO patient_metric_tracking
    (metric_id, patient_uuid) VALUES(?, ?)
  ''',
      [metricId, patientUuid],
    );
  }

  Future<void> setMetricOnDashboard({
    required int metricId,
    required String patientUuid,
    required bool onDashboard,
  }) async {
    final db = await database;
    await db.update(
      'patient_metric_tracking',
      {'on_dashboard': onDashboard ? 1 : 0},
      where: 'metric_id = ? AND patient_uuid = ?',
      whereArgs: [metricId, patientUuid],
    );
  }

  // How a tracked metric's readings are being captured — a doctor reading this data
  // benefits from knowing a BP reading came from an automatic monitor vs. a manual
  // cuff, for instance. `sourceDetail` only means something when source is 'device';
  // passed null for an observation-sourced metric.
  Future<void> setMetricSource({
    required int metricId,
    required String patientUuid,
    required String source,
    String? sourceDetail,
  }) async {
    final db = await database;
    await db.update(
      'patient_metric_tracking',
      {'source': source, 'source_detail': sourceDetail},
      where: 'metric_id = ? AND patient_uuid = ?',
      whereArgs: [metricId, patientUuid],
    );
  }

  // The `device` table already existed in the schema (name, started_using/stopped_using,
  // `measures` -> metric.id) with zero Dart code ever touching it. Recording device
  // choices here means the picker's "Your devices" suggestions are the patient's own real
  // history, not just a generic catalog guess — a much better second-time suggestion.
  Future<void> recordDeviceUsage({required String patientUuid, required String name, required int metricId}) async {
    final db = await database;
    final existing = await db.query(
      'device',
      columns: ['id'],
      where: 'patient_uuid = ? AND name = ? AND measures = ? AND stopped_using IS NULL',
      whereArgs: [patientUuid, name, metricId],
      limit: 1,
    );
    if (existing.isNotEmpty) return;
    await db.insert('device', {'patient_uuid': patientUuid, 'name': name, 'measures': metricId});
  }

  Future<List<String>> getDeviceNamesForMetric({required String patientUuid, required int metricId}) async {
    final db = await database;
    final rows = await db.query(
      'device',
      columns: ['name'],
      where: 'patient_uuid = ? AND measures = ? AND stopped_using IS NULL',
      whereArgs: [patientUuid, metricId],
      orderBy: 'started_using DESC',
    );
    return rows.map((r) => r['name'] as String).toList();
  }

  // Same shape as saveMedicationReminderPreference — one row per (metric, patient),
  // upserted via replace since there's nothing history-worthy about a reminder setting
  // itself (unlike the reading it reminds about).
  Future<void> saveMetricReminderPreference({
    required int metricId,
    required String patientUuid,
    required bool enabled,
    required Set<ReminderChannel> channels,
    WearableAlertMode? wearableMode,
    required String cadence,
    String? reminderTime,
  }) async {
    final db = await database;
    await db.insert('metric_reminder_preference', {
      'metric_id': metricId,
      'patient_uuid': patientUuid,
      'enabled': enabled ? 1 : 0,
      'chime_enabled': channels.contains(ReminderChannel.chime) ? 1 : 0,
      'text_enabled': channels.contains(ReminderChannel.text) ? 1 : 0,
      'email_enabled': channels.contains(ReminderChannel.email) ? 1 : 0,
      'wearable_enabled': channels.contains(ReminderChannel.wearable) ? 1 : 0,
      'wearable_mode': wearableMode?.name,
      'cadence': cadence,
      'reminder_time': reminderTime,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getMetricReminderPreference({
    required int metricId,
    required String patientUuid,
  }) async {
    final db = await database;
    final results = await db.query(
      'metric_reminder_preference',
      where: 'metric_id = ? AND patient_uuid = ?',
      whereArgs: [metricId, patientUuid],
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  // Bulk form, same shape as getActiveThresholds/getActiveTargets — so the dashboard
  // screen can load every reminder preference for the patient in one query rather than
  // one round trip per tracked metric.
  Future<List<Map<String, dynamic>>> getAllMetricReminderPreferences(String patientUuid) async {
    final db = await database;
    return await db.query('metric_reminder_preference', where: 'patient_uuid = ?', whereArgs: [patientUuid]);
  }

  Future<void> muteMetricReminder({required int metricId, required String patientUuid}) async {
    final db = await database;
    await db.update(
      'metric_reminder_preference',
      {'enabled': 0},
      where: 'metric_id = ? AND patient_uuid = ?',
      whereArgs: [metricId, patientUuid],
    );
  }

  // Only metrics the patient is actively tracking, with an enabled reminder — plus the
  // most recent real reading time, so ReminderRegistry can compute "next due" from when
  // they actually last logged one rather than a fixed daily slot (the metric equivalent
  // of MedicationReminder's dose-log exclusion, but generalized to any cadence instead
  // of only "today").
  Future<List<Map<String, dynamic>>> getMetricsWithReminders(String patientUuid) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT m.id AS metric_id, m.name, r.chime_enabled, r.text_enabled, r.email_enabled,
           r.wearable_enabled, r.wearable_mode, r.cadence, r.reminder_time,
           (SELECT MAX(pm.measured) FROM patient_metric pm WHERE pm.metric_id = m.id AND pm.patient_uuid = ?) AS last_measured
    FROM patient_metric_tracking t
    JOIN metric m ON m.id = t.metric_id
    JOIN metric_reminder_preference r ON r.metric_id = t.metric_id AND r.patient_uuid = t.patient_uuid
    WHERE t.patient_uuid = ? AND r.enabled = 1
  ''',
      [patientUuid, patientUuid],
    );
  }

  Future<void> deleteTrackingMetric({required int metricId, required String patientUuid}) async {
    final db = await database;
    await db.rawDelete(
      '''
    DELETE FROM patient_metric_tracking
    WHERE metric_id = ? AND patient_uuid = ?
  ''',
      [metricId, patientUuid],
    );
  }

  Future<List<Map<String, dynamic>>> getAllMetrics() async {
    final db = await database;

    return await db.rawQuery('''
    SELECT *
    FROM metric
  ''');
  }

  Future<List<Map<String, dynamic>>> getTrackedMetrics(String patientUuid) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT *
    FROM patient_metric_tracking pmt WHERE
    pmt.patient_uuid = ?
  ''',
      [patientUuid],
    );
  }

  Future<List<Map<String, dynamic>>> getAllPatientMetricValues(String patientUuid) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT *
    FROM patient_metric pm WHERE
    pm.patient_uuid = ?
    ORDER BY pm.metric_id, pm.measured
  ''',
      [patientUuid],
    );
  }

  // The catalog-driven metric system (metric/patient_metric/patient_metric_tracking)
  // had every read query already built — ranges, thresholds, targets, this table's own
  // history query below — but no way to actually write a new reading into `patient_metric`
  // at all. The card's "Add a Reading" button called this via a stub that did nothing.
  Future<void> insertPatientMetricReading({
    required String patientUuid,
    required int metricId,
    required double value,
    String unitOfMeasure = '',
  }) async {
    final db = await database;
    await db.insert('patient_metric', {
      'id': const Uuid().v4(),
      'metric_id': metricId,
      'patient_uuid': patientUuid,
      'value': value,
      'unit_of_measure': unitOfMeasure,
      'is_metric': 1,
    });
  }

  // Deliberately simple, generic table — name/reason/icon/date/patient, nothing
  // achievement-type-specific. hasAchievement is the dedup guard: reaching an
  // already-won target again on a later reading shouldn't mint a second trophy.
  Future<void> insertAchievement({
    required String patientUuid,
    required String name,
    String? reason,
    String? icon,
  }) async {
    final db = await database;
    await db.insert('achievement', {'patient_uuid': patientUuid, 'name': name, 'reason': reason, 'icon': icon});
  }

  Future<bool> hasAchievement({required String patientUuid, required String name}) async {
    final db = await database;
    final rows = await db.query(
      'achievement',
      columns: ['id'],
      where: 'patient_uuid = ? AND name = ?',
      whereArgs: [patientUuid, name],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getAchievements(String patientUuid) async {
    final db = await database;
    return await db.query(
      'achievement',
      where: 'patient_uuid = ?',
      whereArgs: [patientUuid],
      orderBy: 'earned_at DESC',
    );
  }

  // Drives the avatar's "come look" ripple — on while there's at least one trophy the
  // patient hasn't actually looked at yet, off the moment they have.
  Future<bool> hasUnacknowledgedAchievement(String patientUuid) async {
    final db = await database;
    final rows = await db.query(
      'achievement',
      columns: ['id'],
      where: 'patient_uuid = ? AND acknowledged_at IS NULL',
      whereArgs: [patientUuid],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // Opening the Trophy Case is the acknowledgment moment — everything unseen at that
  // point is marked seen in one go, rather than requiring a tap on each individual
  // trophy before the halo will stop.
  Future<void> acknowledgeAllAchievements(String patientUuid) async {
    final db = await database;
    await db.update(
      'achievement',
      {'acknowledged_at': DateTime.now().toIso8601String()},
      where: 'patient_uuid = ? AND acknowledged_at IS NULL',
      whereArgs: [patientUuid],
    );
  }

  Future<List<Map<String, dynamic>>> getPatientMetricValuesForMetric(String patientUuid, int metricId) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT *
    FROM patient_metric pm WHERE
    pm.patient_uuid = ?
    AND pm.metric_id = ?
    ORDER BY pm.metric_id, pm.measured
  ''',
      [patientUuid, metricId],
    );
  }

  Future<List<Map<String, dynamic>>> getPatientMetricRanges(String patientUuid) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT 
      t.metric_id, 
      COALESCE(MIN(pm.value), 0) AS min_val, 
      COALESCE(MAX(pm.value), 0) AS max_val, 
      COUNT(pm.value) AS count
    FROM patient_metric_tracking t
    LEFT JOIN patient_metric pm ON t.patient_uuid = pm.patient_uuid AND t.metric_id = pm.metric_id
    WHERE t.patient_uuid = ? 
    GROUP BY t.metric_id
    ORDER BY t.metric_id;
    ''',
      [patientUuid],
    );
  }

  Future<List<Map<String, dynamic>>> getRecentPatientMetrics(String patientUuid) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT pm.* 
    FROM patient_metric pm
    INNER JOIN (
      SELECT metric_id, MAX(measured) AS max_measured
      FROM patient_metric
      WHERE patient_uuid = ?
      GROUP BY metric_id
    ) latest ON pm.metric_id = latest.metric_id AND pm.measured = latest.max_measured
    WHERE pm.patient_uuid = ?
    ORDER BY pm.metric_id;
    ''',
      [patientUuid, patientUuid],
    );
  }

  // Metric thresholds/targets — see metric_value.dart's MetricThreshold/MetricTarget
  // for why these are two separate concepts (doctor-communicated safety bounds vs. a
  // personal single-point goal) rather than one shape.

  Future<List<Map<String, dynamic>>> getActiveThresholds(String patientUuid) async {
    final db = await database;
    return await db.query(
      'patient_metric_threshold',
      where: 'patient_uuid = ? AND active = 1',
      whereArgs: [patientUuid],
    );
  }

  // Deactivates whatever threshold was previously on file for this metric and inserts
  // the new one as active, rather than overwriting in place — same "keep history,
  // don't destroy it" shape as trackMoodChange, so a past reading can still be checked
  // against whatever threshold was actually active when it was recorded.
  Future<void> setPatientMetricThreshold({
    required String patientUuid,
    required int metricId,
    double? dangerLow,
    double? dangerHigh,
    double? healthyLow,
    double? healthyHigh,
    String? setBy,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'patient_metric_threshold',
        {'active': 0},
        where: 'patient_uuid = ? AND metric_id = ? AND active = 1',
        whereArgs: [patientUuid, metricId],
      );
      await txn.insert('patient_metric_threshold', {
        'patient_uuid': patientUuid,
        'metric_id': metricId,
        'danger_low': dangerLow,
        'danger_high': dangerHigh,
        'healthy_low': healthyLow,
        'healthy_high': healthyHigh,
        'set_by': setBy,
        'active': 1,
      });
    });
  }

  Future<List<Map<String, dynamic>>> getActiveTargets(String patientUuid) async {
    final db = await database;
    return await db.query('patient_metric_target', where: 'patient_uuid = ? AND active = 1', whereArgs: [patientUuid]);
  }

  Future<void> setPatientMetricTarget({
    required String patientUuid,
    required int metricId,
    required double targetValue,
    required TargetDirection direction,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'patient_metric_target',
        {'active': 0},
        where: 'patient_uuid = ? AND metric_id = ? AND active = 1',
        whereArgs: [patientUuid, metricId],
      );
      await txn.insert('patient_metric_target', {
        'patient_uuid': patientUuid,
        'metric_id': metricId,
        'target_value': targetValue,
        'direction': direction.index,
        'active': 1,
      });
    });
  }

  Future<void> clearPatientMetricTarget(String patientUuid, int metricId) async {
    final db = await database;
    await db.update(
      'patient_metric_target',
      {'active': 0},
      where: 'patient_uuid = ? AND metric_id = ? AND active = 1',
      whereArgs: [patientUuid, metricId],
    );
  }

  // Timeline — real dots and comparison spans, replacing the widget's old
  // never-touches-the-database mock data (see patient_action.dart / timeline_span.dart).

  // At least 5 distinct days with something recorded, spanning at least a week — below
  // this, a real graph is mostly empty space and misleadingly sparse rather than
  // informative, so the widget shows labeled example data instead until it's cleared.
  Future<bool> hasSufficientTimelineData(String patientUuid) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT DISTINCT date(occurred) as d FROM (
        SELECT scheduled_for as occurred FROM medication_dose_log WHERE patient_uuid = ? AND status = 'taken'
        UNION ALL SELECT scheduled_for FROM appointment WHERE patient_uuid = ? AND status != 'scheduled'
        UNION ALL SELECT datetime(recorded, 'unixepoch') FROM markers WHERE patient_uuid = ?
        UNION ALL SELECT start_date FROM patient_mood WHERE patient_uuid = ?
        UNION ALL SELECT completed_on FROM test_completion_log WHERE patient_uuid = ?
      )
      ''',
      [patientUuid, patientUuid, patientUuid, patientUuid, patientUuid],
    );
    if (rows.length < 5) return false;
    final List<DateTime> dates = rows.map((r) => DateTime.parse(r['d'] as String)).toList()..sort();
    return dates.last.difference(dates.first).inDays >= 7;
  }

  // Same five categories the Patient Diary already aggregates per-day (see
  // DatabaseManager.getDayEvents) — this is the all-time version, since the timeline
  // windows by scrolling rather than by a single selected date.
  Future<Map<String, List<Map<String, dynamic>>>> getTimelineEventRows(String patientUuid) async {
    final db = await database;
    final doses = await db.rawQuery(
      '''
      SELECT d.scheduled_for, m.name AS medication_name
      FROM medication_dose_log d
      JOIN medication m ON m.id = d.medication_id
      WHERE d.patient_uuid = ? AND d.status = 'taken'
      ''',
      [patientUuid],
    );
    final appointments = await db.rawQuery(
      '''
      SELECT a.scheduled_for, a.reason, p.first_name || ' ' || p.last_name AS provider_name
      FROM appointment a
      LEFT JOIN provider p ON p.provider_uuid = a.provider_uuid
      WHERE a.patient_uuid = ? AND a.status != 'scheduled'
      ''',
      [patientUuid],
    );
    final symptoms = await db.query('markers', where: 'patient_uuid = ?', whereArgs: [patientUuid]);
    final moods = await db.query('patient_mood', where: 'patient_uuid = ?', whereArgs: [patientUuid]);
    final tests = await db.query('test_completion_log', where: 'patient_uuid = ?', whereArgs: [patientUuid]);
    return {'doses': doses, 'appointments': appointments, 'symptoms': symptoms, 'moods': moods, 'tests': tests};
  }

  Future<List<Map<String, dynamic>>> getMedicationSpanRows(String patientUuid) async {
    final db = await database;
    return await db.query(
      'medication',
      columns: ['id', 'name', 'started_taking', 'stopped_taking'],
      where: 'patient_uuid = ? AND started_taking IS NOT NULL',
      whereArgs: [patientUuid],
    );
  }

  Future<List<Map<String, dynamic>>> getConditionSpanRows(String patientUuid) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT pc.id, c.name, pc.onset, pc.status_date
      FROM patient_condition pc
      JOIN condition c ON c.id = pc.condition_id
      WHERE pc.patient_uuid = ? AND pc.onset IS NOT NULL
      ''',
      [patientUuid],
    );
  }

  Future<List<Map<String, dynamic>>> getProviderSpanRows(String patientUuid) async {
    final db = await database;
    return await db.query(
      'provider',
      columns: ['provider_uuid', 'first_name', 'last_name', 'started_seeing', 'stopped_seeing'],
      where: 'patient_uuid = ? AND started_seeing IS NOT NULL',
      whereArgs: [patientUuid],
    );
  }

  Future<List<Map<String, dynamic>>> getProvider({required String id}) async {
    final db = await database;

    return await db.rawQuery(
      '''
    SELECT *
    FROM provider
    WHERE provider_uuid = ?
  ''',
      [id],
    );
  }

  // The wizard generates medicationId up front (see AddMedicationWizard) so every
  // subsequent add* call below can target the exact row by primary key instead of
  // guessing which row "this patient's medication named X" refers to.
  Future<void> addMedication({required String medicationId, required String name, required String patientUuid}) async {
    await insertMedication({'id': medicationId, 'patient_uuid': patientUuid, 'name': name});
  }

  Future<void> addDosage({required String medicationId, required String dosage}) async {
    final db = await database;
    await db.update('medication', {'dose': dosage}, where: 'id = ?', whereArgs: [medicationId]);
  }

  Future<void> addMedicationType({required String medicationId, required MedicationTypes type}) async {
    final db = await database;
    await db.update('medication', {'type': type.name}, where: 'id = ?', whereArgs: [medicationId]);
  }

  Future<void> addMedicationShape({required String medicationId, required TabletShapes shape}) async {
    final db = await database;
    await db.update('medication', {'shape': shape.name}, where: 'id = ?', whereArgs: [medicationId]);
  }

  Future<void> addMedicationColor({required String medicationId, required TabletColors color}) async {
    final db = await database;
    await db.update('medication', {'color': color.name}, where: 'id = ?', whereArgs: [medicationId]);
  }

  Future<void> addFrequency({required String medicationId, required Frequency frequency}) async {
    final db = await database;

    final String? latin = frequency.latinRecurrence;
    final String freqLabel = (latin != null && latin.isNotEmpty)
        ? latin
        : (frequency.period != null && frequency.periodUoM != null)
        ? 'every ${frequency.period} ${frequency.periodUoM}'
        : 'PRN';

    // `stopped_taking` is NOT written here — that column now specifically means "the
    // patient discontinued this therapy" for the archive feature (only archiveMedication
    // sets it). The frequency screen's "end date" defaults to 30 days out for every new
    // medication; writing that into stopped_taking made every newly-added medication look
    // pre-archived a month in the future and vanish from the active list immediately.
    //
    // `specificTime` was previously captured by the frequency screen's time picker and
    // then silently discarded — never written anywhere — so the reminder system had no
    // way to honor a time the patient actually chose, only the frequency code's fixed
    // defaults (e.g. 08:00 for "once daily"). Persisted as "HH:mm"; ReminderRegistry
    // prefers it over the frequency-code default when present.
    final String? reminderTime = frequency.specificTime != null
        ? '${frequency.specificTime!.hour.toString().padLeft(2, '0')}:${frequency.specificTime!.minute.toString().padLeft(2, '0')}'
        : null;

    await db.update(
      'medication',
      {'freq': freqLabel, 'started_taking': frequency.start?.toIso8601String(), 'reminder_time': reminderTime},
      where: 'id = ?',
      whereArgs: [medicationId],
    );
  }

  Future<void> deleteProvider({required String providerUuid}) async {
    final db = await database;
    await db.rawDelete(
      '''
    DELETE FROM provider
    WHERE provider_uuid = ? 
  ''',
      [providerUuid],
    );
  }

  Future<void> saveProvider(Provider provider) async {
    final db = await database;

    // Convert your Provider object to a Map (assuming you have a .toMap() method)
    final Map<String, dynamic> providerMap = provider.toMap();

    await db.insert('provider', providerMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
