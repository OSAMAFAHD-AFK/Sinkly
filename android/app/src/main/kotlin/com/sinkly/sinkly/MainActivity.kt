package com.sinkly.sinkly

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
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var screenTimeAccess: ScreenTimeAccessBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // "Screen Time" on Android: Display over other apps + Usage access.
        screenTimeAccess = ScreenTimeAccessBridge(this, flutterEngine.dartExecutor.binaryMessenger)
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
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }
}
