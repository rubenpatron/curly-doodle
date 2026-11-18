package com.habitos.cleanstep.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.habitos.cleanstep.data.local.entity.SugarLogEntity
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

@Dao
interface SugarLogDao {
    @Query("SELECT * FROM sugar_logs WHERE date = :date LIMIT 1")
    fun getLogForDateFlow(date: LocalDate): Flow<SugarLogEntity?>

    @Query("SELECT * FROM sugar_logs WHERE date = :date LIMIT 1")
    suspend fun getLogForDateSync(date: LocalDate): SugarLogEntity?

    @Query("SELECT * FROM sugar_logs WHERE date BETWEEN :startDate AND :endDate ORDER BY date ASC")
    fun getLogsBetweenFlow(startDate: LocalDate, endDate: LocalDate): Flow<List<SugarLogEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdate(log: SugarLogEntity): Long
}
