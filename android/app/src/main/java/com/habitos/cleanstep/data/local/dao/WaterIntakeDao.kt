package com.habitos.cleanstep.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.habitos.cleanstep.data.local.entity.WaterIntakeEntity
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

@Dao
interface WaterIntakeDao {
    @Query("SELECT * FROM water_intake WHERE date = :date LIMIT 1")
    fun getWaterIntakeFlow(date: LocalDate): Flow<WaterIntakeEntity?>

    @Query("SELECT * FROM water_intake WHERE date = :date LIMIT 1")
    suspend fun getWaterIntakeSync(date: LocalDate): WaterIntakeEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdate(entity: WaterIntakeEntity)

    @Query("UPDATE water_intake SET glasses_count = glasses_count + 1, timestamp = :timestamp WHERE date = :date")
    suspend fun incrementGlasses(date: LocalDate, timestamp: Long = System.currentTimeMillis())

    @Query("UPDATE water_intake SET glasses_count = CASE WHEN glasses_count > 0 THEN glasses_count - 1 ELSE 0 END, timestamp = :timestamp WHERE date = :date")
    suspend fun decrementGlasses(date: LocalDate, timestamp: Long = System.currentTimeMillis())
}
