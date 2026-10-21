package com.sinkly.app

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.sinkly.app.blocking.AppBlockingBridge
import com.sinkly.app.blocking.BlockingScheduler
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

// FlutterFragmentActivity: required by RevenueCat UI (Customer Center).
class MainActivity : FlutterFragmentActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var screenTimeAccess: ScreenTimeAccessBridge? = null
    private var appBlocking: AppBlockingBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // "Screen Time" on Android: Display over other apps + Usage access.
        screenTimeAccess = ScreenTimeAccessBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        // The app blocker (blocking/): plan snapshot in, lock-screen requests out.
        appBlocking = AppBlockingBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        // Make sure the blocker runs whenever Sinkly is opened (e.g. after a force stop).
        BlockingScheduler.sync(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sinkly/installed_apps")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstalledApps" -> {
                        val iconSize = call.argument<Int>("iconSize") ?: 96
                        // Reading labels + icons takes a moment: stay off the UI thread.
                        worker.execute {
                            try {
                                val apps = readLauncherApps(iconSize)
                                mainHandler.post { result.success(apps) }
                            } catch (error: Exception) {
                                mainHandler.post { result.error("APPS_UNAVAILABLE", error.message, null) }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Every app with a launcher icon (what the user sees on the home screen).
     * Visible on Android 11+ thanks to the MAIN/LAUNCHER `<queries>` entry in
     * the manifest — no QUERY_ALL_PACKAGES permission needed.
     */
    private fun readLauncherApps(iconSize: Int): List<Map<String, Any?>> {
        val pm = packageManager
        val launcherIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val activities = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(launcherIntent, PackageManager.ResolveInfoFlags.of(0L))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(launcherIntent, 0)
        }

        val seen = HashSet<String>()
        val apps = ArrayList<Map<String, Any?>>()
        for (info in activities) {
            val appInfo = info.activityInfo?.applicationInfo ?: continue
            val packageName = appInfo.packageName
            if (packageName == this.packageName || !seen.add(packageName)) continue

            val category = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) appInfo.category else -1
            val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0 &&
                (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) == 0

            apps.add(
                mapOf(
                    "packageName" to packageName,
                    "name" to info.loadLabel(pm).toString(),
                    "category" to category,
                    "isSystem" to isSystem,
                    "icon" to encodeIcon(info.loadIcon(pm), iconSize),
                ),
            )
        }
        return apps
    }

    private fun encodeIcon(drawable: Drawable, size: Int): ByteArray? = try {
        val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
            Bitmap.createScaledBitmap(drawable.bitmap, size, size, true)
        } else {
            // Adaptive / vector icons: draw into a bitmap.
            Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888).also { bitmap ->
                val canvas = Canvas(bitmap)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
            }
        }
        ByteArrayOutputStream().use { stream ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        }
    } catch (_: Exception) {
        null
    }

    /** The blocker opened Sinkly over a locked app while Flutter is running. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val appId = intent.getStringExtra(EXTRA_LOCKED_APP_ID) ?: return
        appBlocking?.deliverLockRequest(
            appId,
            intent.getStringExtra(EXTRA_LOCKED_APP_NAME) ?: "",
            intent.getStringExtra(EXTRA_ACTION) ?: "overlay",
        )
    }

    override fun onResume() {
        super.onResume()
        screenTimeAccess?.onResume()
    }

    override fun onPause() {
        screenTimeAccess?.onPause()
        super.onPause()
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        screenTimeAccess?.dispose()
        screenTimeAccess = null
        appBlocking?.dispose()
        appBlocking = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }

    companion object {
        private const val EXTRA_LOCKED_APP_ID = "sinkly.lockedAppId"
        private const val EXTRA_LOCKED_APP_NAME = "sinkly.lockedAppName"
        private const val EXTRA_ACTION = "sinkly.lockAction"

        /** Opens (or brings back) Sinkly on its full lock screen ([action]:
         *  "overlay"). A cold start reads the same request from
         *  BlockingStore (consumeLaunchAction). */
        fun lockIntent(context: Context, appId: String, appName: String, action: String): Intent =
            Intent(context, MainActivity::class.java)
                .addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
                )
                .putExtra(EXTRA_LOCKED_APP_ID, appId)
                .putExtra(EXTRA_LOCKED_APP_NAME, appName)
                .putExtra(EXTRA_ACTION, action)
    }
}
