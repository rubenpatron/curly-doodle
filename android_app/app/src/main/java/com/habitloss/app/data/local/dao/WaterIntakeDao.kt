package com.habitloss.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.habitloss.app.data.local.entity.WaterIntakeEntity
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

/**
 * Data Access Object para la hidratación diaria y conteo de vasos.
 */
@Dao
interface WaterIntakeDao {

    @Query("SELECT * FROM water_intake WHERE date = :date LIMIT 1")
    fun getWaterIntakeForDateFlow(date: LocalDate): Flow<WaterIntakeEntity?>

    @Query("SELECT * FROM water_intake WHERE date = :date LIMIT 1")
    suspend fun getWaterIntakeForDateSync(date: LocalDate): WaterIntakeEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdate(entity: WaterIntakeEntity)

    @Query("""
        UPDATE water_intake 
        SET glasses_count = glasses_count + :amount, 
            timestamp = :timestamp 
        WHERE date = :date
    """)
    suspend fun incrementGlasses(
        date: LocalDate,
        amount: Int = 1,
        timestamp: Long = System.currentTimeMillis()
    )

    @Query("""
        UPDATE water_intake 
        SET glasses_count = CASE WHEN glasses_count > 0 THEN glasses_count - :amount ELSE 0 END, 
            timestamp = :timestamp 
        WHERE date = :date
    """)
    suspend fun decrementGlasses(
        date: LocalDate,
        amount: Int = 1,
        timestamp: Long = System.currentTimeMillis()
    )

    @Query("""
        UPDATE water_intake 
        SET target_glasses = :target, 
            timestamp = :timestamp 
        WHERE date = :date
    """)
    suspend fun updateTargetGlasses(
        date: LocalDate,
        target: Int,
        timestamp: Long = System.currentTimeMillis()
    )

    @Query("SELECT * FROM water_intake WHERE date BETWEEN :startDate AND :endDate ORDER BY date ASC")
    fun getWaterHistoryFlow(startDate: LocalDate, endDate: LocalDate): Flow<List<WaterIntakeEntity>>

    @Query("DELETE FROM water_intake WHERE date = :date")
    suspend fun deleteForDate(date: LocalDate)
}
