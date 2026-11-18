package com.habitos.cleanstep.data.repository

import com.habitos.cleanstep.data.local.dao.HabitStreakDao
import com.habitos.cleanstep.data.local.dao.NightRoutineDao
import com.habitos.cleanstep.data.local.dao.SugarLogDao
import com.habitos.cleanstep.data.local.dao.WaterIntakeDao
import com.habitos.cleanstep.data.local.entity.HabitStreakEntity
import com.habitos.cleanstep.data.local.entity.NightRoutineEntity
import com.habitos.cleanstep.data.local.entity.SugarLogEntity
import com.habitos.cleanstep.data.local.entity.WaterIntakeEntity
import com.habitos.cleanstep.domain.model.HabitStreak
import com.habitos.cleanstep.domain.model.NightRoutinePlan
import com.habitos.cleanstep.domain.model.NightRoutineSummary
import com.habitos.cleanstep.domain.model.SedentaryProgressionLevel
import com.habitos.cleanstep.domain.model.SugarTrafficLight
import com.habitos.cleanstep.domain.model.WaterIntake
import com.habitos.cleanstep.domain.model.WeeklySugarDay
import com.habitos.cleanstep.domain.repository.HabitRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.TextStyle
import java.time.temporal.TemporalAdjusters
import java.util.Locale

/**
 * Implementación unificada de HabitRepository para la UI del Dashboard en Jetpack Compose.
 * Alimentada por la base de datos Room 100% offline.
 */
