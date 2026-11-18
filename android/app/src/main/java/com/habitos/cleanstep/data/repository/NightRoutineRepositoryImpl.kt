package com.habitos.cleanstep.data.repository

import com.habitos.cleanstep.data.local.dao.NightRoutineDao
import com.habitos.cleanstep.data.local.entity.NightRoutineEntity
import com.habitos.cleanstep.domain.model.NightRoutineCatalog
import com.habitos.cleanstep.domain.model.NightRoutinePlan
import com.habitos.cleanstep.domain.model.NightRoutineSummary
import com.habitos.cleanstep.domain.repository.NightRoutineRepository
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
 * Implementación de NightRoutineRepository con lógica de avance de progresión automática
 * para usuarios sedentarios (meta >= 4 días completados por semana para subir de nivel).
 */
class NightRoutineRepositoryImpl(
    private val nightRoutineDao: NightRoutineDao,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : NightRoutineRepository {

    override fun getTodayRoutine(): Flow<NightRoutineSummary> {
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
            val level = when {
                completedDays >= 6 -> 3
                completedDays >= 4 -> 2
                else -> 1
            }
            NightRoutineCatalog.getPlanForLevel(level)
        }.flowOn(ioDispatcher)
    }

    override suspend fun completeRoutine(
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

    override suspend fun toggleRoutine(date: LocalDate): Unit = withContext(ioDispatcher) {
        val existing = nightRoutineDao.getRoutineForDateSync(date)
        if (existing == null) {
            nightRoutineDao.insertOrUpdate(
                NightRoutineEntity(
                    date = date,
                    completed = true,
                    durationMinutes = 15,
                    timestamp = System.currentTimeMillis()
                )
            )
        } else {
            nightRoutineDao.setCompleted(date, !existing.completed)
        }
    }
}
