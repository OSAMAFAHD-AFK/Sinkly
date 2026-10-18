package com.sinkly.app.blocking

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.os.Build
import android.util.TypedValue
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.sinkly.app.R

/**
 * Sinkly's lock screen over a locked app — a static, branded card, the same
 * on Android and iPhone (iOS shows it as Apple's shield: same heroine, texts
 * and colours). It appears in the same instant the app opens, so the app is
 * never visible. "Clean my sink" opens Sinkly on its full lock screen (the
 * Flutter LockOverlay); Back and "Go to home screen" leave to the home screen.
 * Main thread only.
 */
class LockCoverOverlay(private val context: Context) {
    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var root: View? = null
    private var shownFor: String? = null

    val isShowing: Boolean get() = root != null

    fun show(snapshot: BlockingSnapshot, appId: String, appName: String, onOpen: () -> Unit, onHome: () -> Unit) {
        if (!BlockingPermissions.canDrawOverlays(context)) return
        if (root != null && shownFor == appId) return
        hide()
        val view = build(snapshot, appName, onOpen, onHome)
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            // Focusable on purpose: the Back key must reach this screen, not the locked app.
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            PixelFormat.TRANSLUCENT,
        )
        try {
            windowManager.addView(view, params)
            root = view
            shownFor = appId
            view.requestFocus()
        } catch (_: Exception) {
            root = null
            shownFor = null
        }
    }

    fun hide() {
        val view = root ?: return
        root = null
        shownFor = null
        try {
            windowManager.removeView(view)
        } catch (_: Exception) {
            // Already gone.
        }
    }

    // ── Layout ───────────────────────────────────────────────────────────
    private fun build(snapshot: BlockingSnapshot, appName: String, onOpen: () -> Unit, onHome: () -> Unit): View {
        val fonts = LockFonts(context, snapshot.languageCode)
        val name = appName.ifBlank { snapshot.text("appsGeneric", "Your apps") }

        val rootLayout = object : FrameLayout(context) {
            override fun dispatchKeyEvent(event: KeyEvent): Boolean {
                if (event.keyCode == KeyEvent.KEYCODE_BACK) {
                    if (event.action == KeyEvent.ACTION_UP) onHome()
                    return true
                }
                return super.dispatchKeyEvent(event)
            }
        }.apply {
            // MeshPalette.warm: peach → sky.
            background = GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM, intArrayOf(PEACH, PEACH_LIGHT, SKY_WASH))
            layoutDirection = if (snapshot.isRtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR
            textDirection = if (snapshot.isRtl) View.TEXT_DIRECTION_RTL else View.TEXT_DIRECTION_LTR
            isFocusable = true
            isFocusableInTouchMode = true
            isClickable = true // swallow every touch: nothing reaches the locked app
        }

        val column = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(22), dp(48), dp(22), dp(32))
        }

        val chip = TextView(context).apply {
            text = snapshot.text("lockChip", "{app} · paused").replace("{app}", name)
            fonts.apply(this, 13f, 700, FLAME)
            setPadding(dp(14), dp(7), dp(14), dp(7))
            background = rounded(CHIP_FILL, dp(100).toFloat())
        }

        val heroine = ImageView(context).apply {
            setImageResource(R.drawable.lock_heroine)
            adjustViewBounds = true
            scaleType = ImageView.ScaleType.FIT_CENTER
        }

        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(24), dp(26), dp(24), dp(18))
            background = rounded(CARD_FILL, dp(28).toFloat()).apply { setStroke(dp(1), CARD_STROKE) }
            elevation = dp(10).toFloat()
        }

        val title = TextView(context).apply {
            text = snapshot.text("lockTitle", "Your sink's turn!")
            fonts.apply(this, 25f, 800, INK, height = 1.2f)
            gravity = Gravity.CENTER
        }

        val subtitle = TextView(context).apply {
            text = snapshot.text(
                "lockSubtitle",
                "This app is taking a short break. One photo of a clean sink brings everything back.",
            )
            fonts.apply(this, 15f, 400, INK_SOFT, height = 1.45f)
            gravity = Gravity.CENTER
        }

        val cta = TextView(context).apply {
            text = snapshot.text("lockCta", "Clean my sink")
            fonts.apply(this, 16f, 700, ON_PRIMARY)
            gravity = Gravity.CENTER
            minHeight = dp(56)
            setPadding(dp(20), dp(14), dp(20), dp(14))
            val fill = GradientDrawable(GradientDrawable.Orientation.TL_BR, PRIMARY_GRADIENT)
                .apply { cornerRadius = dp(100).toFloat() }
            background = RippleDrawable(ColorStateList.valueOf(Color.parseColor("#33FFFFFF")), fill, null)
            elevation = dp(6).toFloat()
            isClickable = true
            setOnClickListener { onOpen() }
        }

        val home = TextView(context).apply {
            text = snapshot.text("lockHome", "Go to home screen")
            fonts.apply(this, 14f, 700, PRIMARY_INK)
            gravity = Gravity.CENTER
            setPadding(dp(12), dp(14), dp(12), dp(6))
            isClickable = true
            setOnClickListener { onHome() }
        }

        card.addView(title, matchWrap())
        card.addView(subtitle, matchWrap().apply { topMargin = dp(10) })
        card.addView(cta, matchWrap().apply { topMargin = dp(22) })
        card.addView(home, matchWrap())

        column.addView(chip, LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        column.addView(heroine, LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, 0, 1f).apply {
            topMargin = dp(12)
            bottomMargin = dp(12)
        })
        column.addView(card, matchWrap())

        rootLayout.addView(column, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        return rootLayout
    }

    // ── Helpers ──────────────────────────────────────────────────────────
    private fun rounded(color: Int, radius: Float) = GradientDrawable().apply {
        setColor(color)
        cornerRadius = radius
    }

    private fun matchWrap() = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)

    private fun dp(value: Int): Int =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value.toFloat(), context.resources.displayMetrics).toInt()

    private companion object {
        // Design tokens from lib/core/utils/style.dart (same values as the iOS shield).
        val PRIMARY_GRADIENT = intArrayOf(0xFFA6DCF5.toInt(), 0xFF89CFF0.toInt(), 0xFF74C3EC.toInt())
        const val PRIMARY_INK = 0xFF2B8BC6.toInt()
        const val ON_PRIMARY = 0xFF0B2540.toInt()
        const val INK = 0xFF0F1B2D.toInt()
        const val INK_SOFT = 0xFF5B6B80.toInt()
        const val FLAME = 0xFFFF8A3D.toInt()
        const val CHIP_FILL = 0xFFFFF4E0.toInt()
        const val CARD_FILL = 0xE6FFFFFF.toInt()
        const val CARD_STROKE = 0x99FFFFFF.toInt()
        const val PEACH = 0xFFFFEEE3.toInt()
        const val PEACH_LIGHT = 0xFFFFF7F0.toInt()
        const val SKY_WASH = 0xFFD6EFFC.toInt()

        init {
            check(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) // TYPE_APPLICATION_OVERLAY
        }
    }
}

