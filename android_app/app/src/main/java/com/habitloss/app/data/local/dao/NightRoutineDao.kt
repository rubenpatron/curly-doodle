package com.habitloss.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.habitloss.app.data.local.entity.NightRoutineEntity
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

/**
 * Data Access Object para la rutina nocturna sedentario-amigable (+10:00 PM).
 */
@Dao
interface NightRoutineDao {

    @Query("SELECT * FROM night_routines WHERE date = :date LIMIT 1")
    fun getRoutineForDateFlow(date: LocalDate): Flow<NightRoutineEntity?>

    @Query("SELECT * FROM night_routines WHERE date = :date LIMIT 1")
    suspend fun getRoutineForDateSync(date: LocalDate): NightRoutineEntity?

    @Query("SELECT * FROM night_routines WHERE week_number = :weekNumber ORDER BY date ASC")
    fun getWeeklyRoutinesFlow(weekNumber: Int): Flow<List<NightRoutineEntity>>

    @Query("SELECT * FROM night_routines WHERE date BETWEEN :startDate AND :endDate ORDER BY date ASC")
    fun getRoutinesRangeFlow(startDate: LocalDate, endDate: LocalDate): Flow<List<NightRoutineEntity>>

    @Query("SELECT COUNT(*) FROM night_routines WHERE completed = 1 AND date BETWEEN :startDate AND :endDate")
    fun getCompletedCountBetweenFlow(startDate: LocalDate, endDate: LocalDate): Flow<Int>

    @Query("SELECT COUNT(*) FROM night_routines WHERE completed = 1 AND date BETWEEN :startDate AND :endDate")
    suspend fun getCompletedCountBetweenSync(startDate: LocalDate, endDate: LocalDate): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdate(routine: NightRoutineEntity)

    @Query("""
        UPDATE night_routines 
        SET completed = :completed, 
            exercises_done = :exercisesDone,
            duration_minutes = :durationMinutes,
            difficulty_level = :difficultyLevel,
            timestamp = :timestamp 
        WHERE date = :date
    """)
    suspend fun markCompleted(
        date: LocalDate,
        completed: Boolean,
        exercisesDone: List<String>,
        durationMinutes: Int,
        difficultyLevel: String,
        timestamp: Long = System.currentTimeMillis()
    )

    @Query("""
        UPDATE night_routines 
        SET completed = :completed, 
            timestamp = :timestamp 
        WHERE date = :date
    """)
    suspend fun setRoutineCompleted(
        date: LocalDate,
        completed: Boolean,
        timestamp: Long = System.currentTimeMillis()
    )

    @Query("DELETE FROM night_routines WHERE date = :date")
    suspend fun deleteForDate(date: LocalDate)
}
