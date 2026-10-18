package com.sinkly.app.blocking

import android.content.Context
import android.content.Intent
import android.provider.MediaStore
import android.provider.Settings

/**
 * Apps that are NEVER locked, whatever the user picked (a whole category
 * like "Other" or "Utilities" could otherwise include them):
 *  • Sinkly itself and the home screen,
 *  • the camera — Sinkly opens it to photograph the sink; locking it would
 *    make unlocking impossible,
 *  • phone / emergency calls, Settings, permission and install screens.
 */
class ProtectedApps(private val context: Context) {
    private var cached: Set<String> = emptySet()
    private var computedAt = 0L

    fun contains(packageName: String): Boolean {
        val now = System.currentTimeMillis()
        if (cached.isEmpty() || now - computedAt > REFRESH_MS) {
            cached = compute()
            computedAt = now
        }
        return packageName in cached
    }

    /** Default home screen(s) — leaving to home must never be blocked. */
    fun launchers(): Set<String> = resolve(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME))

    private fun compute(): Set<String> = buildSet {
        add(context.packageName)
        addAll(FIXED)
        addAll(launchers())
        addAll(resolve(Intent(Intent.ACTION_DIAL)))
        addAll(resolve(Intent(MediaStore.ACTION_IMAGE_CAPTURE)))
        addAll(resolve(Intent(MediaStore.INTENT_ACTION_STILL_IMAGE_CAMERA)))
        addAll(resolve(Intent(Settings.ACTION_SETTINGS)))
    }

    private fun resolve(intent: Intent): Set<String> = try {
        context.packageManager.queryIntentActivities(intent, 0).mapNotNull { it.activityInfo?.packageName }.toSet()
    } catch (_: Exception) {
        emptySet()
    }

    companion object {
        private const val REFRESH_MS = 10 * 60 * 1000L

        private val FIXED = setOf(
            "android",
            "com.android.systemui",
            "com.android.settings",
            "com.android.phone",
            "com.android.server.telecom",
            "com.android.emergency",
            "com.google.android.apps.safetyhub",
            "com.android.permissioncontroller",
            "com.google.android.permissioncontroller",
            "com.android.packageinstaller",
            "com.google.android.packageinstaller",
        )
    }
}
