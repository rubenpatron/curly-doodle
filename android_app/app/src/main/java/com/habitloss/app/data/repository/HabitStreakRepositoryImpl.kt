package com.habitloss.app.data.repository

import com.habitloss.app.data.local.dao.HabitStreakDao
import com.habitloss.app.data.local.entity.HabitStreakEntity
import com.habitloss.app.data.mapper.toDomain
import com.habitloss.app.data.mapper.toEntity
import com.habitloss.app.domain.model.HabitStreak
import com.habitloss.app.domain.repository.HabitStreakRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import java.time.LocalDate

/**
 * Implementación 100% offline del repositorio de rachas.
 * Alimenta la UI mediante StateFlow y Flows reactivos sin latencia de red.
 */
class HabitStreakRepositoryImpl(
    private val dao: HabitStreakDao,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : HabitStreakRepository {

    override fun getStreak(): Flow<HabitStreak> {
        return dao.getStreakFlow(id = 1L)
            .map { entity ->
                entity?.toDomain() ?: HabitStreak(id = 1L, currentStreak = 0, bestStreak = 0)
            }
            .flowOn(ioDispatcher)
    }

    override suspend fun recordCleanDay(date: LocalDate): Unit = withContext(ioDispatcher) {
        val currentEntity = dao.getStreakSync(id = 1L) ?: HabitStreakEntity(id = 1L)

        // Evitar duplicar el conteo en el mismo día
        if (currentEntity.lastCleanDate != null && currentEntity.lastCleanDate.isEqual(date)) {
            return@withContext
        }

        val yesterday = date.minusDays(1)
        val newCurrentStreak = if (currentEntity.lastCleanDate != null && currentEntity.lastCleanDate.isEqual(yesterday)) {
            currentEntity.currentStreak + 1
        } else {
            1
        }

        val newBestStreak = maxOf(newCurrentStreak, currentEntity.bestStreak)

        val updatedEntity = currentEntity.copy(
            currentStreak = newCurrentStreak,
            bestStreak = newBestStreak,
            lastCleanDate = date,
            lastUpdatedTimestamp = System.currentTimeMillis()
        )

        dao.insertOrUpdate(updatedEntity)
    }

    override suspend fun recordRelapse(date: LocalDate): Unit = withContext(ioDispatcher) {
        val currentEntity = dao.getStreakSync(id = 1L) ?: HabitStreakEntity(id = 1L)

        val updatedEntity = currentEntity.copy(
            currentStreak = 0,
            lastUpdatedTimestamp = System.currentTimeMillis()
        )

        dao.insertOrUpdate(updatedEntity)
    }

    override suspend fun resetStreak(): Unit = withContext(ioDispatcher) {
        dao.insertOrUpdate(
            HabitStreakEntity(
                id = 1L,
                currentStreak = 0,
                bestStreak = 0,
                lastCleanDate = null,
                startDate = LocalDate.now(),
                lastUpdatedTimestamp = System.currentTimeMillis()
            )
        )
    }

    override suspend fun updateStreak(streak: HabitStreak): Unit = withContext(ioDispatcher) {
        dao.insertOrUpdate(streak.toEntity())
    }
}
