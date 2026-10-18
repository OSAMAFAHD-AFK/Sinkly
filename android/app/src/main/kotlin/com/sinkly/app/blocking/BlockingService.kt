package com.sinkly.app.blocking

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.text.format.DateFormat
import android.util.Log
import com.sinkly.app.MainActivity
import com.sinkly.app.R
import java.util.Date

/**
 * The Android blocker. A foreground service (it shows a small ongoing
 * notification, as Android requires) that stays alive while locking is on:
 *
 *  • Unlocked: sleeps until the next meal time (re-checked at least every
 *    15 s while the screen is on, and on every screen-on), so the lock starts
 *    at the planned minute — 19:00 means 19:00.
 *  • Locked: every 0.5 s (screen on only) checks which app is in front; a
 *    locked app gets Sinkly's lock cover at once, then Sinkly's own lock screen.
 *
 * Every tick asks [LockEngine] for the truth, so plan edits, a clean photo,
 * a time-zone change or a late wake-up are always applied correctly.
 */
class BlockingService : Service() {
    private lateinit var store: BlockingStore
    private lateinit var tracker: ForegroundAppTracker
    private lateinit var protectedApps: ProtectedApps
    private lateinit var cover: LockCoverOverlay
    private lateinit var worker: HandlerThread
    private lateinit var work: Handler
    private val main = Handler(Looper.getMainLooper())

