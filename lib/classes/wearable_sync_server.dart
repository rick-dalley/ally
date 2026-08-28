import 'dart:convert';
import 'dart:io';

import '../widgets/emergency_qr.dart';
import 'alertable.dart';
import 'database_manager.dart';
import 'patient.dart';

// The Linux wearable prototype isn't on Apple's or Google's watch-companion
// frameworks (WatchConnectivity / the Wearable Data Layer API), so it can't piggyback
// on their phone<->watch sync — it's a separate physical device on the same local
// network. A small plain HTTP server (dart:io, no framework — three fixed endpoints
// don't need shelf's routing) is the simplest real transport for a same-network
// prototype: the watch is manually pointed at Ally's LAN IP (no service discovery
// yet, deliberately, to keep this a v1). Real BLE pairing is future work once actual
// hardware is settled.
class WearableSyncServer {
  static const int port = 8787;
  HttpServer? _server;

  // Lets main.dart push a full-screen alert the instant a panic event lands, whether
  // Ally happens to be sitting on the roster or anywhere else — the server has no UI
  // of its own, so it hands off rather than trying to navigate anything itself.
  final void Function(String patientUuid, String triggerType)? onPanic;

  WearableSyncServer({this.onPanic});

  Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen(_handle);
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handle(HttpRequest request) async {
    request.response.headers.contentType = ContentType.json;
    try {
      if (request.method == 'GET' && request.uri.path == '/wearable/sync') {
        await _handleSync(request);
      } else if (request.method == 'POST' && request.uri.path == '/wearable/ack') {
        await _handleAck(request);
      } else if (request.method == 'POST' && request.uri.path == '/wearable/ack_all') {
        await _handleAckAll(request);
      } else if (request.method == 'POST' && request.uri.path == '/wearable/panic') {
        await _handlePanic(request);
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
    } catch (error) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(jsonEncode({'error': error.toString()}));
    }
    await request.response.close();
  }

  Future<void> _handleSync(HttpRequest request) async {
    final String? patientUuid = request.uri.queryParameters['patient'];
    if (patientUuid == null) {
      request.response.statusCode = HttpStatus.badRequest;
      return;
    }
    request.response.write(jsonEncode(await _buildSyncPayload(patientUuid)));
  }

  Future<void> _handleAck(HttpRequest request) async {
    final Map<String, dynamic> body = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
    final String patientUuid = body['patientUuid'] as String;
    final String type = body['type'] as String;
    final String id = body['id'] as String;
    final db = DatabaseManager();
    if (type == 'medication') {
      await db.logMedicationDose(medicationId: id, patientUuid: patientUuid, scheduledFor: DateTime.now(), status: 'taken');
    } else if (type == 'careOrder') {
      await db.acknowledgeCareOrder(careOrderId: id, patientUuid: patientUuid);
    }
    request.response.write(jsonEncode(await _buildSyncPayload(patientUuid)));
  }

  Future<void> _handleAckAll(HttpRequest request) async {
    final Map<String, dynamic> body = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
    final String patientUuid = body['patientUuid'] as String;
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
    request.response.write(jsonEncode(await _buildSyncPayload(patientUuid)));
  }

  // Only records the event and hands off to onPanic — sending anything to the
  // emergency targets is deliberately not automatic. iOS/Android don't let a
  // third-party app place calls or send texts without the person confirming, so the
  // real "dispatch" is Ally surfacing one-tap call/text buttons for a human to press,
  // not a silent background send (see PanicAlertScreen).
  Future<void> _handlePanic(HttpRequest request) async {
    final Map<String, dynamic> body = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
    final String patientUuid = body['patientUuid'] as String;
    final String triggerType = body['trigger'] as String;
    await DatabaseManager().insertPanicEvent(patientUuid: patientUuid, triggerType: triggerType);
    onPanic?.call(patientUuid, triggerType);
    final List<Map<String, dynamic>> targetRows = await DatabaseManager().getEmergencyTargetsForPatient(patientUuid);
    request.response.write(jsonEncode({'notified': targetRows.length}));
  }

  Future<Map<String, dynamic>> _buildSyncPayload(String patientUuid) async {
    final List<Map<String, dynamic>> rows = await DatabaseManager().getPatientWithVitals(patientUuid: patientUuid);
    if (rows.isEmpty) return {'error': 'patient not found'};
    final Patient patient = Patient.fromJson(rows.first);
    final Map<String, dynamic> emergencyPayload = await EmergencyQRCodeView.buildEmergencyPayload(patient);
    final Map<String, dynamic> due = await DatabaseManager().getWearableDueItems(patientUuid);
    final Map<String, dynamic> settingsRow = await DatabaseManager().getOrCreateWearableSettings(patientUuid);
    final List<WearableAlertConfig> alerts = alertConfigsFromRow(settingsRow);
    return {
      'emergencyQr': emergencyPayload,
      ...due,
      'alerts': {for (final a in alerts) a.trigger.name: a.enabled},
    };
  }
}
