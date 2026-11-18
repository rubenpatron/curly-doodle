package com.habitloss.app.domain.repository

import com.habitloss.app.domain.model.SugarLog
import com.habitloss.app.domain.model.SugarTrafficLight
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

interface SugarLogRepository {
    /**
     * Observes today's sugar traffic light log.
     */
    fun getTodaySugarLog(): Flow<SugarLog?>

    /**
     * Observes sugar log for a specific date.
     */
    fun getSugarLogForDate(date: LocalDate): Flow<SugarLog?>

    /**
     * Observes logs within a date range (for weekly / monthly trends).
     */
    fun getSugarLogsRange(startDate: LocalDate, endDate: LocalDate): Flow<List<SugarLog>>

    /**
     * Logs or updates sugar intake traffic light for a given day.
     */
    suspend fun logSugar(
        trafficLight: SugarTrafficLight,
        notes: String? = null,
        date: LocalDate = LocalDate.now()
    )

    /**
     * Directly persists or replaces a sugar log.
     */
    suspend fun saveSugarLog(log: SugarLog)
}
