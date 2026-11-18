package com.habitloss.app.domain.repository

import com.habitloss.app.domain.model.CravingRescueSession
import com.habitloss.app.domain.model.CravingType
import com.habitloss.app.domain.model.SatietySwapItem
import kotlinx.coroutines.flow.Flow

interface CravingRescueRepository {
    /**
     * Retrieves available healthy satiety swaps, optionally filtered by craving type.
     */
    fun getSatietySwaps(cravingType: CravingType? = null): Flow<List<SatietySwapItem>>

    /**
     * Logs an anti-craving rescue session (10-15 min delay + swap used).
     */
    suspend fun logCravingSession(session: CravingRescueSession)

    /**
     * Observes recent craving rescue attempts.
     */
    fun getRecentCravingSessions(limit: Int = 10): Flow<List<CravingRescueSession>>
}
