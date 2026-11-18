package com.habitos.cleanstep.core.notification

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

/**
 * Worker that triggers daily at ~4:30 PM (16:30) during the critical dopamine drop / snacking hour.
 * Dispatches an actionable notification prompting the user to hydrate or grab mineral water
 * with lemon instead of soda, cookies, or chips.
 */
class MidAfternoonReminderWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            val notificationHelper = NotificationHelper(applicationContext)
            notificationHelper.showMidAfternoonNotification(
                title = NotificationHelper.DEFAULT_MID_AFTERNOON_TITLE,
                body = NotificationHelper.DEFAULT_MID_AFTERNOON_BODY
            )
            Result.success()
        } catch (e: Exception) {
            Result.failure()
        }
    }

    companion object {
        const val WORK_NAME = "work_cleanstep_mid_afternoon_reminder"
        const val TAG = "cleanstep_mid_afternoon"
        const val TARGET_HOUR = 16
        const val TARGET_MINUTE = 30
    }
}
