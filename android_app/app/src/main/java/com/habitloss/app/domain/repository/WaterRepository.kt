package com.habitloss.app.domain.repository

import com.habitloss.app.domain.model.WaterIntake
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

interface WaterRepository {
    /**
     * Observes today's water intake in real-time.
     */
    fun getTodayWaterIntake(): Flow<WaterIntake>

    /**
     * Observes water intake for a specific date.
     */
    fun getWaterIntakeForDate(date: LocalDate): Flow<WaterIntake?>

    /**
     * Increments water intake by 1 glass (250 ml).
     */
    suspend fun incrementGlass(date: LocalDate = LocalDate.now())

    /**
     * Decrements water intake by 1 glass (cannot go below 0).
     */
    suspend fun decrementGlass(date: LocalDate = LocalDate.now())

    /**
     * Updates daily target glasses (default 8).
     */
    suspend fun setTargetGlasses(target: Int, date: LocalDate = LocalDate.now())

    /**
     * Replaces or updates water intake record.
     */
    suspend fun updateWaterIntake(waterIntake: WaterIntake)
}
