import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'wearable_sync_logic.dart';

// The phone-side half of the Wear OS transport — receives a request over the
// Wearable Data Layer API (native bridge in MainActivity.kt), runs the exact same
// business logic WearableSyncServer's HTTP handlers use, and sends the JSON result
// straight back over the same channel. Paths mirror the HTTP routes one-for-one
// (see wearable_sync_server.dart) so the two transports stay easy to reason about
// side by side.
class WearableDataLayerBridge {
  static const MethodChannel _channel = MethodChannel('com.cwicare/wear_data_layer');
  static const EventChannel _events = EventChannel('com.cwicare/wear_data_layer/messages');

  final void Function(String patientUuid, String triggerType)? onPanic;
  StreamSubscription<dynamic>? _subscription;

  WearableDataLayerBridge({this.onPanic});

  void start() {
    _subscription ??= _events.receiveBroadcastStream().listen(_onMessage);
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _onMessage(dynamic event) async {
    final Map<dynamic, dynamic> message = event as Map<dynamic, dynamic>;
    final String path = message['path'] as String;
    final String payload = message['payload'] as String;

    switch (path) {
      case '/wearable/sync/request':
        final String patientUuid = payload;
        await _reply('/wearable/sync/response', await WearableSyncLogic.buildSyncPayload(patientUuid));
        break;
      case '/wearable/ack':
        final Map<String, dynamic> body = jsonDecode(payload) as Map<String, dynamic>;
        final result = await WearableSyncLogic.handleAck(patientUuid: body['patientUuid'] as String, type: body['type'] as String, id: body['id'] as String);
        await _reply('/wearable/sync/response', result);
        break;
      case '/wearable/ack_all':
        final Map<String, dynamic> body = jsonDecode(payload) as Map<String, dynamic>;
        final result = await WearableSyncLogic.handleAckAll(body['patientUuid'] as String);
        await _reply('/wearable/sync/response', result);
        break;
      case '/wearable/panic':
        final Map<String, dynamic> body = jsonDecode(payload) as Map<String, dynamic>;
        final int notified = await WearableSyncLogic.handlePanic(patientUuid: body['patientUuid'] as String, triggerType: body['trigger'] as String, onPanic: onPanic);
        await _reply('/wearable/panic/response', {'notified': notified});
        break;
      case '/wearable/set_mood':
        final Map<String, dynamic> body = jsonDecode(payload) as Map<String, dynamic>;
        final result = await WearableSyncLogic.handleSetMood(patientUuid: body['patientUuid'] as String, moodIndex: body['moodIndex'] as int);
        await _reply('/wearable/sync/response', result);
        break;
    }
  }

  Future<void> _reply(String path, Map<String, dynamic> body) async {
    await _channel.invokeMethod('sendMessage', {'path': path, 'payload': jsonEncode(body)});
  }
}
