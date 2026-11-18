package com.habitos.cleanstep.core.notification

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

/**
 * Worker that triggers punctually at 10:00 PM (22:00) before sleep.
 * Dispatches a discreet, low-noise nocturnal notification prompting the user to complete
 * their 15-minute low-impact mobility and decompression routine.
 */
class NightRoutineReminderWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            val notificationHelper = NotificationHelper(applicationContext)
            notificationHelper.showNightRoutineNotification(
                title = NotificationHelper.DEFAULT_NIGHT_ROUTINE_TITLE,
                body = NotificationHelper.DEFAULT_NIGHT_ROUTINE_BODY
            )
            Result.success()
        } catch (e: Exception) {
            Result.failure()
        }
    }

    companion object {
        const val WORK_NAME = "work_cleanstep_night_routine_reminder"
        const val TAG = "cleanstep_night_routine"
        const val TARGET_HOUR = 22
        const val TARGET_MINUTE = 0
    }
}
