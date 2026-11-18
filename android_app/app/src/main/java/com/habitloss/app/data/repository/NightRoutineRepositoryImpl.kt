package com.habitloss.app.data.repository

import com.habitloss.app.data.local.dao.NightRoutineDao
import com.habitloss.app.data.local.entity.NightRoutineEntity
import com.habitloss.app.data.mapper.toDomain
import com.habitloss.app.data.mapper.toEntity
import com.habitloss.app.domain.model.NightRoutine
import com.habitloss.app.domain.model.NightRoutineCatalog
import com.habitloss.app.domain.model.NightRoutinePlan
import com.habitloss.app.domain.model.RoutineDifficulty
import com.habitloss.app.domain.repository.NightRoutineRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.TemporalAdjusters

/**
 * Implementación 100% offline del repositorio de rutina de bajo impacto nocturna (+10:00 PM).
 */
class NightRoutineRepositoryImpl(
    private val dao: NightRoutineDao,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : NightRoutineRepository {

    override fun getTodayRoutine(): Flow<NightRoutine?> {
        val today = LocalDate.now()
        return dao.getRoutineForDateFlow(today)
            .map { it?.toDomain() }
            .flowOn(ioDispatcher)
    }

    override fun getWeeklyRoutines(weekNumber: Int): Flow<List<NightRoutine>> {
        return dao.getWeeklyRoutinesFlow(weekNumber)
            .map { list -> list.map { it.toDomain() } }
            .flowOn(ioDispatcher)
    }

    override fun getRoutinesRange(startDate: LocalDate, endDate: LocalDate): Flow<List<NightRoutine>> {
        return dao.getRoutinesRangeFlow(startDate, endDate)
            .map { list -> list.map { it.toDomain() } }
            .flowOn(ioDispatcher)
    }

    override fun getCompletedDaysInCurrentWeek(): Flow<Int> {
        val today = LocalDate.now()
        val startOfWeek = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        val endOfWeek = today.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY))

        return dao.getCompletedCountBetweenFlow(startOfWeek, endOfWeek)
            .flowOn(ioDispatcher)
    }

    override fun getCurrentRoutinePlan(): Flow<NightRoutinePlan> {
        return getCompletedDaysInCurrentWeek().map { completedDays ->
            val level = when {
                completedDays >= 6 -> 3
                completedDays >= 4 -> 2
                else -> 1
            }
            NightRoutineCatalog.getPlanForLevel(level)
        }.flowOn(ioDispatcher)
    }

    override suspend fun completeRoutine(
        date: LocalDate,
        exercises: List<String>,
        durationMinutes: Int,
        weekNumber: Int,
        difficulty: RoutineDifficulty
    ): Unit = withContext(ioDispatcher) {
        val entity = NightRoutineEntity(
            date = date,
            completed = true,
            exercisesDone = exercises,
            durationMinutes = durationMinutes,
            weekNumber = weekNumber,
            difficultyLevel = difficulty,
            scheduledHour = 22,
            timestamp = System.currentTimeMillis()
        )
        dao.insertOrUpdate(entity)
    }

    override suspend fun saveRoutine(routine: NightRoutine): Unit = withContext(ioDispatcher) {
        dao.insertOrUpdate(routine.toEntity())
    }
}
