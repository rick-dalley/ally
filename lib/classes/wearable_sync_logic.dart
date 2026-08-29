import 'package:flutter/material.dart';

import '../widgets/emergency_qr.dart';
import 'alertable.dart';
import 'database_manager.dart';
import 'patient.dart';
import 'patient_sentiment.dart';

// Transport-agnostic business logic behind every wearable interaction — shared by
// WearableSyncServer (HTTP, the Linux prototype) and WearableDataLayerBridge (Google's
// Wearable Data Layer API, for Wear OS). Both transports carry the exact same JSON
// shapes; only how the bytes get from one device to the other differs.
class WearableSyncLogic {
  // "#RRGGBB" rather than an ARGB int — a plain hex string parses trivially on both
  // watch platforms (UIColor/Color init from hex) without either needing to agree on
  // Flutter's own bit layout.
  static String _hex(Color color) {
    String channel(double v) => (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#${channel(color.r)}${channel(color.g)}${channel(color.b)}';
  }

  // Every Sentiment a watch can offer in its own mood picker — label + color only
  // (not the icon; Material Symbols codepoints don't mean anything to SF Symbols or
  // Android's icon set, so each watch app picks its own icon per label instead of
  // trying to transmit one).
  static List<Map<String, dynamic>> get moodOptions =>
      Sentiment.values.map((s) => {'index': s.index, 'label': s.label, 'color': _hex(s.color)}).toList();

  static Future<Map<String, dynamic>> buildSyncPayload(String patientUuid) async {
    final List<Map<String, dynamic>> rows = await DatabaseManager().getPatientWithVitals(patientUuid: patientUuid);
    if (rows.isEmpty) return {'error': 'patient not found'};
    final Patient patient = Patient.fromJson(rows.first);
    final Map<String, dynamic> emergencyPayload = await EmergencyQRCodeView.buildEmergencyPayload(patient);
    final Map<String, dynamic> due = await DatabaseManager().getWearableDueItems(patientUuid);
    final Map<String, dynamic> settingsRow = await DatabaseManager().getOrCreateWearableSettings(patientUuid);
    final List<WearableAlertConfig> alerts = alertConfigsFromRow(settingsRow);
    final Map<String, dynamic>? currentMoodRow = await DatabaseManager().getCurrentMood(patientUuid);
    final Sentiment currentMood = currentMoodRow != null ? Sentiment.values[currentMoodRow['mood'] as int] : Sentiment.calm;
    return {
      'emergencyQr': emergencyPayload,
      ...due,
      'alerts': {for (final a in alerts) a.trigger.name: a.enabled},
      'currentMood': {'index': currentMood.index, 'label': currentMood.label, 'color': _hex(currentMood.color)},
      'moodOptions': moodOptions,
    };
  }

  static Future<Map<String, dynamic>> handleSetMood({required String patientUuid, required int moodIndex}) async {
    await DatabaseManager().trackMoodChange(patientUuid, moodIndex);
    return buildSyncPayload(patientUuid);
  }

  static Future<Map<String, dynamic>> handleAck({required String patientUuid, required String type, required String id}) async {
    final db = DatabaseManager();
    if (type == 'medication') {
      await db.logMedicationDose(medicationId: id, patientUuid: patientUuid, scheduledFor: DateTime.now(), status: 'taken');
    } else if (type == 'careOrder') {
      await db.acknowledgeCareOrder(careOrderId: id, patientUuid: patientUuid);
    }
    return buildSyncPayload(patientUuid);
  }

  static Future<Map<String, dynamic>> handleAckAll(String patientUuid) async {
    final db = DatabaseManager();
    final Map<String, dynamic> due = await db.getWearableDueItems(patientUuid);
    final Set<String> doneMeds = Set<String>.from(due['doneMedicationIds'] as List);
    final Set<String> doneOrders = Set<String>.from(due['doneCareOrderIds'] as List);
    for (final med in (due['medications'] as List<dynamic>)) {
      final String id = med['id'] as String;
      if (!doneMeds.contains(id)) {
        await db.logMedicationDose(medicationId: id, patientUuid: patientUuid, scheduledFor: DateTime.now(), status: 'taken');
      }
    }
    for (final order in (due['careOrders'] as List<dynamic>)) {
      final String id = order['id'] as String;
      if (!doneOrders.contains(id)) {
        await db.acknowledgeCareOrder(careOrderId: id, patientUuid: patientUuid);
      }
    }
    return buildSyncPayload(patientUuid);
  }

  // Only records the event and returns how many contacts would be notified —
  // dispatching to them is deliberately not automatic. iOS/Android don't let a
  // third-party app place calls or send texts without the person confirming, so the
  // real "dispatch" is Ally surfacing one-tap call/text buttons for a human to press
  // (see PanicAlertScreen), not a silent background send.
  static Future<int> handlePanic({required String patientUuid, required String triggerType, void Function(String patientUuid, String triggerType)? onPanic}) async {
    await DatabaseManager().insertPanicEvent(patientUuid: patientUuid, triggerType: triggerType);
    onPanic?.call(patientUuid, triggerType);
    final List<Map<String, dynamic>> targetRows = await DatabaseManager().getEmergencyTargetsForPatient(patientUuid);
    return targetRows.length;
  }
}
