package com.habitos.cleanstep.domain.repository

import com.habitos.cleanstep.domain.model.RescueSnack
import kotlinx.coroutines.flow.Flow

data class CravingLogEntry(
    val id: Long = 0L,
    val timestamp: Long = System.currentTimeMillis(),
    val durationSecondsTarget: Int = 900,
    val secondsWaited: Int = 900,
    val resistedSuccessfully: Boolean = true,
    val snackChosenName: String? = null
)

interface CravingRescueRepository {
    fun getRescueSnacks(): Flow<List<RescueSnack>>
    suspend fun logCravingSession(entry: CravingLogEntry)
    fun getRecentCravingLogs(limit: Int = 10): Flow<List<CravingLogEntry>>
}
