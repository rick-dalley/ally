package com.example.ally

import android.os.Build
import android.view.WindowManager
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), MessageClient.OnMessageReceivedListener {
    private val lockScreenChannel = "com.example.ally/lock_screen"

    // Wear OS Data Layer bridge — the phone-side counterpart of wear_os's own
    // MainActivity.kt. See that file's doc comment for why this is hand-written
    // rather than a published plugin; the two are otherwise identical.
    private val dataLayerChannel = "com.cwicare/wear_data_layer"
    private val dataLayerEvents = "com.cwicare/wear_data_layer/messages"
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, lockScreenChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setShowOverLockScreen" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        setShowOverLockScreen(enabled)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, dataLayerChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendMessage" -> {
                        val path = call.argument<String>("path")!!
                        val payload = call.argument<String>("payload") ?: ""
                        sendToAllNodes(path, payload)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, dataLayerEvents)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    override fun onResume() {
        super.onResume()
        Wearable.getMessageClient(this).addListener(this)
    }

    override fun onPause() {
        Wearable.getMessageClient(this).removeListener(this)
        super.onPause()
    }

    override fun onMessageReceived(event: MessageEvent) {
        val payload = String(event.data, Charsets.UTF_8)
        runOnUiThread {
            eventSink?.success(mapOf("path" to event.path, "payload" to payload))
        }
    }

    private fun sendToAllNodes(path: String, payload: String) {
        val messageClient = Wearable.getMessageClient(this)
        Wearable.getNodeClient(this).connectedNodes.addOnSuccessListener { nodes ->
            for (node in nodes) {
                messageClient.sendMessage(node.id, path, payload.toByteArray(Charsets.UTF_8))
            }
        }
    }

    // Same window behavior alarm and incoming-call apps use to be visible without
    // unlocking the device: draws this Activity over the keyguard without dismissing
    // it, so backing out returns to the lock screen, not the home screen underneath.
    private fun setShowOverLockScreen(enabled: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(enabled)
            setTurnScreenOn(enabled)
        } else {
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            if (enabled) {
                window.addFlags(flags)
            } else {
                window.clearFlags(flags)
            }
        }
    }
}
