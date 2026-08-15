import 'dart:convert';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import 'frequency_codes.dart';

class DataSeeder {
  /// Entry point for seeding data.
  /// Only executes in debug mode to prevent data pollution in release builds.
  static Future<void> seed(Database db) async {
    if (!kDebugMode) return;

    debugPrint('--- Starting Database Seeding ---');

    await _seedPatientData(db);
    await _seedObservations(db);
    await _seedConditionsCatalog(db);
    await _seedSuppliesCatalog(db);
    await _seedAllergensCatalog(db);
    await _seedProviders(db);
    await _seedInteractions(db);
    await _seedMetricsAndUnits(db);
    await _seedPatientMetricThresholds(db);
    await _seedTestCatalog(db);

    debugPrint('--- Seeding Complete ---');
  }

  static Future<void> _seedInteractions(Database db) async {
    final rawData = await rootBundle.loadString('assets/interactions/db_drug_interactions.csv');

    //Parse the CSV (assumes first row is header)
    List<List<dynamic>> rows = const CsvToListConverter(
      fieldDelimiter: ',', // Double check this: is it actually a comma?
      eol: '\n', // Or '\r\n' for Windows-style files
      shouldParseNumbers: false,
    ).convert(rawData);

    //Batch insert using a transaction
    await db.transaction((txn) async {
      // Skip the header row (index 0)
      for (int i = 1; i < rows.length; i++) {
        var row = rows[i];
        await txn.insert('interaction', {
          // 'id': row[0].toString(),
          // 'rx_norm_id': '',
          'name_a': row[0].toString(),
          'name_b': row[1].toString(),
          'explanation': row[2].toString(),
          // 'local_datasheet_id': row[5].toString(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  static Future<void> _seedProviders(Database db) async {
    // 1. Verify if the master table has already been populated
    final List<Map<String, dynamic>> existingRecords = await db.rawQuery("SELECT COUNT(*) as total FROM provider");

    if (existingRecords.first['total'] as int > 0) {
      return; // Catalog is already successfully configured!
    }

    try {
      // 2. Read raw condition data groups from json asset bundle
      final String jsonString = await rootBundle.loadString('assets/providers/providers.json');
      final List<dynamic> data = jsonDecode(jsonString);

      Batch batch = db.batch();
      for (var entry in data) {
        batch.insert('provider', {
          'provider_uuid': entry['id'],
          'patient_uuid': entry['patient_uuid'],
          'first_name': entry['first_name'],
          'last_name': entry['last_name'],
          'accreditations': entry['accreditations'],
          'specializations': entry['specializations'],
          'personal_email': entry['email'],
          'office_email': entry['office_email'],
          'position': entry['position'],
          'gender': entry['gender'],
          'is_specialist': 0,
          'pager': entry['pager'],
          'personal_phone': entry['phone'],
          'office_phone': entry['office_phone'],
          'started_seeing': entry['started_seeing'],
          'stopped_seeing': entry['stopped_seeing'],
          'city': entry['city'],
          'street': entry['street'],
          'pr_st': entry['pr_st'],
          'country': entry['country'],
        });
      }

      await batch.commit(noResult: true);
    } catch (error) {
      debugPrint("Critical failure in _seedProviders: $error");
    }
  }

  static Future<void> _seedMetricsAndUnits(Database db) async {
    // 1. Verify if the master tables have already been populated
    final List<Map<String, dynamic>> existingMetrics = await db.rawQuery("SELECT COUNT(*) as total FROM metric");
    final List<Map<String, dynamic>> existingUnits = await db.rawQuery("SELECT COUNT(*) as total FROM unit_of_measure");

    if ((existingMetrics.first['total'] as int > 0) || (existingUnits.first['total'] as int > 0)) {
      return; // Catalogs are already successfully configured!
    }

    try {
      // 2. Read raw metrics data groups from json asset bundle
      final String jsonString = await rootBundle.loadString('assets/metrics/metrics.json');
      final Map<String, dynamic> rootData = jsonDecode(jsonString);
      final List<dynamic> categories = rootData['categories'] ?? [];

      Batch unitBatch = db.batch();
      Batch metricBatch = db.batch();

      // Track inserted units to prevent duplicates since multiple metrics share unit definitions
      final Set<String> insertedUnitSymbols = {};

      for (var category in categories) {
        final List<dynamic> metrics = category['metrics'] ?? [];
        final String categoryName = category['category'] ?? '';

        for (var metric in metrics) {
          // Insert Metric
          debugPrint("Processing: ${metric['id']}");
          int pairId = metric['pair_id'] ?? 0;
          int isPaired = pairId > 0 ? 1 : 0;
          bool isInteger = metric['is_integer'];
          metricBatch.insert('metric', {
            'id': metric['id'],
            'name': metric['name'],
            'symbol': metric['units_of_measure'] != null && metric['units_of_measure'].isNotEmpty
                ? metric['units_of_measure'][0]['symbol']
                : '',
            'category': categoryName,
            'safe_upper_limit': metric['safe_upper'],
            'safe_lower_limit': metric['safe_lower'],
            'healthy_upper_limit': metric['healthy_upper'],
            'healthy_lower_limit': metric['healthy_lower'],
            'is_integer': isInteger ? 1 : 0,
            'description': metric['description'],
            'purpose': metric['purpose'],
            'paired': isPaired,
            'pair_id': pairId,
          });

          // Parse and Queue Units of Measure
          final List<dynamic> units = metric['units_of_measure'] ?? [];
          for (var unit in units) {
            final String symbol = unit['symbol'] ?? '';
            if (symbol.isNotEmpty && !insertedUnitSymbols.contains(symbol)) {
              insertedUnitSymbols.add(symbol);

              final Map<String, dynamic> converters = unit['converters'] ?? {};
              final bool isMetricUnit =
                  unit['name'] != null &&
                  (unit['name'].toString().toLowerCase().contains('metric') ||
                      symbol == '°C' ||
                      symbol == 'kg' ||
                      symbol == 'cm' ||
                      symbol == 'L' ||
                      symbol == 'mmol/L' ||
                      symbol == 'µmol/L' ||
                      symbol == 'mg/L');

              unitBatch.insert('unit_of_measure', {
                'name': unit['name'],
                'symbol': symbol,
                'is_metric': isMetricUnit ? 1 : 0,
                'conversion_functions': jsonEncode(converters),
              }, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
          }
        }
      }

      // Commit batches
      await unitBatch.commit(noResult: true);
      await metricBatch.commit(noResult: true);
    } catch (error) {
      debugPrint("Critical failure in _seedMetricsAndUnits: $error");
    }
  }

  static Future<void> _seedConditionsCatalog(Database db) async {
    // 1. Verify if the master table has already been populated
    final List<Map<String, dynamic>> existingRecords = await db.rawQuery("SELECT COUNT(*) as total FROM condition");

    if (existingRecords.first['total'] as int > 0) {
      return; // Catalog is already successfully configured!
    }

    try {
      // 2. Read raw condition data groups from json asset bundle
      final String jsonString = await rootBundle.loadString('assets/conditions/conditions.json');
      final Map<String, dynamic> parsedJson = jsonDecode(jsonString);

      // 3. Open an atomic batch block for high-performance writing
      final Batch migrationBatch = db.batch();

      parsedJson.forEach((categoryKey, ailmentList) {
        if (ailmentList is List) {
          for (var ailment in ailmentList) {
            if (ailment is Map) {
              // Pass only name and category. SQLite generates the integer ID automatically!
              migrationBatch.insert('condition', {
                'name': ailment["name"],
                'category': categoryKey,
              }, conflictAlgorithm: ConflictAlgorithm.ignore);
            }
          }
        }
      });

      // 4. Commit rows down to the storage engine
      await migrationBatch.commit(noResult: true);
    } catch (error) {
      debugPrint("Critical failure in _seedConditionsCatalog: $error");
    }
  }

  // assets/conditions/allergies.json is shaped as a LIST of {category, description,
  // allergens: [{name, description}]} objects — different from conditions.json's
  // {categoryKey: [...]} map shape, so this doesn't reuse _seedConditionsCatalog's loop.
  static Future<void> _seedAllergensCatalog(Database db) async {
    final List<Map<String, dynamic>> existingRecords = await db.rawQuery("SELECT COUNT(*) as total FROM allergen");
    if (existingRecords.first['total'] as int > 0) {
      return; // Catalog is already successfully configured!
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/conditions/allergies.json');
      final List<dynamic> parsedJson = jsonDecode(jsonString);

      final Batch migrationBatch = db.batch();
      for (final categoryEntry in parsedJson) {
        if (categoryEntry is! Map) continue;
        final String? category = categoryEntry['category'] as String?;
        final allergens = categoryEntry['allergens'];
        if (category == null || allergens is! List) continue;
        for (final allergen in allergens) {
          if (allergen is! Map) continue;
          migrationBatch.insert('allergen', {
            'name': allergen['name'],
            'category': category,
            'description': allergen['description'],
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      await migrationBatch.commit(noResult: true);
    } catch (error) {
      debugPrint("Critical failure in _seedAllergensCatalog: $error");
    }
  }

  // Category per supply name — kept here rather than in the JSON since it drives icon
  // selection (see iconForSupplyCategory in patient_supply.dart) and every condition
  // that mentions the same supply should agree on its category regardless of who wrote
  // that condition's list.
  static const Map<String, String> _supplyCategories = {
    'Blood Glucose Test Strips': 'Testing & Monitoring',
    'Lancets': 'Testing & Monitoring',
    'Alcohol Swabs': 'Injection Supplies',
    'Insulin Syringes': 'Injection Supplies',
    'Sharps Disposal Container': 'Injection Supplies',
    'Sterile Gauze Pads': 'Wound Care',
    'Adhesive Wound Tape': 'Wound Care',
    'Non-Stick Dressings': 'Wound Care',
    'Ostomy Bags': 'Continence & Ostomy',
    'Ostomy Wafers/Skin Barriers': 'Continence & Ostomy',
    'Incontinence Pads': 'Continence & Ostomy',
    'Intermittent Catheters': 'Continence & Ostomy',
    'Nebulizer Masks/Tubing': 'Respiratory',
    'CPAP Filters': 'Respiratory',
  };

  // Reads the same conditions.json a second time (small file, one-time cost) for each
  // condition's optional "supplies" array — not every condition has one; this is a
  // starting list of the more obviously supply-heavy conditions (diabetes, IBD,
  // incontinence, respiratory), not an attempt to cover all ~150 entries at once. Runs
  // after _seedConditionsCatalog so `condition` rows already have real ids to link
  // against.
  static Future<void> _seedSuppliesCatalog(Database db) async {
    final List<Map<String, dynamic>> existingRecords = await db.rawQuery("SELECT COUNT(*) as total FROM supply");
    if (existingRecords.first['total'] as int > 0) {
      return; // Catalog is already successfully configured!
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/conditions/conditions.json');
      final Map<String, dynamic> parsedJson = jsonDecode(jsonString);

      final Batch supplyBatch = db.batch();
      final Set<String> uniqueSupplyNames = {};

      parsedJson.forEach((categoryKey, ailmentList) {
        if (ailmentList is! List) return;
        for (var ailment in ailmentList) {
          if (ailment is! Map) continue;
          final supplies = ailment['supplies'];
          if (supplies is! List) continue;
          for (final supply in supplies) {
            uniqueSupplyNames.add(supply.toString());
          }
        }
      });

      for (final name in uniqueSupplyNames) {
        supplyBatch.insert('supply', {
          'name': name,
          'category': _supplyCategories[name] ?? 'Custom',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await supplyBatch.commit(noResult: true);

      // Now link each condition to its supplies — needs real ids on both sides, so
      // this happens as a second pass once every supply/condition row actually exists.
      final List<Map<String, dynamic>> supplyRows = await db.query('supply');
      final Map<String, int> supplyIdByName = {
        for (final row in supplyRows) row['name'] as String: row['id'] as int,
      };
      final List<Map<String, dynamic>> conditionRows = await db.query('condition');
      final Map<String, int> conditionIdByName = {
        for (final row in conditionRows) row['name'] as String: row['id'] as int,
      };

      final Batch joinBatch = db.batch();
      parsedJson.forEach((categoryKey, ailmentList) {
        if (ailmentList is! List) return;
        for (var ailment in ailmentList) {
          if (ailment is! Map) continue;
          final supplies = ailment['supplies'];
          if (supplies is! List) continue;
          final int? conditionId = conditionIdByName[ailment['name']];
          if (conditionId == null) continue;
          for (final supply in supplies) {
            final int? supplyId = supplyIdByName[supply.toString()];
            if (supplyId == null) continue;
            joinBatch.insert('condition_supply', {
              'condition_id': conditionId,
              'supply_id': supplyId,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      });
      await joinBatch.commit(noResult: true);
    } catch (error) {
      debugPrint("Critical failure in _seedSuppliesCatalog: $error");
    }
  }

  // A reference catalog of common out-of-house (clinic/lab) tests — deliberately not
  // at-home ones, since those mostly duplicate what the Metrics screen already tracks
  // (blood pressure, glucose, SpO2, weight, etc.) with a real value-tracking/trend
  // system this catalog doesn't have. Not an attempt to cover every possible medical
  // test, just a common list to pick from, same spirit as _seedConditionsCatalog.
  static Future<void> _seedTestCatalog(Database db) async {
    final List<Map<String, dynamic>> existingRecords = await db.rawQuery("SELECT COUNT(*) as total FROM test_catalog");
    if (existingRecords.first['total'] as int > 0) {
      return; // Catalog is already successfully configured!
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/tests/tests.json');
      final List<dynamic> data = jsonDecode(jsonString);

      final Batch batch = db.batch();
      for (var entry in data) {
        batch.insert('test_catalog', {
          'name': entry['name'],
          'description': entry['description'],
          'category': entry['category'],
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    } catch (error) {
      debugPrint("Critical failure in _seedTestCatalog: $error");
    }
  }

  static Future<void> _seedObservations(Database db) async {
    final String response = await rootBundle.loadString('assets/observations/observations.json');
    final List<dynamic> data = json.decode(response);

    Batch batch = db.batch();
    for (var entry in data) {
      batch.insert('observations', {
        'patient_uuid': entry['patient_uuid'],
        'content': entry['content'],
        'author_name': entry['author_name'],
        'author_role': entry['author_role'],
      });
    }
    await batch.commit(noResult: true);
    debugPrint('Observations seeded.');
  }

  static String normalize(String? timestamp) {
    if (timestamp == null) return DateTime.now().toString();
    // If it's already a string, parse it then format it
    final dt = DateTime.tryParse(timestamp) ?? DateTime.now();
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}";
  }

  //Seed Patient Personal, Prescription and Vitals information
  static Future<void> _seedPatientData(Database db) async {
    // Parse the master JSON array
    // 1. Read the raw data directly from your local asset storage
    final String rawJsonString = await rootBundle.loadString('assets/patients/patients.json');
    final List<dynamic> decodedData = jsonDecode(rawJsonString);

    // Use a batch transaction block for optimal safety and insert velocity
    await db.transaction((txn) async {
      for (var item in decodedData) {
        if (item is! Map<String, dynamic>) continue;

        final String patientUuid = item['patient_uuid'];

        // 1. Build the clean Patient record map for insertion
        // We explicitly pull the top-level keys matching your core schema
        final Map<String, dynamic> patientRow = {
          'patient_uuid': patientUuid, // maps patient_uuid to local primary key id
          'first_name': item['first_name'],
          'last_name': item['last_name'],
          'acuity': item['acuity'],
          'phn': item['phn'],
          'phase_step_id': item['phase_step_id'],
          'email': item['email'],
          'ssn': item['ssn'],
          'title': item['title'],
          'city': item['city'],
          'country': item['country'],
          'street_address': item['street_address'],
          'province': item['province'],
          'postal_code': item['postal_code'],
          'dob': item['dob'],
          'admitted': item['admitted'],
          'police_reports': item['police_reports'],
          'assessments': item['assessments'],
          'status': item['status'],
          'path': item['path'],
          'phone': item['phone'],
          'family_doctor_phone': item['family_doctor_phone'],
          'contact_phone': item['contact_phone'],
          'pharmacy_phone': item['pharmacy_phone'],
          'pharmacy_fax': item['pharmacy_fax'],
          'family_doctor_name': item['family_doctor_name'],
          'contact_name': item['contact_name'],
          'relation': item['relation'],
          'narrative_hint': item['narrative_hint'],
        };

        // Write parent row down first to satisfy foreign key constraints
        await txn.insert('patient', patientRow, conflictAlgorithm: ConflictAlgorithm.replace);

        // Extract and Seed the Nested Medications ('prescription' array)
        if (item['prescription'] != null && item['prescription'] is List) {
          final List<dynamic> prescriptions = item['prescription'];
          for (var med in prescriptions) {
            // Clean out the ghost formula string error gracefully on insert
            String frequency = med['freq'] ?? 'PRN';
            if (frequency.contains('Syntax error')) {
              frequency = 'PRN'; // Default fallback until the UI toggle is saved
            }

            final String medicationId = '${patientUuid}_med_${med['id']}';
            final int medIndex = (med['id'] as num?)?.toInt() ?? 1;

            // Stagger start dates so medications don't all appear to begin the same day.
            final DateTime startedTaking = DateTime.now().subtract(Duration(days: 5 + (medIndex * 11)));
            // One medication per patient is seeded as a completed/discontinued course,
            // so the timeline and history views have something other than "currently active" to show.
            final bool discontinued = medIndex == 2;
            final DateTime? stoppedTaking = discontinued ? startedTaking.add(const Duration(days: 30)) : null;

            await txn.insert('medication', {
              'id': medicationId, // Unique compound string key
              'patient_uuid': patientUuid, // Links cleanly back to parent
              'set_id': med['set_id'],
              'name': med['name'],
              'dose': med['dose'],
              'freq': frequency,
              'type': med['type'],
              'shape': med['shape'],
              'color': med['color'],
              'started_taking': startedTaking.toIso8601String(),
              'stopped_taking': stoppedTaking?.toIso8601String(),
              'has_local_datasheet': med['has_local_datasheet'] ?? 0,
            }, conflictAlgorithm: ConflictAlgorithm.replace);

            // Only log adherence history for medications the patient is still taking.
            if (!discontinued) {
              // The hero demo patient's BP combo (med id 3) gets a deliberate recent
              // adherence decline, to demo the "declining adherence" story end to end.
              final bool simulateDecline = patientUuid == '02039325-2425-4bf3-bf85-1ec81a797e25' && medIndex == 3;
              await _seedMedicationDoseLog(
                txn,
                medicationId: medicationId,
                patientUuid: patientUuid,
                frequency: frequency,
                startedTaking: startedTaking,
                simulateDecline: simulateDecline,
              );
            }
          }
        }

      }
    });
  }

  /// Backfills the last 7 days of scheduled-dose history for one medication, so the
  /// adherence/reminder UI and the therapy-impact timeline have real rows to render
  /// instead of a blank state. `simulateDecline` skews the most recent 3 days toward
  /// "missed", to demo the declining-adherence scenario end to end.
  static Future<void> _seedMedicationDoseLog(
    Transaction txn, {
    required String medicationId,
    required String patientUuid,
    required String frequency,
    required DateTime startedTaking,
    bool simulateDecline = false,
  }) async {
    // Shared with the live reminder system (FrequencySchedule) so seeded adherence
    // history and real reminders agree on what "qd"/"bid"/etc. actually mean.
    final List<String> doseTimes = FrequencySchedule.dailyTimesFor(frequency);
    if (doseTimes.isEmpty) return;

    final DateTime today = DateTime.now();
    final DateTime windowStart = today.subtract(const Duration(days: 7));
    final DateTime effectiveStart = startedTaking.isAfter(windowStart) ? startedTaking : windowStart;

    // Seeded per-medication so re-running the seeder produces the same demo history.
    final Random rng = Random(medicationId.hashCode);

    for (DateTime day = effectiveStart; day.isBefore(today); day = day.add(const Duration(days: 1))) {
      final int daysAgo = today.difference(day).inDays;

      for (final String time in doseTimes) {
        final List<String> parts = time.split(':');
        final DateTime scheduledFor = DateTime(day.year, day.month, day.day, int.parse(parts[0]), int.parse(parts[1]));

        final String status;
        if (simulateDecline && daysAgo <= 3) {
          status = rng.nextDouble() < 0.75 ? 'missed' : 'taken';
        } else {
          final double roll = rng.nextDouble();
          status = roll < 0.85 ? 'taken' : (roll < 0.93 ? 'snoozed' : 'missed');
        }

        await txn.insert('medication_dose_log', {
          'id': '${medicationId}_dose_${scheduledFor.millisecondsSinceEpoch}',
          'medication_id': medicationId,
          'patient_uuid': patientUuid,
          'scheduled_for': scheduledFor.toIso8601String(),
          'status': status,
          'responded_at': status == 'taken' ? scheduledFor.add(const Duration(minutes: 5)).toIso8601String() : null,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  /// Seeds per-patient, three-tier (danger/acceptable/healthy) alert thresholds for the
  /// demo patient's blood pressure, standing in for a doctor having customized the
  /// catalog defaults for this specific patient. Storage only — no trigger/notification
  /// logic reads these yet.
  static Future<void> _seedPatientMetricThresholds(Database db) async {
    final List<Map<String, dynamic>> existing = await db.rawQuery(
      "SELECT COUNT(*) as total FROM patient_metric_threshold",
    );
    if (existing.first['total'] as int > 0) {
      return; // Already configured!
    }

    const String heroPatientUuid = '02039325-2425-4bf3-bf85-1ec81a797e25';
    const String cardiologistUuid = '61659e82-7b1f-4edb-a465-2490a13a7c20';

    try {
      final Batch batch = db.batch();
      batch.insert('patient_metric_threshold', {
        'patient_uuid': heroPatientUuid,
        'metric_id': 1, // Blood Pressure - Systolic
        'danger_low': 85,
        'healthy_low': 105,
        'healthy_high': 125,
        'danger_high': 150,
        'set_by': cardiologistUuid,
      });
      batch.insert('patient_metric_threshold', {
        'patient_uuid': heroPatientUuid,
        'metric_id': 2, // Blood Pressure - Diastolic
        'danger_low': 50,
        'healthy_low': 65,
        'healthy_high': 85,
        'danger_high': 100,
        'set_by': cardiologistUuid,
      });
      await batch.commit(noResult: true);
    } catch (error) {
      debugPrint("Critical failure in _seedPatientMetricThresholds: $error");
    }
  }
}
