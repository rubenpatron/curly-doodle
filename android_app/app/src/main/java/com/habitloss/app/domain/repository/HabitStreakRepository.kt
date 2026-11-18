package com.habitloss.app.domain.repository

import com.habitloss.app.domain.model.HabitStreak
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

interface HabitStreakRepository {
    /**
     * Observes the active streak state in real-time.
     */
    fun getStreak(): Flow<HabitStreak>

    /**
     * Records a clean day (no soda, no cookies, no chips/Sabritas).
     * If yesterday was clean, increments currentStreak; updates bestStreak if exceeded.
     */
    suspend fun recordCleanDay(date: LocalDate = LocalDate.now())

    /**
     * Records a relapse into ultraprocessed snacks or soda.
     * Resets current streak to 0 while preserving bestStreak.
     */
    suspend fun recordRelapse(date: LocalDate = LocalDate.now())

    /**
     * Resets streak state completely.
     */
    suspend fun resetStreak()

    /**
     * Updates streak entity explicitly.
     */
    suspend fun updateStreak(streak: HabitStreak)
}
