package com.sinkly.app.blocking

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Android side of channel `sinkly/app_blocking` (same contract as iOS):
 *  • apply(snapshot)        → stores it, (re)starts or stops the blocker → status
 *  • getStatus              → {enabled, isLocked, lockedSinceMs, nextLockAtMs, missing[]}
 *  • consumeLaunchAction    → {appId, appName, action} from a lock-screen button, or null
 *  • leaveToHomeScreen      → home screen (Back on the lock screen)
 *  • openBatterySettings    → battery-optimization settings
 *  • (native → Dart) openLockOverlay {appId, appName, action: overlay}
 */
class AppBlockingBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, CHANNEL)
    private val store = BlockingStore(activity)

    init {
        channel.setMethodCallHandler(::onMethodCall)
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "apply" -> {
                val map = call.arguments as? Map<*, *>
                if (map == null) {
                    result.error("BAD_SNAPSHOT", "apply expects a map", null)
                    return
                }
                store.snapshot = BlockingSnapshot.fromChannel(map)
                BlockingScheduler.sync(activity)
                result.success(status())
            }
            "getStatus" -> result.success(status())
            "consumeLaunchAction" -> result.success(
                store.consumePendingLaunch()?.let { (id, name, action) ->
                    mapOf("appId" to id, "appName" to name, "action" to action)
                },
            )
            "leaveToHomeScreen" -> {
                tryStart(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                result.success(null)
            }
            "openBatterySettings" -> {
                tryStart(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)) ||
                    tryStart(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${activity.packageName}")))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** A lock-screen button while Flutter runs: open the matching screen now. */
    fun deliverLockRequest(appId: String, appName: String, action: String) {
        store.consumePendingLaunch() // handled here, not again at the next cold start
        channel.invokeMethod("openLockOverlay", mapOf("appId" to appId, "appName" to appName, "action" to action))
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun status(): Map<String, Any?> {
        val snapshot = store.snapshot
        val state = LockEngine.evaluate(snapshot, System.currentTimeMillis())
        return mapOf(
            "enabled" to snapshot.enabled,
            "isLocked" to state.locked,
            "lockedSinceMs" to state.lockedSinceMs,
            "nextLockAtMs" to state.nextLockAtMs,
            "missing" to if (snapshot.enabled) BlockingPermissions.missing(activity) else emptyList(),
        )
    }

    private fun tryStart(intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (_: Exception) {
        false
    }

    companion object {
        const val CHANNEL = "sinkly/app_blocking"
    }
}
