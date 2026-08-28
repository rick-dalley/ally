import 'dart:convert';
import 'dart:io';

import 'wearable_sync_logic.dart';

// The Linux wearable prototype isn't on Apple's or Google's watch-companion
// frameworks (WatchConnectivity / the Wearable Data Layer API), so it can't piggyback
// on their phone<->watch sync — it's a separate physical device on the same local
// network. A small plain HTTP server (dart:io, no framework — three fixed endpoints
// don't need shelf's routing) is the simplest real transport for a same-network
// prototype: the watch is manually pointed at Ally's LAN IP (no service discovery
// yet, deliberately, to keep this a v1). See wearable_sync_logic.dart for the actual
// business logic, shared with the Wear OS Data Layer transport.
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
    request.response.write(jsonEncode(await WearableSyncLogic.buildSyncPayload(patientUuid)));
  }

  Future<void> _handleAck(HttpRequest request) async {
    final Map<String, dynamic> body = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
    final result = await WearableSyncLogic.handleAck(patientUuid: body['patientUuid'] as String, type: body['type'] as String, id: body['id'] as String);
    request.response.write(jsonEncode(result));
  }

  Future<void> _handleAckAll(HttpRequest request) async {
    final Map<String, dynamic> body = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
    final result = await WearableSyncLogic.handleAckAll(body['patientUuid'] as String);
    request.response.write(jsonEncode(result));
  }

  Future<void> _handlePanic(HttpRequest request) async {
    final Map<String, dynamic> body = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
    final int notified = await WearableSyncLogic.handlePanic(patientUuid: body['patientUuid'] as String, triggerType: body['trigger'] as String, onPanic: onPanic);
    request.response.write(jsonEncode({'notified': notified}));
  }
}
