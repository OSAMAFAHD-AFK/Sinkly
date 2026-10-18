package com.sinkly.app.blocking

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build

/**
 * Which app is in front, from the system's usage events ("Usage access").
 * Polled only while the apps are locked and the screen is on, so it costs
 * next to nothing in battery.
 */
class ForegroundAppTracker(context: Context) {
    private val usage = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    private var queriedUntil = 0L

    /** Last app that came to the front (stays until another one does). */
    var current: String? = null
        private set

    /** Starts over, looking [lookBackMs] into the past to find the app already open. */
    fun reset(lookBackMs: Long) {
        queriedUntil = System.currentTimeMillis() - lookBackMs
        current = null
    }

    fun poll(): String? {
        val now = System.currentTimeMillis()
        try {
            val events = usage.queryEvents(queriedUntil, now)
            val event = UsageEvents.Event()
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.eventType == RESUMED) current = event.packageName
            }
            // Small overlap so an event stamped on the boundary is never missed.
            queriedUntil = now - OVERLAP_MS
        } catch (_: Exception) {
            // Usage access withdrawn: status reports it, Flutter shows the banner.
        }
        return current
    }

    private companion object {
        const val OVERLAP_MS = 1_000L

        @Suppress("DEPRECATION")
        val RESUMED = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            UsageEvents.Event.ACTIVITY_RESUMED
        } else {
            UsageEvents.Event.MOVE_TO_FOREGROUND
        }
    }
}
