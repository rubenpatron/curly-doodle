package com.habitloss.app.data.repository

import com.habitloss.app.data.local.dao.SugarLogDao
import com.habitloss.app.data.local.entity.SugarLogEntity
import com.habitloss.app.data.mapper.toDomain
import com.habitloss.app.data.mapper.toEntity
import com.habitloss.app.domain.model.SugarLog
import com.habitloss.app.domain.model.SugarTrafficLight
import com.habitloss.app.domain.repository.SugarLogRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import java.time.LocalDate

/**
 * Implementación 100% offline del repositorio de semáforo de azúcar diario.
 */
class SugarLogRepositoryImpl(
    private val dao: SugarLogDao,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : SugarLogRepository {

    override fun getTodaySugarLog(): Flow<SugarLog?> {
        return getSugarLogForDate(LocalDate.now())
    }

    override fun getSugarLogForDate(date: LocalDate): Flow<SugarLog?> {
        return dao.getSugarLogForDateFlow(date)
            .map { it?.toDomain() }
            .flowOn(ioDispatcher)
    }

    override fun getSugarLogsRange(startDate: LocalDate, endDate: LocalDate): Flow<List<SugarLog>> {
        return dao.getSugarLogsRangeFlow(startDate, endDate)
            .map { list -> list.map { it.toDomain() } }
            .flowOn(ioDispatcher)
    }

    override suspend fun logSugar(
        trafficLight: SugarTrafficLight,
        notes: String?,
        date: LocalDate
    ): Unit = withContext(ioDispatcher) {
        val existing = dao.getSugarLogForDateSync(date)
        val entity = SugarLogEntity(
            id = existing?.id ?: 0L,
            date = date,
            sugarTrafficLight = trafficLight,
            notes = notes,
            timestamp = System.currentTimeMillis()
        )
        dao.insertOrUpdate(entity)
    }

    override suspend fun saveSugarLog(log: SugarLog): Unit = withContext(ioDispatcher) {
        dao.insertOrUpdate(log.toEntity())
    }
}
