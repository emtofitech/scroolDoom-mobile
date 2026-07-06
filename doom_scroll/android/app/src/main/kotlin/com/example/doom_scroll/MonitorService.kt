package com.example.doom_scroll

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.Timer
import java.util.TimerTask

class MonitorService : Service() {

    private val TAG = "MonitorService"
    private var timer: Timer? = null
    private val tracked = mutableSetOf<String>()
    private var authToken: String = ""
    private var lastForeground: String? = null
    private var lastTrackedOpen: String? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Log.d(TAG, "Service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val packages = intent?.getStringExtra("trackedPackages") ?: ""
        val token = intent?.getStringExtra("authToken") ?: ""

        // Check if this is a lock/unlock command
        val lockAction = intent?.getStringExtra("lockAction")
        val lockPackage = intent?.getStringExtra("lockPackage")
        val lockLabel = intent?.getStringExtra("lockLabel")

        if (lockAction != null && lockPackage != null) {
            when (lockAction) {
                "lock" -> {
                    blockedApps.add(lockPackage)
                    blockedLabels[lockPackage] = lockLabel ?: lockPackage
                    Log.d(TAG, "🔒 Locked app: $lockPackage (${blockedApps.size} total)")
                    // If this app is currently in the foreground, block it immediately
                    val currentFg = detectForegroundApp()
                    if (currentFg == lockPackage) {
                        launchBlocker(lockPackage, lockLabel ?: lockPackage)
                    }
                }
                "unlock" -> {
                    blockedApps.remove(lockPackage)
                    blockedLabels.remove(lockPackage)
                    Log.d(TAG, "🔓 Unlocked app: $lockPackage (${blockedApps.size} total)")
                }
            }
            return START_REDELIVER_INTENT
        }

        // Normal start: update tracked packages and token
        if (packages.isNotBlank()) {
            tracked.clear()
            tracked.addAll(packages.split(",").filter { it.isNotBlank() })
            authToken = token

            val notification = buildNotification(
                if (tracked.isEmpty()) "No apps tracked"
                else "Monitoring ${tracked.size} app${if (tracked.size != 1) "s" else ""}"
            )
            startForeground(NOTIFICATION_ID, notification)

            timer?.cancel()
            timer = Timer()
            timer?.scheduleAtFixedRate(
                object : TimerTask() {
                    override fun run() = checkForeground()
                },
                0,
                POLL_MS
            )

            Log.d(TAG, "Service started — monitoring ${tracked.size} apps: $packages")
        }

        return START_REDELIVER_INTENT
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        timer?.cancel()
        timer = null
        Log.d(TAG, "Service destroyed")
        super.onDestroy()
    }

    // ── Foreground detection ────────────────────────────────────────────

    private fun checkForeground() {
        if (tracked.isEmpty()) return
        if (authToken.isBlank()) return

        val current = detectForegroundApp() ?: return

        // Check if the current foreground app is blocked.
        // Skip if it's DoomScroll itself or the blocker activity.
        if (current != OWN_PACKAGE &&
            current != "$OWN_PACKAGE.blocker" &&
            blockedApps.contains(current)
        ) {
            val label = blockedLabels[current] ?: current
            Log.d(TAG, "🔒 Blocked app in foreground: $current — launching blocker")
            launchBlocker(current, label)
        }

        if (current == lastForeground) return

        val wasTracked = lastForeground != null && tracked.contains(lastForeground)
        val isTracked = tracked.contains(current)

        Log.d(TAG, "Switch: $lastForeground → $current (was=$wasTracked, is=$isTracked)")

        if (wasTracked && lastTrackedOpen != null) {
            postEvent("app-close", lastTrackedOpen!!)
            lastTrackedOpen = null
        }

        if (isTracked) {
            lastTrackedOpen = current
            postEvent("app-open", current)
        }

        lastForeground = current
    }

    private fun detectForegroundApp(): String? {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val eventWindowMs = 60_000L
        val statsWindowMs = 300_000L

        val events = usm.queryEvents(now - eventWindowMs, now)
        var foreground: String? = null
        while (events.hasNextEvent()) {
            val e = UsageEvents.Event()
            events.getNextEvent(e)
            if (e.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
                 e.eventType == UsageEvents.Event.ACTIVITY_RESUMED)) {
                foreground = e.packageName
            }
        }
        if (foreground != null) return foreground

        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - statsWindowMs, now)
        if (stats != null && stats.isNotEmpty()) {
            return stats
                .sortedByDescending { it.lastTimeUsed }
                .firstOrNull()
                ?.packageName
        }
        return null
    }

    // ── App blocker ────────────────────────────────────────────────────

    private fun launchBlocker(packageName: String, appLabel: String) {
        try {
            val intent = Intent(this, AppBlockerActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra(AppBlockerActivity.EXTRA_APP_LABEL, appLabel)
                putExtra(AppBlockerActivity.EXTRA_PACKAGE_NAME, packageName)
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch blocker: ${e.message}")
        }
    }

    // ── API calls ───────────────────────────────────────────────────────

    private fun postEvent(endpoint: String, packageName: String) {
        try {
            val url = URL("$API_BASE/$endpoint")
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "POST"
            conn.setRequestProperty("Content-Type", "application/json")
            conn.setRequestProperty("Authorization", "Bearer $authToken")
            conn.doOutput = true
            conn.connectTimeout = 10_000
            conn.readTimeout = 10_000

            val body = """{"packageName":"$packageName"}"""
            OutputStreamWriter(conn.outputStream).use { it.write(body) }

            val code = conn.responseCode
            Log.d(TAG, "POST /$endpoint → $code (pkg=$packageName)")
            conn.disconnect()
        } catch (e: Exception) {
            Log.w(TAG, "POST /$endpoint failed: ${e.message}")
        }
    }

    // ── Notification ────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "App Monitoring",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "DoomScroll is monitoring your app usage"
                setShowBadge(false)
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(text: String): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        return builder
            .setContentTitle("DoomScroll")
            .setContentText(text)
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setPriority(Notification.PRIORITY_LOW)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "doomscroll_monitor"
        private const val NOTIFICATION_ID = 1001
        private const val POLL_MS = 5000L
        private const val API_BASE = "https://doomscroll-aotr.onrender.com/api/v1/usage"
        private const val OWN_PACKAGE = "com.example.doom_scroll"

        /** Set of currently blocked package names — shared across service restarts. */
        val blockedApps = mutableSetOf<String>()

        /** Friendly labels for blocked apps. */
        val blockedLabels = mutableMapOf<String, String>()
    }
}
