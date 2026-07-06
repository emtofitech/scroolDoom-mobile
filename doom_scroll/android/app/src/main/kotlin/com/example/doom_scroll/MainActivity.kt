package com.example.doom_scroll

import android.Manifest
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.doomscroll/usage"
    private val TAG = "ForegroundDetector"
    private var notificationPermissionRequested = false

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
                    "checkOverlayPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            result.success(Settings.canDrawOverlays(this@MainActivity))
                        } else {
                            result.success(true)
                        }
                    }
                    "openOverlaySettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, android.net.Uri.parse("package:$packageName"))
                            startActivity(intent)
                        }
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
                    "startMonitorService" -> {
                        try {
                            requestNotificationPermissionIfNeeded()
                            val packages = call.argument<String>("packages") ?: ""
                            val token = call.argument<String>("token") ?: ""
                            val intent = Intent(this, MonitorService::class.java).apply {
                                putExtra("trackedPackages", packages)
                                putExtra("authToken", token)
                            }
                            ContextCompat.startForegroundService(this, intent)
                            Log.d(TAG, "MonitorService started (${packages.split(",").size} apps)")
                            result.success(true)
                        } catch (ex: Exception) {
                            Log.e(TAG, "Failed to start service: ${ex.message}", ex)
                            result.error("SERVICE_ERROR", ex.message, null)
                        }
                    }
                    "stopMonitorService" -> {
                        try {
                            stopService(Intent(this@MainActivity, MonitorService::class.java))
                            result.success(true)
                        } catch (ex: Exception) {
                            result.error("SERVICE_ERROR", ex.message, null)
                        }
                    }
                    "bringToForeground" -> {
                        val intent = Intent(this@MainActivity, MainActivity::class.java).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                        }
                        startActivity(intent)
                        result.success(true)
                    }

                    // ── App lock/unlock via native MonitorService ──────────────
                    "lockApp" -> {
                        try {
                            val packageName = call.argument<String>("packageName") ?: ""
                            val appLabel = call.argument<String>("appLabel") ?: packageName
                            if (packageName.isBlank()) {
                                result.error("INVALID_ARG", "packageName is required", null)
                                return@setMethodCallHandler
                            }
                            // Update the MonitorService's blocked set
                            MonitorService.blockedApps.add(packageName)
                            MonitorService.blockedLabels[packageName] = appLabel
                            Log.d(TAG, "🔒 lockApp: $packageName ($appLabel)")

                            // Also send to MonitorService via Intent so it can
                            // trigger an immediate check
                            val intent = Intent(this, MonitorService::class.java).apply {
                                putExtra("lockAction", "lock")
                                putExtra("lockPackage", packageName)
                                putExtra("lockLabel", appLabel)
                            }
                            ContextCompat.startForegroundService(this, intent)

                            result.success(true)
                        } catch (ex: Exception) {
                            Log.e(TAG, "lockApp error: ${ex.message}", ex)
                            result.error("LOCK_ERROR", ex.message, null)
                        }
                    }
                    "unlockApp" -> {
                        try {
                            val packageName = call.argument<String>("packageName") ?: ""
                            if (packageName.isBlank()) {
                                result.error("INVALID_ARG", "packageName is required", null)
                                return@setMethodCallHandler
                            }
                            MonitorService.blockedApps.remove(packageName)
                            MonitorService.blockedLabels.remove(packageName)
                            Log.d(TAG, "🔓 unlockApp: $packageName")

                            val intent = Intent(this, MonitorService::class.java).apply {
                                putExtra("lockAction", "unlock")
                                putExtra("lockPackage", packageName)
                            }
                            ContextCompat.startForegroundService(this, intent)

                            result.success(true)
                        } catch (ex: Exception) {
                            Log.e(TAG, "unlockApp error: ${ex.message}", ex)
                            result.error("UNLOCK_ERROR", ex.message, null)
                        }
                    }
                    "getBlockedApps" -> {
                        result.success(MonitorService.blockedApps.toList())
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            !notificationPermissionRequested
        ) {
            notificationPermissionRequested = true
            if (ContextCompat.checkSelfPermission(
                    this, Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                requestPermissions(
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_REQUEST_CODE
                )
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
        val eventWindowMs = 60_000L
        val statsWindowMs = 300_000L

        // 1. Try queryEvents first (most precise)
        val events = usm.queryEvents(now - eventWindowMs, now)
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

        // 2. Fallback: queryUsageStats with a wide window (more reliable across OEMs)
        Log.d(TAG, "queryEvents found no foreground — trying queryUsageStats")
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - statsWindowMs, now)
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

    companion object {
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 9001
    }
}
