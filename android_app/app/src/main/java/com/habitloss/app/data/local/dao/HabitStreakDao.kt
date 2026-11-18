package com.habitloss.app.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.habitloss.app.data.local.entity.HabitStreakEntity
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

/**
 * Data Access Object para la persistencia y observación reactiva de rachas.
 * Emite actualizaciones continuas mediante Kotlin Coroutines Flows.
 */
@Dao
interface HabitStreakDao {

    @Query("SELECT * FROM habit_streaks WHERE id = :id LIMIT 1")
    fun getStreakFlow(id: Long = 1L): Flow<HabitStreakEntity?>

    @Query("SELECT * FROM habit_streaks WHERE id = :id LIMIT 1")
    suspend fun getStreakSync(id: Long = 1L): HabitStreakEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdate(entity: HabitStreakEntity)

    @Update
    suspend fun update(entity: HabitStreakEntity)

    @Query("""
        UPDATE habit_streaks 
        SET current_streak = :currentStreak,
            best_streak = :bestStreak,
            last_clean_date = :lastCleanDate,
            last_updated_timestamp = :timestamp
        WHERE id = :id
    """)
    suspend fun updateStreak(
        id: Long = 1L,
        currentStreak: Int,
        bestStreak: Int,
        lastCleanDate: LocalDate,
        timestamp: Long = System.currentTimeMillis()
    )

    @Query("""
        UPDATE habit_streaks 
        SET current_streak = 0,
            last_updated_timestamp = :timestamp
        WHERE id = :id
    """)
    suspend fun recordRelapse(
        id: Long = 1L,
        timestamp: Long = System.currentTimeMillis()
    )

    @Query("""
        UPDATE habit_streaks 
        SET current_streak = 0,
            best_streak = 0,
            last_clean_date = NULL,
            last_updated_timestamp = :timestamp
        WHERE id = :id
    """)
    suspend fun resetStreak(
        id: Long = 1L,
        timestamp: Long = System.currentTimeMillis()
    )

    @Query("DELETE FROM habit_streaks WHERE id = :id")
    suspend fun deleteById(id: Long = 1L)
}
