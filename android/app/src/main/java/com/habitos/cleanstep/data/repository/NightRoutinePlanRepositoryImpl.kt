package com.habitos.cleanstep.data.repository

import com.habitos.cleanstep.data.local.dao.NightRoutineDao
import com.habitos.cleanstep.data.local.entity.NightRoutineEntity
import com.habitos.cleanstep.domain.model.NightRoutinePlan
import com.habitos.cleanstep.domain.model.SedentaryProgressionLevel
import com.habitos.cleanstep.domain.repository.NightRoutinePlanRepository
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
 * Implementación de NightRoutinePlanRepository alimentada 100% offline por Room.
 * Calcula automáticamente la progresión semanal (>= 4 días) para el ViewModel.
 */
class NightRoutinePlanRepositoryImpl(
    private val dao: NightRoutineDao,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : NightRoutinePlanRepository {

    override fun getCompletedDaysInCurrentWeek(): Flow<Int> {
        val today = LocalDate.now()
        val startOfWeek = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        val endOfWeek = today.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY))

        return dao.getCompletedDaysCountFlow(startOfWeek, endOfWeek)
            .flowOn(ioDispatcher)
    }

    override fun isRoutineCompletedToday(date: LocalDate): Flow<Boolean> {
        return dao.getRoutineForDateFlow(date)
            .map { it?.completed ?: false }
            .flowOn(ioDispatcher)
    }

    override suspend fun markRoutineCompleted(
        date: LocalDate,
        exercisesDone: List<String>,
        durationMinutes: Int
    ): Unit = withContext(ioDispatcher) {
        val today = LocalDate.now()
        val startOfWeek = today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        val endOfWeek = today.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY))
        val completedDays = dao.getCompletedDaysCountSync(startOfWeek, endOfWeek)
        val level = SedentaryProgressionLevel.fromCompletedDaysThisWeek(completedDays + 1)

        val entity = NightRoutineEntity(
            date = date,
            completed = true,
            exercisesDone = exercisesDone,
            durationMinutes = durationMinutes,
            weekNumber = level.levelNumber,
            difficultyLevel = level.name,
            scheduledHour = 22,
            timestamp = System.currentTimeMillis()
        )
        dao.insertOrUpdate(entity)
    }

    override fun getPlanForLevel(level: SedentaryProgressionLevel): NightRoutinePlan {
        return NightRoutinePlan(level = level)
    }
}
