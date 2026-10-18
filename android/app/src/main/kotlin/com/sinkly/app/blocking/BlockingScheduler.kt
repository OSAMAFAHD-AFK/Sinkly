package com.sinkly.app.blocking

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.util.Log

/**
 * Keeps the blocker alive and on time, whoever wakes it: Flutter (a new
 * snapshot), a reboot, a time / time-zone change, the next-meal alarm or the
 * 15-minute watchdog. All of them just call [sync].
 */
object BlockingScheduler {
    private const val TAG = "SinklyBlocker"
    const val ACTION_WAKE = "com.sinkly.app.blocking.WAKE"
    const val ACTION_WATCHDOG = "com.sinkly.app.blocking.WATCHDOG"

    fun sync(context: Context) {
        val app = context.applicationContext
        val snapshot = BlockingStore(app).snapshot
        if (!snapshot.enabled) {
            cancel(app, ACTION_WAKE)
            cancel(app, ACTION_WATCHDOG)
            app.stopService(Intent(app, BlockingService::class.java))
            return
        }
        ensureRunning(app)
        val state = LockEngine.evaluate(snapshot, System.currentTimeMillis())
        scheduleWake(app, state.nextLockAtMs)
        scheduleWatchdog(app)
    }

    private fun ensureRunning(context: Context) {
        val intent = Intent(context, BlockingService::class.java)
        try {
            if (BlockingService.isRunning) {
                context.startService(intent) // just a poke: re-read the snapshot now
            } else {
                context.startForegroundService(intent)
            }
        } catch (error: Exception) {
            // Android may refuse a start from the background (e.g. an inexact
            // alarm). The next allowed wake-up — Sinkly opened, screen-on
            // reboot, exact alarm — starts it.
            Log.w(TAG, "Blocker start refused: $error")
        }
    }

    /** Wakes the phone at the next meal time, even in deep sleep. */
    private fun scheduleWake(context: Context, atMs: Long?) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = pendingIntent(context, ACTION_WAKE)
        if (atMs == null) {
            alarms.cancel(pending)
            return
        }
        try {
            val exactAllowed = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()
            if (exactAllowed) {
                alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMs, pending)
            } else {
                // Inexact may come a little late; the service still locks from the planned minute.
                alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMs, pending)
            }
        } catch (error: SecurityException) {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMs, pending)
        }
    }

    private fun scheduleWatchdog(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarms.setInexactRepeating(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + AlarmManager.INTERVAL_FIFTEEN_MINUTES,
            AlarmManager.INTERVAL_FIFTEEN_MINUTES,
            pendingIntent(context, ACTION_WATCHDOG),
        )
    }

    private fun cancel(context: Context, action: String) {
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pendingIntent(context, action))
    }

    private fun pendingIntent(context: Context, action: String): PendingIntent = PendingIntent.getBroadcast(
        context,
        action.hashCode(),
        Intent(context, BlockingReceiver::class.java).setAction(action),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}
