package com.example.triage

import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val lockScreenChannel = "com.example.triage/lock_screen"

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
