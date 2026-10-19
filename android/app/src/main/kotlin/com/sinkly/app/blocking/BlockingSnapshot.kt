package com.sinkly.app.blocking

import org.json.JSONArray
import org.json.JSONObject

/**
 * Everything the blocker needs, sent by Flutter (`AppBlockingRepo`) over
 * channel `sinkly/app_blocking` whenever something changes, and kept on disk
 * so it keeps working while Sinkly is closed or after a reboot.
 *
 * Instants are UTC epoch milliseconds; meal times are the phone's local wall
 * clock: ISO weekday (1 = Monday … 7 = Sunday) → minutes after midnight.
 */
data class BlockingSnapshot(
    val enabled: Boolean,
    val activeSinceMs: Long?,
    val lastCleanAtMs: Long?,
    val manualLockAtMs: Long?,
    /** Settings "Reminders" switch; off = minimized service notification. */
    val remindersEnabled: Boolean = true,
    val days: Map<Int, List<Int>>,
    /** Same shape as [days]: "breakfast" / "lunch" / "dinner" for each time. */
    val mealTypes: Map<Int, List<String>> = emptyMap(),
    val blockedPackages: Set<String>,
    val blockedCategories: Set<String>,
    val strings: Map<String, String>,
    val languageCode: String,
) {
    fun text(key: String, fallback: String): String = strings[key]?.takeIf { it.isNotBlank() } ?: fallback

    val isRtl: Boolean get() = languageCode == "ar"

    fun toJson(): String = JSONObject().apply {
        put("enabled", enabled)
        putOpt("activeSinceMs", activeSinceMs)
        putOpt("lastCleanAtMs", lastCleanAtMs)
        putOpt("manualLockAtMs", manualLockAtMs)
        put("remindersEnabled", remindersEnabled)
        put("days", JSONObject().apply { days.forEach { (day, minutes) -> put("$day", JSONArray(minutes)) } })
        put("mealTypes", JSONObject().apply { mealTypes.forEach { (day, types) -> put("$day", JSONArray(types)) } })
        put("blockedPackages", JSONArray(blockedPackages.toList()))
        put("blockedCategories", JSONArray(blockedCategories.toList()))
        put("strings", JSONObject(strings as Map<*, *>))
        put("languageCode", languageCode)
    }.toString()

    companion object {
        val DISABLED = BlockingSnapshot(
            enabled = false,
            activeSinceMs = null,
            lastCleanAtMs = null,
            manualLockAtMs = null,
            days = emptyMap(),
            blockedPackages = emptySet(),
            blockedCategories = emptySet(),
            strings = emptyMap(),
            languageCode = "en",
        )

        /** From the Flutter channel map (`BlockingSnapshotModel.toChannel`). */
        fun fromChannel(map: Map<*, *>): BlockingSnapshot = BlockingSnapshot(
            enabled = map["enabled"] == true,
            activeSinceMs = (map["activeSinceMs"] as? Number)?.toLong(),
            lastCleanAtMs = (map["lastCleanAtMs"] as? Number)?.toLong(),
            manualLockAtMs = (map["manualLockAtMs"] as? Number)?.toLong(),
            remindersEnabled = map["remindersEnabled"] != false,
            days = (map["days"] as? Map<*, *>).orEmpty().mapNotNull { (key, value) ->
                val day = key.toString().toIntOrNull() ?: return@mapNotNull null
                day to (value as? List<*>).orEmpty().mapNotNull { (it as? Number)?.toInt() }
            }.toMap(),
            mealTypes = (map["mealTypes"] as? Map<*, *>).orEmpty().mapNotNull { (key, value) ->
                val day = key.toString().toIntOrNull() ?: return@mapNotNull null
                day to (value as? List<*>).orEmpty().map { it.toString() }
            }.toMap(),
            blockedPackages = (map["blockedPackages"] as? List<*>).orEmpty().map { it.toString() }.toSet(),
            blockedCategories = (map["blockedCategories"] as? List<*>).orEmpty().map { it.toString() }.toSet(),
            strings = (map["strings"] as? Map<*, *>).orEmpty().entries.associate { it.key.toString() to it.value.toString() },
            languageCode = map["languageCode"]?.toString() ?: "en",
        )

        fun fromJson(json: String?): BlockingSnapshot? = try {
            if (json.isNullOrBlank()) null else parse(JSONObject(json))
        } catch (_: Exception) {
            null
        }

        private fun parse(json: JSONObject): BlockingSnapshot {
            fun optLong(key: String): Long? = if (json.has(key) && !json.isNull(key)) json.getLong(key) else null
            val days = json.optJSONObject("days")
            val mealTypes = json.optJSONObject("mealTypes")
            val strings = json.optJSONObject("strings")
            return BlockingSnapshot(
                enabled = json.optBoolean("enabled", false),
                activeSinceMs = optLong("activeSinceMs"),
                lastCleanAtMs = optLong("lastCleanAtMs"),
                manualLockAtMs = optLong("manualLockAtMs"),
                remindersEnabled = json.optBoolean("remindersEnabled", true),
                days = days?.keys()?.asSequence()?.mapNotNull { key ->
                    val day = key.toIntOrNull() ?: return@mapNotNull null
                    val minutes = days.getJSONArray(key)
                    day to (0 until minutes.length()).map { minutes.getInt(it) }
                }?.toMap().orEmpty(),
                mealTypes = mealTypes?.keys()?.asSequence()?.mapNotNull { key ->
                    val day = key.toIntOrNull() ?: return@mapNotNull null
                    val types = mealTypes.getJSONArray(key)
                    day to (0 until types.length()).map { types.getString(it) }
                }?.toMap().orEmpty(),
                blockedPackages = json.optJSONArray("blockedPackages").toStringSet(),
                blockedCategories = json.optJSONArray("blockedCategories").toStringSet(),
                strings = strings?.keys()?.asSequence()?.associateWith { strings.getString(it) }.orEmpty(),
                languageCode = json.optString("languageCode", "en"),
            )
        }

        private fun JSONArray?.toStringSet(): Set<String> =
            if (this == null) emptySet() else (0 until length()).map { getString(it) }.toSet()
    }
}