/**
 * The app's fonts: Cairo (Arabic) / Plus Jakarta Sans. google_fonts stores
 * the files it downloaded in the app's files folder; the lock screen loads the
 * very same files, so the text looks like in Flutter.
 */
class LockFonts(private val context: Context, languageCode: String) {
    private val family = if (languageCode == "ar") "Cairo" else "PlusJakartaSans"
    private val isArabic = languageCode == "ar"
    private val cache = HashMap<Int, Typeface>()

    private fun weight(weight: Int): Typeface = cache.getOrPut(weight) { load(weight) }

    private fun load(weight: Int): Typeface {
        val name = "$family-${WEIGHT_NAMES[weight] ?: "Regular"}"
        try {
            context.filesDir.listFiles()
                ?.firstOrNull { it.name.startsWith("${name}_") && (it.name.endsWith(".ttf") || it.name.endsWith(".otf")) }
                ?.let { return Typeface.createFromFile(it) }
            // Fonts bundled later as assets (google_fonts' "assets/google_fonts" folder).
            val asset = "flutter_assets/assets/google_fonts/$name.ttf"
            context.assets.open(asset).close()
            return Typeface.createFromAsset(context.assets, asset)
        } catch (_: Exception) {
            // Not downloaded yet (first launch offline): the system font.
        }
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            Typeface.create(Typeface.SANS_SERIF, weight, false)
        } else {
            Typeface.create(Typeface.SANS_SERIF, if (weight >= 600) Typeface.BOLD else Typeface.NORMAL)
        }
    }

    /** Size in dp (text scale clamped to 1.3 like the app), weight, colour, line height factor. */
    fun apply(view: TextView, size: Float, weight: Int, color: Int, height: Float = 1.3f) {
        val metrics = context.resources.displayMetrics
        val scale = context.resources.configuration.fontScale.coerceAtMost(1.3f)
        val px = size * metrics.density * scale
        view.typeface = weight(weight)
        view.setTextSize(TypedValue.COMPLEX_UNIT_PX, px)
        view.setTextColor(color)
        view.includeFontPadding = false
        val lineHeight = px * (if (isArabic) height * 1.08f else height)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            view.lineHeight = lineHeight.toInt()
        } else {
            view.setLineSpacing(lineHeight - view.paint.fontMetrics.let { it.descent - it.ascent }, 1f)
        }
    }

    private companion object {
        val WEIGHT_NAMES = mapOf(400 to "Regular", 500 to "Medium", 600 to "SemiBold", 700 to "Bold", 800 to "ExtraBold")
    }
}
