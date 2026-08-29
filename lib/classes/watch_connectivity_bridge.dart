import 'dart:convert';

import 'package:flutter/services.dart';

import 'wearable_sync_logic.dart';

// The phone-side half of the Apple Watch transport — WatchConnectivity's
// sendMessage/replyHandler API already has real request/response semantics built in
// (unlike the Wearable Data Layer API, which is one-way messaging and needed the
// manual response-path matching in wearable_data_layer_bridge.dart), so this is
// simpler: the native side (WatchConnectivityBridge.swift) just calls invokeMethod
// and returns whatever this handler returns, straight back to the watch as the reply.
class WatchConnectivityBridge {
  static const MethodChannel _channel = MethodChannel('com.cwicare/watch_connectivity');

  final void Function(String patientUuid, String triggerType)? onPanic;

  WatchConnectivityBridge({this.onPanic});

  void start() {
    _channel.setMethodCallHandler(_handle);
  }

  Future<String> _handle(MethodCall call) async {
    switch (call.method) {
      case 'sync':
        final String patientUuid = call.arguments as String;
        return jsonEncode(await WearableSyncLogic.buildSyncPayload(patientUuid));
      case 'ack':
        final Map<String, dynamic> body = jsonDecode(call.arguments as String) as Map<String, dynamic>;
        final result = await WearableSyncLogic.handleAck(patientUuid: body['patientUuid'] as String, type: body['type'] as String, id: body['id'] as String);
        return jsonEncode(result);
      case 'ackAll':
        final Map<String, dynamic> body = jsonDecode(call.arguments as String) as Map<String, dynamic>;
        final result = await WearableSyncLogic.handleAckAll(body['patientUuid'] as String);
        return jsonEncode(result);
      case 'panic':
        final Map<String, dynamic> body = jsonDecode(call.arguments as String) as Map<String, dynamic>;
        final int notified = await WearableSyncLogic.handlePanic(patientUuid: body['patientUuid'] as String, triggerType: body['trigger'] as String, onPanic: onPanic);
        return jsonEncode({'notified': notified});
      case 'setMood':
        final Map<String, dynamic> body = jsonDecode(call.arguments as String) as Map<String, dynamic>;
        final result = await WearableSyncLogic.handleSetMood(patientUuid: body['patientUuid'] as String, moodIndex: body['moodIndex'] as int);
        return jsonEncode(result);
      default:
        throw MissingPluginException('Unknown watch connectivity method: ${call.method}');
    }
  }
}
