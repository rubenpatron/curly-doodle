package com.habitos.cleanstep.data.repository

import com.habitos.cleanstep.domain.model.MexicanRescueSnacksCatalog
import com.habitos.cleanstep.domain.model.RescueSnack
import com.habitos.cleanstep.domain.repository.CravingLogEntry
import com.habitos.cleanstep.domain.repository.CravingRescueRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.withContext

/**
 * Implementación 100% offline para el registro de sesiones de antojo y catálogo de rescate.
 */
class CravingRescueRepositoryImpl(
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : CravingRescueRepository {

    private val _logsFlow = MutableStateFlow<List<CravingLogEntry>>(emptyList())

    override fun getRescueSnacks(): Flow<List<RescueSnack>> {
        return flowOf(MexicanRescueSnacksCatalog.snacks).flowOn(ioDispatcher)
    }

    override suspend fun logCravingSession(entry: CravingLogEntry): Unit = withContext(ioDispatcher) {
        _logsFlow.update { current ->
            listOf(entry) + current
        }
    }

    override fun getRecentCravingLogs(limit: Int): Flow<List<CravingLogEntry>> {
        return _logsFlow.asStateFlow()
    }
}
