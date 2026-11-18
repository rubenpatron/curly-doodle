package com.habitos.cleanstep.core.notification

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.concurrent.TimeUnit

class NotificationSchedulerTest {

    @Test
    fun `calculateInitialDelayMillis when current time is before 4_30 PM schedules for same day`() {
        // Given current time is 10:00:00 AM today
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 10)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val nowMillis = calendar.timeInMillis

        // When calculating delay for 4:30 PM (16:30)
        val delay = NotificationScheduler.calculateInitialDelayMillis(
            targetHour = 16,
            targetMinute = 30,
            nowMillis = nowMillis
        )

        // Then expected delay is 6 hours and 30 minutes
        val expectedDelay = TimeUnit.HOURS.toMillis(6) + TimeUnit.MINUTES.toMillis(30)
        assertEquals(expectedDelay, delay)
    }

    @Test
    fun `calculateInitialDelayMillis when current time is after 4_30 PM schedules for next day`() {
        // Given current time is 5:00:00 PM (17:00) today
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 17)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val nowMillis = calendar.timeInMillis

        // When calculating delay for 4:30 PM (16:30)
        val delay = NotificationScheduler.calculateInitialDelayMillis(
            targetHour = 16,
            targetMinute = 30,
            nowMillis = nowMillis
        )

        // Then expected delay is 23 hours and 30 minutes (tomorrow at 16:30)
        val expectedDelay = TimeUnit.HOURS.toMillis(23) + TimeUnit.MINUTES.toMillis(30)
        assertEquals(expectedDelay, delay)
    }

    @Test
    fun `calculateInitialDelayMillis for 10_00 PM when current time is 8_00 PM schedules for same day`() {
        // Given current time is 8:00:00 PM (20:00) today
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 20)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val nowMillis = calendar.timeInMillis

        // When calculating delay for 10:00 PM (22:00)
        val delay = NotificationScheduler.calculateInitialDelayMillis(
            targetHour = 22,
            targetMinute = 0,
            nowMillis = nowMillis
        )

        // Then expected delay is exactly 2 hours
        val expectedDelay = TimeUnit.HOURS.toMillis(2)
        assertEquals(expectedDelay, delay)
    }

    @Test
    fun `calculateInitialDelayMillis for 10_00 PM when current time is 10_15 PM schedules for next day`() {
        // Given current time is 10:15:00 PM (22:15) today
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 22)
            set(Calendar.MINUTE, 15)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val nowMillis = calendar.timeInMillis

        // When calculating delay for 10:00 PM (22:00)
        val delay = NotificationScheduler.calculateInitialDelayMillis(
            targetHour = 22,
            targetMinute = 0,
            nowMillis = nowMillis
        )

        // Then expected delay is 23 hours and 45 minutes
        val expectedDelay = TimeUnit.HOURS.toMillis(23) + TimeUnit.MINUTES.toMillis(45)
        assertEquals(expectedDelay, delay)
    }

    @Test
    fun `calculateInitialDelayMillis at exact target minute schedules for next day 24 hours later`() {
        // Given current time is exactly 16:30:00.000
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 16)
            set(Calendar.MINUTE, 30)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val nowMillis = calendar.timeInMillis

        val delay = NotificationScheduler.calculateInitialDelayMillis(
            targetHour = 16,
            targetMinute = 30,
            nowMillis = nowMillis
        )

        // Target should be 24 hours in the future
        val expectedDelay = TimeUnit.HOURS.toMillis(24)
        assertEquals(expectedDelay, delay)
    }

    @Test
    fun `verify notification copy matches behavioral science requirements`() {
        assertEquals(
            "¿Sed o antojo? Tómate un vaso de agua o prepara tu agua mineral con limón. ¡Tu racha limpia continúa!",
            NotificationHelper.DEFAULT_MID_AFTERNOON_BODY
        )
        assertEquals(
            "Son las 10:00 PM. Tu rutina de 15 min de descompresión y movilidad te espera antes de dormir.",
            NotificationHelper.DEFAULT_NIGHT_ROUTINE_BODY
        )
    }

    @Test
    fun `verify worker target hours and tags`() {
        assertEquals(16, MidAfternoonReminderWorker.TARGET_HOUR)
        assertEquals(30, MidAfternoonReminderWorker.TARGET_MINUTE)
        assertEquals(22, NightRoutineReminderWorker.TARGET_HOUR)
        assertEquals(0, NightRoutineReminderWorker.TARGET_MINUTE)

        assertTrue(NotificationHelper.CHANNEL_ID_MID_AFTERNOON.isNotEmpty())
        assertTrue(NotificationHelper.CHANNEL_ID_NIGHT_ROUTINE.isNotEmpty())
        assertEquals("destination_cravings", NotificationHelper.DESTINATION_CRAVINGS)
        assertEquals("destination_night_routine", NotificationHelper.DESTINATION_NIGHT_ROUTINE)
    }
}
