package com.habitos.cleanstep

import android.app.Application
import com.habitos.cleanstep.core.notification.NotificationHelper
import com.habitos.cleanstep.core.notification.NotificationScheduler
import com.habitos.cleanstep.data.local.database.AppDatabase
import com.habitos.cleanstep.data.repository.CravingRescueRepositoryImpl
import com.habitos.cleanstep.data.repository.HabitRepositoryImpl
import com.habitos.cleanstep.data.repository.NightRoutinePlanRepositoryImpl
import com.habitos.cleanstep.domain.repository.CravingRescueRepository
import com.habitos.cleanstep.domain.repository.HabitRepository
import com.habitos.cleanstep.domain.repository.NightRoutinePlanRepository

class CleanStepApplication : Application() {

    lateinit var database: AppDatabase
        private set

    lateinit var habitRepository: HabitRepository
        private set

    lateinit var cravingRescueRepository: CravingRescueRepository
        private set

    lateinit var nightRoutinePlanRepository: NightRoutinePlanRepository
        private set

    lateinit var notificationHelper: NotificationHelper
        private set

    override fun onCreate() {
        super.onCreate()
        database = AppDatabase.getInstance(this)
        habitRepository = HabitRepositoryImpl(
            habitStreakDao = database.habitStreakDao(),
            sugarLogDao = database.sugarLogDao(),
            waterIntakeDao = database.waterIntakeDao(),
            nightRoutineDao = database.nightRoutineDao()
        )
        cravingRescueRepository = CravingRescueRepositoryImpl()
        nightRoutinePlanRepository = NightRoutinePlanRepositoryImpl(database.nightRoutineDao())

        // Inicializar canales de notificación y programación de WorkManager
        notificationHelper = NotificationHelper(this)
        notificationHelper.createChannels()
        NotificationScheduler.scheduleDailyReminders(this)
    }
}
