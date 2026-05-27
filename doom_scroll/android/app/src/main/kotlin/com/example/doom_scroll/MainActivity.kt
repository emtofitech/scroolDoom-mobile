package com.example.doom_scroll

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.doomscroll/usage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openUsageSettings" -> {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
