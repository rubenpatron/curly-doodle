package com.habitos.cleanstep.domain.repository

import com.habitos.cleanstep.domain.model.NightRoutinePlan
import com.habitos.cleanstep.domain.model.SedentaryProgressionLevel
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

interface NightRoutinePlanRepository {
    fun getCompletedDaysInCurrentWeek(): Flow<Int>
    fun isRoutineCompletedToday(date: LocalDate = LocalDate.now()): Flow<Boolean>
    suspend fun markRoutineCompleted(date: LocalDate = LocalDate.now(), exercisesDone: List<String>, durationMinutes: Int)
    fun getPlanForLevel(level: SedentaryProgressionLevel): NightRoutinePlan
}
