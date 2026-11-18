package com.habitos.cleanstep.core.notification

import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.Calendar
import java.util.concurrent.TimeUnit

/**
 * Manages scheduling of background reminders using AndroidX WorkManager.
 * Ensures reminders are fired daily at specific target times:
 * - 4:30 PM (16:30): Mid-Afternoon dopamine drop & craving rescue
 * - 10:00 PM (22:00): Nocturnal low-impact mobility & decompression routine
 */
object NotificationScheduler {

    /**
     * Calculates the millisecond delay until the next occurrence of [targetHour]:[targetMinute].
     * If the time for today has already passed, schedules for tomorrow.
     *
     * @param targetHour 0-23 hour in 24h format
     * @param targetMinute 0-59 minute
     * @param nowMillis reference timestamp for calculation (defaults to System.currentTimeMillis)
     * @return delay in milliseconds
     */
    fun calculateInitialDelayMillis(
        targetHour: Int,
        targetMinute: Int,
        nowMillis: Long = System.currentTimeMillis()
    ): Long {
        val now = Calendar.getInstance().apply { timeInMillis = nowMillis }
        val target = Calendar.getInstance().apply {
            timeInMillis = nowMillis
            set(Calendar.HOUR_OF_DAY, targetHour)
            set(Calendar.MINUTE, targetMinute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        if (target.timeInMillis <= now.timeInMillis) {
            target.add(Calendar.DAY_OF_YEAR, 1)
        }

        return target.timeInMillis - now.timeInMillis
    }

    /**
     * Schedules periodic 24-hour workers for both daily reminders using ExistingPeriodicWorkPolicy.KEEP.
     * Idempotent: Subsequent calls will preserve active schedules without resetting timers.
     */
    fun scheduleDailyPeriodicReminders(context: Context) {
        val workManager = WorkManager.getInstance(context)

        // 1. Mid-Afternoon Reminder (4:30 PM)
        val afternoonDelay = calculateInitialDelayMillis(
            targetHour = MidAfternoonReminderWorker.TARGET_HOUR,
            targetMinute = MidAfternoonReminderWorker.TARGET_MINUTE
        )

        val afternoonRequest = PeriodicWorkRequestBuilder<MidAfternoonReminderWorker>(24, TimeUnit.HOURS)
            .setInitialDelay(afternoonDelay, TimeUnit.MILLISECONDS)
            .addTag(MidAfternoonReminderWorker.TAG)
            .build()

        workManager.enqueueUniquePeriodicWork(
            MidAfternoonReminderWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            afternoonRequest
        )

        // 2. Night Routine Reminder (10:00 PM)
        val nightDelay = calculateInitialDelayMillis(
            targetHour = NightRoutineReminderWorker.TARGET_HOUR,
            targetMinute = NightRoutineReminderWorker.TARGET_MINUTE
        )

        val nightRequest = PeriodicWorkRequestBuilder<NightRoutineReminderWorker>(24, TimeUnit.HOURS)
            .setInitialDelay(nightDelay, TimeUnit.MILLISECONDS)
            .addTag(NightRoutineReminderWorker.TAG)
            .build()

        workManager.enqueueUniquePeriodicWork(
            NightRoutineReminderWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            nightRequest
        )
    }

    /**
     * Schedules one-time daily workers with exact delay calculation using ExistingWorkPolicy.KEEP.
     * Useful for immediate daily locks or environments where chained one-off tasks are preferred.
     */
    fun scheduleDailyOneTimeReminders(context: Context) {
        val workManager = WorkManager.getInstance(context)

        // Mid-Afternoon One-Time Request
        val afternoonDelay = calculateInitialDelayMillis(
            targetHour = MidAfternoonReminderWorker.TARGET_HOUR,
            targetMinute = MidAfternoonReminderWorker.TARGET_MINUTE
        )
        val afternoonOneTime = OneTimeWorkRequestBuilder<MidAfternoonReminderWorker>()
            .setInitialDelay(afternoonDelay, TimeUnit.MILLISECONDS)
            .addTag(MidAfternoonReminderWorker.TAG)
            .build()

        workManager.enqueueUniqueWork(
            MidAfternoonReminderWorker.WORK_NAME,
            ExistingWorkPolicy.KEEP,
            afternoonOneTime
        )

        // Night Routine One-Time Request
        val nightDelay = calculateInitialDelayMillis(
            targetHour = NightRoutineReminderWorker.TARGET_HOUR,
            targetMinute = NightRoutineReminderWorker.TARGET_MINUTE
        )
        val nightOneTime = OneTimeWorkRequestBuilder<NightRoutineReminderWorker>()
            .setInitialDelay(nightDelay, TimeUnit.MILLISECONDS)
            .addTag(NightRoutineReminderWorker.TAG)
            .build()

        workManager.enqueueUniqueWork(
            NightRoutineReminderWorker.WORK_NAME,
            ExistingWorkPolicy.KEEP,
            nightOneTime
        )
    }

    /**
     * Standard entry point invoked during Application onCreate.
     * Sets up periodic reminders with ExistingPeriodicWorkPolicy.KEEP.
     */
    fun scheduleDailyReminders(context: Context) {
        scheduleDailyPeriodicReminders(context)
    }

    /**
     * Cancels all scheduled reminder workers.
     */
    fun cancelAllReminders(context: Context) {
        val workManager = WorkManager.getInstance(context)
        workManager.cancelUniqueWork(MidAfternoonReminderWorker.WORK_NAME)
        workManager.cancelUniqueWork(NightRoutineReminderWorker.WORK_NAME)
    }
}
