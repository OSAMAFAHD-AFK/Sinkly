package com.sinkly.app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import com.sinkly.app.blocking.BlockingPermissions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Android side of channel `sinkly/screen_time` (same contract as iOS).
 *
 * Android has no popup for app blocking. Sinkly needs two special accesses
 * that only exist as switches in Settings:
 *  • displayOverApps — SYSTEM_ALERT_WINDOW: draws the lock screen over apps.
 *  • usageAccess     — PACKAGE_USAGE_STATS: knows which app is in front.
 *
 *  • getAuthorizationStatus → {displayOverApps: Bool, usageAccess: Bool}
 *  • requestAuthorization   → opens the Settings page of the next missing
 *    access and answers (same map) when the user comes back to Sinkly.
 *    While Settings is open, the switch is watched: as soon as it flips on,
 *    Sinkly brings itself back to the front (Opal-style, best effort —
 *    Android may block it; returning with Back works either way).
 */
class ScreenTimeAccessBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val handler = Handler(Looper.getMainLooper())

    private var pendingResult: MethodChannel.Result? = null
    private var pendingRequirement: String? = null
    private var leftForSettings = false
    private var watchStartedAt = 0L

    init {
        channel.setMethodCallHandler(::onMethodCall)
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getAuthorizationStatus" -> result.success(status())
            "requestAuthorization" -> request(result)
            else -> result.notImplemented()
        }
    }

    private fun request(result: MethodChannel.Result) {
        val requirement = nextMissing() ?: return result.success(status())

        // A newer request wins; the older caller just gets the current status.
        pendingResult?.success(status())
        pendingResult = result
        pendingRequirement = requirement
        leftForSettings = false

        if (!openSettingsFor(requirement)) {
            finishPending()
            return
        }
        watchStartedAt = System.currentTimeMillis()
        handler.removeCallbacks(watcher)
        handler.postDelayed(watcher, WATCH_INTERVAL_MS)
    }

    // ── Activity lifecycle (forwarded by MainActivity) ───────────────────
    fun onPause() {
        if (pendingResult != null) leftForSettings = true
    }

    fun onResume() {
        if (pendingResult != null && leftForSettings) finishPending()
    }

    fun dispose() {
        handler.removeCallbacks(watcher)
        channel.setMethodCallHandler(null)
    }

    private fun finishPending() {
        handler.removeCallbacks(watcher)
        val result = pendingResult ?: return
        pendingResult = null
        pendingRequirement = null
        leftForSettings = false
        result.success(status())
    }

    // ── Watching the switch while the user is in Settings ────────────────
    private val watcher = object : Runnable {
        override fun run() {
            val requirement = pendingRequirement ?: return
            if (isGranted(requirement)) {
                bringSinklyToFront()
                return
            }
            if (System.currentTimeMillis() - watchStartedAt < WATCH_TIMEOUT_MS) {
                handler.postDelayed(this, WATCH_INTERVAL_MS)
            }
        }
    }

    private fun bringSinklyToFront() {
        try {
            activity.startActivity(
                Intent(activity, MainActivity::class.java).addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP,
                ),
            )
        } catch (_: Exception) {
            // Background-start blocked: onResume completes when the user returns.
        }
    }

    // ── Status ───────────────────────────────────────────────────────────
    private fun status(): Map<String, Boolean> = linkedMapOf(
        DISPLAY_OVER_APPS to canDrawOverlays(),
        USAGE_ACCESS to hasUsageAccess(),
    )

    /** Overlay first: its page opens right on Sinkly's switch, and once on it
     *  lets Sinkly come back to the front after the usage-access switch. */
    private fun nextMissing(): String? = when {
        !canDrawOverlays() -> DISPLAY_OVER_APPS
        !hasUsageAccess() -> USAGE_ACCESS
        else -> null
    }

    private fun isGranted(requirement: String) =
        if (requirement == DISPLAY_OVER_APPS) canDrawOverlays() else hasUsageAccess()

    private fun canDrawOverlays(): Boolean = BlockingPermissions.canDrawOverlays(activity)

    private fun hasUsageAccess(): Boolean = BlockingPermissions.hasUsageAccess(activity)

    // ── Settings pages ───────────────────────────────────────────────────
    private fun openSettingsFor(requirement: String): Boolean {
        val packageUri = Uri.parse("package:${activity.packageName}")
        val action = if (requirement == DISPLAY_OVER_APPS) {
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION
        } else {
            Settings.ACTION_USAGE_ACCESS_SETTINGS
        }
        // Sinkly's own page first (supported on most devices), then the list.
        return tryStart(Intent(action, packageUri)) ||
            tryStart(Intent(action)) ||
            tryStart(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageUri))
    }

    private fun tryStart(intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (_: ActivityNotFoundException) {
        false
    } catch (_: SecurityException) {
        false
    }

    companion object {
        const val CHANNEL = "sinkly/screen_time"
        private const val DISPLAY_OVER_APPS = "displayOverApps"
        private const val USAGE_ACCESS = "usageAccess"
        private const val WATCH_INTERVAL_MS = 400L
        private const val WATCH_TIMEOUT_MS = 3 * 60 * 1000L
    }
}
