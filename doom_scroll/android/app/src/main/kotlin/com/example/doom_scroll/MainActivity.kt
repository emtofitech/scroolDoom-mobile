package com.example.doom_scroll

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.doomscroll/usage"
    private val TAG = "ForegroundDetector"

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
                    "getForegroundApp" -> {
                        try {
                            val out = HashMap<String, Any?>()
                            val granted = hasUsageStatsPermission()
                            out["granted"] = granted
                            if (granted) {
                                val fg = detectForegroundApp()
                                out["app"] = fg
                                Log.d(TAG, "Foreground app: $fg")
                            } else {
                                out["app"] = null
                                Log.w(TAG, "Usage stats permission not granted")
                            }
                            result.success(out)
                        } catch (ex: Exception) {
                            Log.e(TAG, "Error: ${ex.message}", ex)
                            result.error("FOREGROUND_ERROR", ex.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsageStatsPermission(): Boolean {
        return try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val now = System.currentTimeMillis()
            // Use a wider window so the query reliably returns something
            usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 60_000L, now)
            true
        } catch (_: SecurityException) {
            Log.w(TAG, "PACKAGE_USAGE_STATS permission not granted")
            false
        }
    }

    private fun detectForegroundApp(): String? {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val windowMs = 15000L

        // 1. Try queryEvents first (most precise)
        val events = usm.queryEvents(now - windowMs, now)
        var eventCount = 0
        var foreground: String? = null
        while (events.hasNextEvent()) {
            val e = UsageEvents.Event()
            events.getNextEvent(e)
            eventCount++
            if (e.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
                 e.eventType == UsageEvents.Event.ACTIVITY_RESUMED)) {
                foreground = e.packageName
                Log.d(TAG, "  FOREGROUND event: ${e.packageName}")
            }
        }
        Log.d(TAG, "queryEvents returned $eventCount events, foreground=$foreground")

        if (foreground != null) return foreground

        // 2. Fallback: queryUsageStats (more reliable across OEMs)
        Log.d(TAG, "queryEvents found no foreground — trying queryUsageStats")
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_BEST, now - windowMs, now)
        if (stats != null && stats.isNotEmpty()) {
            stats
                .sortedByDescending { it.lastTimeUsed }
                .forEach { Log.d(TAG, "  usage: ${it.packageName} lastUsed=${it.lastTimeUsed}") }
            return stats
                .sortedByDescending { it.lastTimeUsed }
                .firstOrNull()
                ?.packageName
        }

        Log.d(TAG, "queryUsageStats returned null or empty")
        return null
    }
}
