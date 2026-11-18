package com.habitos.cleanstep.domain.repository

import com.habitos.cleanstep.domain.model.HabitStreak
import com.habitos.cleanstep.domain.model.NightRoutinePlan
import com.habitos.cleanstep.domain.model.NightRoutineSummary
import com.habitos.cleanstep.domain.model.SugarTrafficLight
import com.habitos.cleanstep.domain.model.WaterIntake
import com.habitos.cleanstep.domain.model.WeeklySugarDay
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

interface HabitRepository {
    fun getHabitStreak(): Flow<HabitStreak>
    fun getSugarTrafficLightToday(): Flow<SugarTrafficLight>
    fun getWeeklySugarHistory(): Flow<List<WeeklySugarDay>>
    fun getWaterIntakeToday(): Flow<WaterIntake>
    fun getNightRoutineToday(): Flow<NightRoutineSummary>
    fun getCompletedDaysInCurrentWeek(): Flow<Int>
    fun getCurrentRoutinePlan(): Flow<NightRoutinePlan>

    suspend fun setSugarTrafficLightToday(level: SugarTrafficLight)
    suspend fun incrementWater()
    suspend fun decrementWater()
    suspend fun toggleNightRoutine()
    suspend fun completeNightRoutine(
        exercisesDone: List<String>,
        durationMinutes: Int,
        level: Int = 1,
        date: LocalDate = LocalDate.now()
    )
}