class HabitRepositoryImpl(
    private val habitStreakDao: HabitStreakDao,
    private val sugarLogDao: SugarLogDao,
    private val waterIntakeDao: WaterIntakeDao,
    private val nightRoutineDao: NightRoutineDao,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : HabitRepository {

    override fun getHabitStreak(): Flow<HabitStreak> {
        return habitStreakDao.getStreakFlow(1L)
            .map { entity ->
                if (entity != null) {
                    HabitStreak(
                        currentStreak = entity.currentStreak,
                        bestStreak = entity.bestStreak,
                        daysWithoutSoda = entity.daysWithoutSoda,
                        daysWithoutCookies = entity.daysWithoutCookies,
                        daysWithoutChips = entity.daysWithoutChips,
                        lastCleanDate = entity.lastCleanDate?.toString().orEmpty()
                    )
                } else {
                    HabitStreak()
                }
            }
            .flowOn(ioDispatcher)
    }

    override fun getSugarTrafficLightToday(): Flow<SugarTrafficLight> {
        val today = LocalDate.now()
        return sugarLogDao.getLogForDateFlow(today)
            .map { it?.trafficLight ?: SugarTrafficLight.NONE }
            .flowOn(ioDispatcher)
    }

    override fun getWeeklySugarHistory(): Flow<List<WeeklySugarDay>> {
        val today = LocalDate.now()
        val startDate = today.minusDays(6)

        return sugarLogDao.getLogsBetweenFlow(startDate, today)
            .map { logs ->
                val logMap = logs.associateBy { it.date }
                (0..6).map { dayOffset ->
                    val date = startDate.plusDays(dayOffset.toLong())
                    val log = logMap[date]
                    val dayName = date.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale("es", "MX"))
                        .replaceFirstChar { it.uppercase() }

                    WeeklySugarDay(
                        dayOfWeek = dayName,
                        dateString = date.toString(),
                        status = log?.trafficLight ?: SugarTrafficLight.NONE,
                        isToday = date.isEqual(today)
                    )
                }
            }
            .flowOn(ioDispatcher)
    }

    override fun getWaterIntakeToday(): Flow<WaterIntake> {
        val today = LocalDate.now()
        return waterIntakeDao.getWaterIntakeFlow(today)
            .map { entity ->
                if (entity != null) {
                    WaterIntake(
                        glassesCount = entity.glassesCount,
                        targetGlasses = entity.targetGlasses
                    )
                } else {
                    WaterIntake(glassesCount = 0, targetGlasses = 8)
                }
            }
            .flowOn(ioDispatcher)
    }

    override fun getNightRoutineToday(): Flow<NightRoutineSummary> {
        val today = LocalDate.now()
        return nightRoutineDao.getRoutineForDateFlow(today)
            .map { entity ->
                NightRoutineSummary(
                    isCompletedToday = entity?.completed ?: false,
                    scheduledTime = "22:00",
                    title = "Rutina Nocturna Sedentaria",
                    durationMinutes = entity?.durationMinutes ?: 15,
                    description = if (entity?.completed == true) {
                        "¡Completada hoy! Músculos relajados, retorno venoso activo y sistema parasimpático encendido."
                    } else {
                        "Movilidad articular suave de bajo impacto para aliviar tensión lumbar y apagar el sistema nervioso."
                    }
                )
            }
            .flowOn(ioDispatcher)
    }

    override fun getCompletedDaysInCurrentWeek(): Flow<Int> {
        val today = LocalDate.now()
        val startOfWeek = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        val endOfWeek = today.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY))

        return nightRoutineDao.getCompletedDaysCountFlow(startOfWeek, endOfWeek)
            .flowOn(ioDispatcher)
    }

    override fun getCurrentRoutinePlan(): Flow<NightRoutinePlan> {
        return getCompletedDaysInCurrentWeek().map { completedDays ->
            val level = SedentaryProgressionLevel.fromCompletedDaysThisWeek(completedDays)
            NightRoutinePlan(level = level)
        }.flowOn(ioDispatcher)
    }

    override suspend fun setSugarTrafficLightToday(level: SugarTrafficLight): Unit = withContext(ioDispatcher) {
        val today = LocalDate.now()
        val logEntity = SugarLogEntity(
            date = today,
            trafficLight = level,
            timestamp = System.currentTimeMillis()
        )
        sugarLogDao.insertOrUpdate(logEntity)

        // Actualizar la racha según el semáforo
        val currentStreakEntity = habitStreakDao.getStreakSync(1L) ?: HabitStreakEntity(id = 1L)
        if (level == SugarTrafficLight.GREEN) {
            val yesterday = today.minusDays(1)
            val isConsecutive = currentStreakEntity.lastCleanDate != null && currentStreakEntity.lastCleanDate.isEqual(yesterday)
            val isAlreadyLoggedToday = currentStreakEntity.lastCleanDate != null && currentStreakEntity.lastCleanDate.isEqual(today)

            if (!isAlreadyLoggedToday) {
                val newStreak = if (isConsecutive) currentStreakEntity.currentStreak + 1 else 1
                val newBest = maxOf(newStreak, currentStreakEntity.bestStreak)
                habitStreakDao.insertOrUpdate(
                    currentStreakEntity.copy(
                        currentStreak = newStreak,
                        bestStreak = newBest,
                        daysWithoutSoda = currentStreakEntity.daysWithoutSoda + 1,
                        daysWithoutCookies = currentStreakEntity.daysWithoutCookies + 1,
                        daysWithoutChips = currentStreakEntity.daysWithoutChips + 1,
                        lastCleanDate = today,
                        lastUpdatedTimestamp = System.currentTimeMillis()
                    )
                )
            }
        } else if (level == SugarTrafficLight.RED || level == SugarTrafficLight.AMBER) {
            habitStreakDao.insertOrUpdate(
                currentStreakEntity.copy(
                    currentStreak = 0,
                    lastUpdatedTimestamp = System.currentTimeMillis()
                )
            )
        }
    }

    override suspend fun incrementWater(): Unit = withContext(ioDispatcher) {
        val today = LocalDate.now()
        val existing = waterIntakeDao.getWaterIntakeSync(today)
        if (existing == null) {
            waterIntakeDao.insertOrUpdate(
                WaterIntakeEntity(
                    date = today,
                    glassesCount = 1,
                    targetGlasses = 8,
                    timestamp = System.currentTimeMillis()
                )
            )
        } else {
            waterIntakeDao.incrementGlasses(today)
        }
    }

    override suspend fun decrementWater(): Unit = withContext(ioDispatcher) {
        val today = LocalDate.now()
        val existing = waterIntakeDao.getWaterIntakeSync(today)
        if (existing == null) {
            waterIntakeDao.insertOrUpdate(
                WaterIntakeEntity(
                    date = today,
                    glassesCount = 0,
                    targetGlasses = 8,
                    timestamp = System.currentTimeMillis()
                )
            )
        } else {
            waterIntakeDao.decrementGlasses(today)
        }
    }

    override suspend fun toggleNightRoutine(): Unit = withContext(ioDispatcher) {
        val today = LocalDate.now()
        val existing = nightRoutineDao.getRoutineForDateSync(today)
        if (existing == null) {
            nightRoutineDao.insertOrUpdate(
                NightRoutineEntity(
                    date = today,
                    completed = true,
                    durationMinutes = 15,
                    timestamp = System.currentTimeMillis()
                )
            )
        } else {
            nightRoutineDao.setCompleted(today, !existing.completed)
        }
    }

    override suspend fun completeNightRoutine(
        exercisesDone: List<String>,
        durationMinutes: Int,
        level: Int,
        date: LocalDate
    ): Unit = withContext(ioDispatcher) {
        val entity = NightRoutineEntity(
            date = date,
            completed = true,
            exercisesDone = exercisesDone,
            durationMinutes = durationMinutes,
            weekNumber = level,
            difficultyLevel = "LEVEL_$level",
            scheduledHour = 22,
            timestamp = System.currentTimeMillis()
        )
        nightRoutineDao.insertOrUpdate(entity)
    }
}
