package com.habitos.cleanstep.domain.repository

import com.habitos.cleanstep.domain.model.NightRoutinePlan
import com.habitos.cleanstep.domain.model.NightRoutineSummary
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

/**
 * Contrato de repositorio específico para la rutina nocturna de descompresión y movilidad (+10:00 PM).
 */
interface NightRoutineRepository {
    /**
     * Observa el estado de la rutina del día de hoy.
     */
    fun getTodayRoutine(): Flow<NightRoutineSummary>

    /**
     * Observa la cantidad de días completados de rutina en la semana en curso (Lunes a Domingo).
     */
    fun getCompletedDaysInCurrentWeek(): Flow<Int>

    /**
     * Observa el plan activo de rutina (Nivel 1, 2 o 3) con avance automático si se completan >= 4 días en la semana.
     */
    fun getCurrentRoutinePlan(): Flow<NightRoutinePlan>

    /**
     * Registra la rutina de hoy como completada con los ejercicios ejecutados y la duración en minutos.
     */
    suspend fun completeRoutine(
        exercisesDone: List<String>,
        durationMinutes: Int,
        level: Int = 1,
        date: LocalDate = LocalDate.now()
    )

    /**
     * Alterna rápidamente el estado completado/no completado de la rutina de una fecha.
     */
    suspend fun toggleRoutine(date: LocalDate = LocalDate.now())
}
