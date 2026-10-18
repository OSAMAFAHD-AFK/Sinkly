package com.sinkly.app.blocking

import android.Manifest
import android.app.AppOpsManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings

/** The special accesses the blocker depends on (shared with ScreenTimeAccessBridge). */
object BlockingPermissions {
    const val USAGE_ACCESS = "usageAccess"
    const val DISPLAY_OVER_APPS = "displayOverApps"
    const val BATTERY_OPTIMIZATION = "batteryOptimization"

    /** "Display over other apps": draw the lock screen over a locked app. */
    fun canDrawOverlays(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)

    /** "Usage access": know which app just came to the front. */
    fun hasUsageAccess(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        }
        return if (mode == AppOpsManager.MODE_DEFAULT) {
            context.checkCallingOrSelfPermission(Manifest.permission.PACKAGE_USAGE_STATS) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            mode == AppOpsManager.MODE_ALLOWED
        }
    }

    /** Battery optimization may freeze the blocker (advice only). */
    fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return power.isIgnoringBatteryOptimizations(context.packageName)
    }

    fun missing(context: Context): List<String> = buildList {
        if (!hasUsageAccess(context)) add(USAGE_ACCESS)
        if (!canDrawOverlays(context)) add(DISPLAY_OVER_APPS)
        if (!isIgnoringBatteryOptimizations(context)) add(BATTERY_OPTIMIZATION)
    }
}
