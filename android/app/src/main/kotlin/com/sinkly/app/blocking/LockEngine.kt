package com.sinkly.app.blocking

import java.time.Instant
import java.time.ZoneId
import java.time.ZonedDateTime

/** Result of [LockEngine.evaluate]. */
data class LockState(val locked: Boolean, val lockedSinceMs: Long?, val nextLockAtMs: Long?)

/**
 * THE lock rule — the same as Dart's `LockStatusModel.evaluate` and Swift's
 * `SinklyLockEngine`, checked against the same cases
 * (`test/fixtures/lock_engine_vectors.json`, see LockEngineTest):
 *
 *  • A lock starts when a planned meal ends (or "Test the lock now").
 *  • It lasts until a clean-sink photo — no expiry.
 *  • Only meals that end after locking became active count.
 *  • Meal times are the phone's wall clock in its current time zone, built
 *    from clock fields, so 18:00 stays 18:00 on daylight-saving days.
 *
 * It is a pure function of (snapshot, now, zone): every wake-up recomputes
 * the truth, so a late alarm can never move a 19:00 lock — at worst the
 * lock is *noticed* a moment later and still counts from 19:00.
 */
object LockEngine {
    /** The plan repeats weekly: the latest past meal is within 7 days. */
    private const val LOOK_BACK_DAYS = 8L

    fun evaluate(snapshot: BlockingSnapshot, nowMs: Long, zone: ZoneId = ZoneId.systemDefault()): LockState {
        val now = Instant.ofEpochMilli(nowMs).atZone(zone)
        var latest: Long? = triggersBetween(snapshot.days, now.minusDays(LOOK_BACK_DAYS), now, zone).lastOrNull()

        val manual = snapshot.manualLockAtMs
        if (manual != null && manual <= nowMs && (latest == null || manual > latest)) latest = manual

        val activeSince = if (snapshot.enabled) snapshot.activeSinceMs else null
        val lastClean = snapshot.lastCleanAtMs
        val anchor = activeSince?.let { active -> if (lastClean != null && lastClean > active) lastClean else active }

        val locked = anchor != null && latest != null && latest > anchor
        val next = triggersBetween(snapshot.days, now.plusSeconds(1), now.plusDays(LOOK_BACK_DAYS), zone).firstOrNull()
        return LockState(locked = locked, lockedSinceMs = if (locked) latest else null, nextLockAtMs = next)
    }

    /**
     * Which meal started the lock at [lockedSinceMs]: "breakfast" / "lunch" /
     * "dinner", or null for "Test the lock now" (or an unknown time).
     */
    fun mealOf(snapshot: BlockingSnapshot, lockedSinceMs: Long?, zone: ZoneId = ZoneId.systemDefault()): String? {
        if (lockedSinceMs == null || lockedSinceMs == snapshot.manualLockAtMs) return null
        val at = Instant.ofEpochMilli(lockedSinceMs).atZone(zone)
        val day = at.dayOfWeek.value
        val minutes = at.hour * 60 + at.minute
        val index = snapshot.days[day]?.indexOf(minutes) ?: -1
        return snapshot.mealTypes[day]?.getOrNull(index)
    }

    /** Every meal end (epoch ms) inside [from, to], oldest first. */
    fun triggersBetween(days: Map<Int, List<Int>>, from: ZonedDateTime, to: ZonedDateTime, zone: ZoneId): List<Long> {
        val result = ArrayList<Long>()
        var day = from.toLocalDate()
        val lastDay = to.toLocalDate()
        while (!day.isAfter(lastDay)) {
            days[day.dayOfWeek.value]?.forEach { minutes ->
                // atZone resolves a skipped time (spring forward) to the first valid instant after it.
                val at = day.atTime(minutes / 60, minutes % 60).atZone(zone)
                if (!at.isBefore(from) && !at.isAfter(to)) result.add(at.toInstant().toEpochMilli())
            }
            day = day.plusDays(1)
        }
        result.sort()
        return result
    }
}
