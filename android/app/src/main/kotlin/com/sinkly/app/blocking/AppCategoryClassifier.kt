package com.sinkly.app.blocking

import android.content.pm.PackageManager
import android.os.Build

/**
 * Same grouping as Dart's `AppCategory.fromAndroid` (ids match `AppCategory.id`),
 * so a blocked category also covers apps installed after the plan was saved:
 * an app is classified the moment it comes to the front.
 * The known-package list is generated from lib/core/models/app_category_model.dart.
 */
object AppCategoryClassifier {
    private val cache = HashMap<String, String>()

    fun categoryOf(pm: PackageManager, packageName: String): String = synchronized(cache) {
        cache.getOrPut(packageName) { classify(pm, packageName) }
    }

    private fun classify(pm: PackageManager, packageName: String): String {
        KNOWN[packageName]?.let { return it }
        val category = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) pm.getApplicationInfo(packageName, 0).category else -1
        } catch (_: Exception) {
            -1
        }
        return when (category) {
            0 -> "games"
            1, 2 -> "entertainment"
            3 -> "creativity"
            4 -> "social"
            5 -> "reading"
            6 -> "travel"
            7 -> "productivity"
            8 -> "utilities"
            else -> guess(packageName)
        }
    }

    private fun guess(packageName: String): String {
        val name = packageName.lowercase()
        if (name.contains("game") || name.contains(".games.") || name.contains("supercell") || name.contains("king.")) {
            return "games"
        }
        if (name.contains("calculator") || name.contains("clock") || name.contains("camera") || name.contains("files")) {
            return "utilities"
        }
        return "other"
    }

    private val KNOWN: Map<String, String> = mapOf(
        "com.zhiliaoapp.musically" to "social",
        "com.ss.android.ugc.trill" to "social",
        "com.instagram.android" to "social",
        "com.instagram.barcelona" to "social",
        "com.twitter.android" to "social",
        "com.snapchat.android" to "social",
        "com.facebook.katana" to "social",
        "com.facebook.lite" to "social",
        "com.facebook.orca" to "social",
        "com.whatsapp" to "social",
        "com.whatsapp.w4b" to "social",
        "org.telegram.messenger" to "social",
        "com.reddit.frontpage" to "social",
        "com.pinterest" to "social",
        "com.discord" to "social",
        "com.linkedin.android" to "social",
        "com.google.android.youtube" to "entertainment",
        "tv.twitch.android.app" to "entertainment",
        "com.netflix.mediaclient" to "entertainment",
        "com.spotify.music" to "entertainment",
        "com.amazon.avod.thirdpartyclient" to "entertainment",
        "com.disney.disneyplus" to "entertainment",
        "com.anghami" to "entertainment",
        "com.shahid.app" to "entertainment",
        "com.amazon.mShop.android.shopping" to "shopping_food",
        "com.talabat" to "shopping_food",
        "com.noon.buyerapp" to "shopping_food",
        "com.alibaba.aliexpresshd" to "shopping_food",
        "com.einnovation.temu" to "shopping_food",
        "com.zzkko" to "shopping_food",
        "com.ubercab.eats" to "shopping_food",
        "com.duolingo" to "education",
        "com.google.android.apps.classroom" to "education",
        "com.ubercab" to "travel",
        "com.booking" to "travel",
        "com.airbnb.android" to "travel",
        "com.google.android.apps.fitness" to "health",
        "com.strava" to "health",
        "com.amazon.kindle" to "reading",
        "com.google.android.apps.magazines" to "reading",
        "com.canva.editor" to "creativity",
        "com.adobe.lrmobile" to "creativity",
        "com.google.android.calculator" to "utilities",
        "com.android.chrome" to "utilities",
        "com.google.android.gm" to "productivity",
        "com.microsoft.office.outlook" to "productivity",
    )
}
