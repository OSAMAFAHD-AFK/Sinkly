package com.sinkly.app.blocking

import android.content.Context

/** The blocker's on-disk memory (survives Sinkly being closed and reboots). */
class BlockingStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    var snapshot: BlockingSnapshot
        get() = BlockingSnapshot.fromJson(prefs.getString(KEY_SNAPSHOT, null)) ?: BlockingSnapshot.DISABLED
        set(value) {
            prefs.edit().putString(KEY_SNAPSHOT, value.toJson()).apply()
        }

    /** A locked app the user tried to open, waiting for Flutter to show its lock screen. */
    fun setPendingLaunch(appId: String, appName: String, action: String) {
        prefs.edit()
            .putString(KEY_PENDING_ID, appId)
            .putString(KEY_PENDING_NAME, appName)
            .putString(KEY_PENDING_ACTION, action)
            .apply()
    }

    /** (appId, appName, action) waiting for Flutter, then cleared. */
    fun consumePendingLaunch(): Triple<String, String, String>? {
        val id = prefs.getString(KEY_PENDING_ID, null) ?: return null
        val name = prefs.getString(KEY_PENDING_NAME, "") ?: ""
        val action = prefs.getString(KEY_PENDING_ACTION, "overlay") ?: "overlay"
        prefs.edit().remove(KEY_PENDING_ID).remove(KEY_PENDING_NAME).remove(KEY_PENDING_ACTION).apply()
        return Triple(id, name, action)
    }

    companion object {
        private const val PREFS = "sinkly_blocking"
        private const val KEY_SNAPSHOT = "snapshot"
        private const val KEY_PENDING_ID = "pending_app_id"
        private const val KEY_PENDING_NAME = "pending_app_name"
        private const val KEY_PENDING_ACTION = "pending_action"
    }
}
