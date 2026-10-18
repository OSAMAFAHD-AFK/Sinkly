package com.sinkly.app.blocking

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.File
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime

/**
 * The Kotlin side of the shared lock-rule cases: the very same JSON file as
 * Dart's test/lock_engine_vectors_test.dart (and Swift's tests).
 */
class LockEngineTest {
    private val vectors: JSONObject by lazy {
        // Gradle runs unit tests from android/app.
        val file = listOf("../../test/fixtures/lock_engine_vectors.json", "test/fixtures/lock_engine_vectors.json")
            .map(::File).first { it.exists() }
        JSONObject(file.readText())
    }

    /** Wall-clock cases: any zone without daylight saving gives the same answers. */
    private val zone: ZoneId = ZoneId.of("UTC")

    private fun ms(value: Any?): Long? =
        if (value == null || value == JSONObject.NULL) null
        else LocalDateTime.parse(value as String).atZone(zone).toInstant().toEpochMilli()

    @Test
    fun sharedCases() {
        val cases = vectors.getJSONArray("cases")
        for (i in 0 until cases.length()) {
            val case = cases.getJSONObject(i)
            val days = case.getJSONObject("days")
            val snapshot = BlockingSnapshot.DISABLED.copy(
                enabled = true,
                activeSinceMs = ms(case.opt("activeSince")),
                lastCleanAtMs = ms(case.opt("lastCleanAt")),
                manualLockAtMs = ms(case.opt("manualLockAt")),
                days = days.keys().asSequence().associate { key ->
                    val minutes = days.getJSONArray(key)
                    key.toInt() to (0 until minutes.length()).map { minutes.getInt(it) }
                },
            )
            val state = LockEngine.evaluate(snapshot, ms(case.getString("now"))!!, zone)
            val expect = case.getJSONObject("expect")
            val name = case.getString("name")
            assertEquals("$name · locked", expect.getBoolean("locked"), state.locked)
            assertEquals("$name · lockedSince", ms(expect.opt("lockedSince")), state.lockedSinceMs)
            assertEquals("$name · nextLockAt", ms(expect.opt("nextLockAt")), state.nextLockAtMs)
        }
    }

    @Test
    fun dinnerStaysAtSixOnDaylightSavingDays() {
        val london = ZoneId.of("Europe/London")
        val days = (1..7).associateWith { listOf(18 * 60) }
        // 29 March 2026: clocks jump 01:00 → 02:00 in London (a 23-hour day).
        val from = ZonedDateTime.of(2026, 3, 29, 0, 0, 0, 0, london)
        val trigger = LockEngine.triggersBetween(days, from, from.plusHours(23), london).single()
        val local = java.time.Instant.ofEpochMilli(trigger).atZone(london)
        assertEquals(18, local.hour)
        assertEquals(0, local.minute)
        // 25 October 2026: clocks go back 02:00 → 01:00 (a 25-hour day).
        val autumn = ZonedDateTime.of(2026, 10, 25, 0, 0, 0, 0, london)
        val autumnTrigger = LockEngine.triggersBetween(days, autumn, autumn.plusHours(25), london).single()
        assertEquals(18, java.time.Instant.ofEpochMilli(autumnTrigger).atZone(london).hour)
    }

    @Test
    fun followsThePhonesTimeZone() {
        // Dinner at 18:00 means 18:00 where the phone is: Riyadh and London differ by 3 h in winter.
        val days = (1..7).associateWith { listOf(18 * 60) }
        val riyadh = ZoneId.of("Asia/Riyadh")
        val london = ZoneId.of("Europe/London")
        val nowMs = ZonedDateTime.of(2026, 12, 1, 12, 0, 0, 0, riyadh).toInstant().toEpochMilli()
        val snapshot = BlockingSnapshot.DISABLED.copy(enabled = true, activeSinceMs = 0, days = days)
        val inRiyadh = LockEngine.evaluate(snapshot, nowMs, riyadh).nextLockAtMs!!
        val inLondon = LockEngine.evaluate(snapshot, nowMs, london).nextLockAtMs!!
        assertEquals(18, java.time.Instant.ofEpochMilli(inRiyadh).atZone(riyadh).hour)
        assertEquals(18, java.time.Instant.ofEpochMilli(inLondon).atZone(london).hour)
        assertEquals(3 * 60 * 60 * 1000L, inLondon - inRiyadh)
    }

    @Test
    fun snapshotSurvivesDisk() {
        val snapshot = BlockingSnapshot.DISABLED.copy(
            enabled = true,
            activeSinceMs = 1_000L,
            days = mapOf(1 to listOf(570, 1260)),
            blockedPackages = setOf("com.instagram.android"),
            blockedCategories = setOf("social"),
            strings = mapOf("lockTitle" to "حان دور الحوض!"),
            languageCode = "ar",
        )
        assertEquals(snapshot, BlockingSnapshot.fromJson(snapshot.toJson()))
    }
}