    private var wasLocked = false
    private var handledForeground: String? = null
    private var notificationKey: String? = null
    @Volatile private var screenOn = true

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            screenOn = intent.action != Intent.ACTION_SCREEN_OFF
            poke()
        }
    }

    private val tick = Runnable { runTick() }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        store = BlockingStore(this)
        tracker = ForegroundAppTracker(this)
        protectedApps = ProtectedApps(this)
        cover = LockCoverOverlay(this)
        worker = HandlerThread("sinkly-blocker").apply { start() }
        work = Handler(worker.looper)
        screenOn = (getSystemService(Context.POWER_SERVICE) as PowerManager).isInteractive
        createChannel(store.snapshot)
        startInForeground(buildNotification(store.snapshot, null))
        registerReceiver(screenReceiver, IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        })
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startInForeground(buildNotification(store.snapshot, null))
        notificationKey = null
        poke()
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        BlockingScheduler.sync(applicationContext)
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        isRunning = false
        try {
            unregisterReceiver(screenReceiver)
        } catch (_: Exception) {
        }
        work.removeCallbacksAndMessages(null)
        worker.quitSafely()
        cover.hide()
        super.onDestroy()
    }

    private fun poke() {
        if (!::work.isInitialized) return
        work.removeCallbacks(tick)
        work.post(tick)
    }

    private fun runTick() {
        val snapshot = store.snapshot
        if (!snapshot.enabled) {
            main.post { cover.hide() }
            stopSelf()
            return
        }
        val now = System.currentTimeMillis()
        val state = LockEngine.evaluate(snapshot, now)
        updateNotification(snapshot, state)

        if (state.locked) {
            if (!wasLocked) {
                tracker.reset(lookBackMs = 60 * 60 * 1000L)
                handledForeground = null
                wasLocked = true
            }
            if (screenOn) {
                handleForeground(snapshot, tracker.poll())
                work.postDelayed(tick, LOCKED_POLL_MS)
            } else {
                work.postDelayed(tick, SCREEN_OFF_CHECK_MS)
            }
        } else {
            if (wasLocked) {
                wasLocked = false
                handledForeground = null
                main.post { cover.hide() }
            }
            val untilNext = state.nextLockAtMs?.minus(now) ?: Long.MAX_VALUE
            val cap = if (screenOn) IDLE_POLL_MS else SCREEN_OFF_CHECK_MS
            work.postDelayed(tick, untilNext.coerceIn(MIN_DELAY_MS, cap))
        }
    }

    private fun handleForeground(snapshot: BlockingSnapshot, foreground: String?) {
        if (foreground == null) return
        val locked = foreground != packageName && !protectedApps.contains(foreground) && isBlocked(snapshot, foreground)
        if (!locked) {
            handledForeground = foreground
            main.post { cover.hide() }
            return
        }
        if (foreground == handledForeground && cover.isShowing) return
        handledForeground = foreground
        val label = labelOf(foreground)
        main.post {
            cover.show(
                snapshot,
                foreground,
                label,
                onOpen = { openSinkly(foreground, label) },
                onHome = { goHome() },
            )
        }
    }

    private fun isBlocked(snapshot: BlockingSnapshot, packageName: String): Boolean =
        packageName in snapshot.blockedPackages ||
            (snapshot.blockedCategories.isNotEmpty() &&
                AppCategoryClassifier.categoryOf(packageManager, packageName) in snapshot.blockedCategories)

    private fun labelOf(packageName: String): String = try {
        packageManager.getApplicationLabel(packageManager.getApplicationInfo(packageName, 0)).toString()
    } catch (_: Exception) {
        ""
    }

    private fun openSinkly(appId: String, appName: String) {
        store.setPendingLaunch(appId, appName, ACTION_OVERLAY)
        try {
            startActivity(MainActivity.lockIntent(this, appId, appName, ACTION_OVERLAY))
        } catch (error: Exception) {
            Log.w(TAG, "Could not open Sinkly from the lock screen: $error")
        }
    }

    private fun goHome() {
        cover.hide()
        try {
            startActivity(
                Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
        } catch (_: Exception) {
        }
    }

    private fun startInForeground(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun createChannel(snapshot: BlockingSnapshot) {
        val channel = NotificationChannel(
            CHANNEL_ID,
            snapshot.text("serviceChannel", "Plan protection"),
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            setShowBadge(false)
            enableVibration(false)
            setSound(null, null)
        }
        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(channel)
    }

    private fun updateNotification(snapshot: BlockingSnapshot, state: LockState) {
        val key = "${state.locked}|${state.nextLockAtMs}|${snapshot.languageCode}|${snapshot.strings.hashCode()}"
        if (key == notificationKey) return
        notificationKey = key
        createChannel(snapshot)
        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
            .notify(NOTIFICATION_ID, buildNotification(snapshot, state))
    }

    private fun buildNotification(snapshot: BlockingSnapshot, state: LockState?): Notification {
        val title = if (state?.locked == true) {
            snapshot.text("serviceLocked", "Apps locked · clean your sink to unlock")
        } else {
            snapshot.text("serviceActive", "Sinkly is keeping your plan")
        }
        val next = state?.nextLockAtMs
        val text = when {
            state == null || state.locked -> null
            next != null -> snapshot.text("serviceNext", "Next lock at {time}")
                .replace("{time}", westernDigits(DateFormat.getTimeFormat(this).format(Date(next))))
            else -> snapshot.text("serviceIdle", "No lock planned")
        }
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        
        // تصحيح بناء الإشعار بإزالة الـ apply لتجنب مشاكل الـ Type Inference
        val builder = Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_sinkly)
            .setContentTitle(title)
            .setContentIntent(open)
            .setOngoing(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setColor(0xFF89CFF0.toInt())

        if (text != null) {
            builder.setContentText(text)
        }

        return builder.build()
    }

    /** Clock times always use 0-9 (same rule as the Flutter side): "٣:٠٠ م" → "3:00 م". */
    private fun westernDigits(text: String): String = buildString(text.length) {
        for (char in text) {
            append(
                when (char) {
                    in '٠'..'٩' -> '0' + (char - '٠')
                    in '۰'..'۹' -> '0' + (char - '۰')
                    else -> char
                },
            )
        }
    }

    companion object {
        private const val TAG = "SinklyBlocker"

        const val ACTION_OVERLAY = "overlay"
        const val NOTIFICATION_ID = 4242
        private const val CHANNEL_ID = "sinkly_protection"
        private const val LOCKED_POLL_MS = 500L
        private const val IDLE_POLL_MS = 15_000L
        private const val SCREEN_OFF_CHECK_MS = 60_000L
        private const val MIN_DELAY_MS = 200L

        @Volatile
        var isRunning = false
            private set
    }
}