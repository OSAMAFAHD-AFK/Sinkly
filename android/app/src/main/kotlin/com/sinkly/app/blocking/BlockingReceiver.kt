package com.sinkly.app.blocking

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restarts / re-times the blocker after a reboot, an app update, a clock or
 * time-zone change (travel, daylight saving), the next-meal alarm and the
 * watchdog. The decision itself is always [LockEngine]'s.
 */
class BlockingReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        BlockingScheduler.sync(context)
    }
}
