package com.habitos.cleanstep.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.habitos.cleanstep.data.local.entity.HabitStreakEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface HabitStreakDao {
    @Query("SELECT * FROM habit_streaks WHERE id = :id LIMIT 1")
    fun getStreakFlow(id: Long = 1L): Flow<HabitStreakEntity?>

    @Query("SELECT * FROM habit_streaks WHERE id = :id LIMIT 1")
    suspend fun getStreakSync(id: Long = 1L): HabitStreakEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdate(entity: HabitStreakEntity)
}
