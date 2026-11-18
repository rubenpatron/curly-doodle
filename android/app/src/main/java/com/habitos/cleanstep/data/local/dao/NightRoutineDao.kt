package com.habitos.cleanstep.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.habitos.cleanstep.data.local.entity.NightRoutineEntity
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

@Dao
interface NightRoutineDao {
    @Query("SELECT * FROM night_routines WHERE date = :date LIMIT 1")
    fun getRoutineForDateFlow(date: LocalDate): Flow<NightRoutineEntity?>

    @Query("SELECT * FROM night_routines WHERE date = :date LIMIT 1")
    suspend fun getRoutineForDateSync(date: LocalDate): NightRoutineEntity?

    @Query("SELECT COUNT(*) FROM night_routines WHERE completed = 1 AND date BETWEEN :startDate AND :endDate")
    fun getCompletedDaysCountFlow(startDate: LocalDate, endDate: LocalDate): Flow<Int>

    @Query("SELECT COUNT(*) FROM night_routines WHERE completed = 1 AND date BETWEEN :startDate AND :endDate")
    suspend fun getCompletedDaysCountSync(startDate: LocalDate, endDate: LocalDate): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdate(entity: NightRoutineEntity)

    @Query("""
        UPDATE night_routines 
        SET completed = :completed, 
            exercises_done = :exercisesDone, 
            duration_minutes = :durationMinutes, 
            difficulty_level = :difficultyLevel,
            timestamp = :timestamp 
        WHERE date = :date
    """)
    suspend fun updateRoutineCompletion(
        date: LocalDate,
        completed: Boolean,
        exercisesDone: List<String>,
        durationMinutes: Int,
        difficultyLevel: String,
        timestamp: Long = System.currentTimeMillis()
    )

    @Query("UPDATE night_routines SET completed = :completed, timestamp = :timestamp WHERE date = :date")
    suspend fun setCompleted(date: LocalDate, completed: Boolean, timestamp: Long = System.currentTimeMillis())
}
