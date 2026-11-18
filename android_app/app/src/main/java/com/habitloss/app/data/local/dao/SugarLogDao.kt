package com.habitloss.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.habitloss.app.data.local.entity.SugarLogEntity
import com.habitloss.app.domain.model.SugarTrafficLight
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

/**
 * Data Access Object para el registro diario de semáforo de azúcar.
 * Emite en tiempo real a través de Kotlin Flow para alimentar UI reactiva.
 */
@Dao
interface SugarLogDao {

    @Query("SELECT * FROM sugar_logs WHERE date = :date LIMIT 1")
    fun getSugarLogForDateFlow(date: LocalDate): Flow<SugarLogEntity?>

    @Query("SELECT * FROM sugar_logs WHERE date = :date LIMIT 1")
    suspend fun getSugarLogForDateSync(date: LocalDate): SugarLogEntity?

    @Query("SELECT * FROM sugar_logs WHERE date BETWEEN :startDate AND :endDate ORDER BY date ASC")
    fun getSugarLogsRangeFlow(startDate: LocalDate, endDate: LocalDate): Flow<List<SugarLogEntity>>

    @Query("SELECT * FROM sugar_logs ORDER BY date DESC LIMIT :limit")
    fun getRecentSugarLogsFlow(limit: Int = 7): Flow<List<SugarLogEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdate(log: SugarLogEntity): Long

    @Query("DELETE FROM sugar_logs WHERE date = :date")
    suspend fun deleteForDate(date: LocalDate)

    @Query("SELECT COUNT(*) FROM sugar_logs WHERE sugar_traffic_light = :trafficLight AND date BETWEEN :startDate AND :endDate")
    fun countTrafficLightInRange(
        trafficLight: SugarTrafficLight,
        startDate: LocalDate,
        endDate: LocalDate
    ): Flow<Int>
}
