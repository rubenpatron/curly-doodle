package com.habitloss.app.data.repository

import com.habitloss.app.data.local.dao.WaterIntakeDao
import com.habitloss.app.data.local.entity.WaterIntakeEntity
import com.habitloss.app.data.mapper.toDomain
import com.habitloss.app.data.mapper.toEntity
import com.habitloss.app.domain.model.WaterIntake
import com.habitloss.app.domain.repository.WaterRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import java.time.LocalDate

/**
 * Implementación 100% offline del repositorio de hidratación con Room y Flows.
 */
class WaterRepositoryImpl(
    private val dao: WaterIntakeDao,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : WaterRepository {

    override fun getTodayWaterIntake(): Flow<WaterIntake> {
        val today = LocalDate.now()
        return dao.getWaterIntakeForDateFlow(today)
            .map { entity ->
                entity?.toDomain() ?: WaterIntake(date = today, glassesCount = 0, targetGlasses = 8)
            }
            .flowOn(ioDispatcher)
    }

    override fun getWaterIntakeForDate(date: LocalDate): Flow<WaterIntake?> {
        return dao.getWaterIntakeForDateFlow(date)
            .map { it?.toDomain() }
            .flowOn(ioDispatcher)
    }

    override suspend fun incrementGlass(date: LocalDate): Unit = withContext(ioDispatcher) {
        val existing = dao.getWaterIntakeForDateSync(date)
        if (existing == null) {
            dao.insertOrUpdate(
                WaterIntakeEntity(
                    date = date,
                    glassesCount = 1,
                    targetGlasses = 8,
                    timestamp = System.currentTimeMillis()
                )
            )
        } else {
            dao.incrementGlasses(date = date, amount = 1)
        }
    }

    override suspend fun decrementGlass(date: LocalDate): Unit = withContext(ioDispatcher) {
        val existing = dao.getWaterIntakeForDateSync(date)
        if (existing == null) {
            dao.insertOrUpdate(
                WaterIntakeEntity(
                    date = date,
                    glassesCount = 0,
                    targetGlasses = 8,
                    timestamp = System.currentTimeMillis()
                )
            )
        } else {
            dao.decrementGlasses(date = date, amount = 1)
        }
    }

    override suspend fun setTargetGlasses(target: Int, date: LocalDate): Unit = withContext(ioDispatcher) {
        val existing = dao.getWaterIntakeForDateSync(date)
        if (existing == null) {
            dao.insertOrUpdate(
                WaterIntakeEntity(
                    date = date,
                    glassesCount = 0,
                    targetGlasses = target,
                    timestamp = System.currentTimeMillis()
                )
            )
        } else {
            dao.updateTargetGlasses(date = date, target = target)
        }
    }

    override suspend fun updateWaterIntake(waterIntake: WaterIntake): Unit = withContext(ioDispatcher) {
        dao.insertOrUpdate(waterIntake.toEntity())
    }
}
