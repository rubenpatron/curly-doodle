package com.habitloss.app.domain.repository

import com.habitloss.app.domain.model.NightRoutine
import com.habitloss.app.domain.model.NightRoutinePlan
import com.habitloss.app.domain.model.RoutineDifficulty
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

interface NightRoutineRepository {
    /**
     * Observes today's night routine status.
     */
    fun getTodayRoutine(): Flow<NightRoutine?>

    /**
     * Observes routines for a specific week number.
     */
    fun getWeeklyRoutines(weekNumber: Int): Flow<List<NightRoutine>>

    /**
     * Observes routines within a date range.
     */
    fun getRoutinesRange(startDate: LocalDate, endDate: LocalDate): Flow<List<NightRoutine>>

    /**
     * Observes count of completed days in the current week (Monday to Sunday).
     */
    fun getCompletedDaysInCurrentWeek(): Flow<Int>

    /**
     * Observes the active sedentary progression plan (Level 1, 2, or 3).
     * Automatically advances if >= 4 days completed in the current week.
     */
    fun getCurrentRoutinePlan(): Flow<NightRoutinePlan>

    /**
     * Marks routine completed with exercises and duration.
     */
    suspend fun completeRoutine(
        date: LocalDate = LocalDate.now(),
        exercises: List<String>,
        durationMinutes: Int,
        weekNumber: Int = 1,
        difficulty: RoutineDifficulty = RoutineDifficulty.GENTLE
    )

    /**
     * Replaces or updates routine record.
     */
    suspend fun saveRoutine(routine: NightRoutine)
}
