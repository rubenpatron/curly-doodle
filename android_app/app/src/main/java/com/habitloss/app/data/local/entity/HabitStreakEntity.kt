package com.habitloss.app.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDate

/**
 * Entidad Room para persistir las rachas de días limpios sin consumo de
 * refrescos, galletas ni papas/Sabritas entre comidas.
 *
 * Se garantiza persistencia 100% offline. El registro con id = 1L representa
 * el contador principal del hábito.
 */
@Entity(tableName = "habit_streaks")
data class HabitStreakEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: Long = 1L,

    @ColumnInfo(name = "current_streak")
    val currentStreak: Int = 0,

    @ColumnInfo(name = "best_streak")
    val bestStreak: Int = 0,

    @ColumnInfo(name = "last_clean_date")
    val lastCleanDate: LocalDate? = null,

    @ColumnInfo(name = "start_date")
    val startDate: LocalDate = LocalDate.now(),

    @ColumnInfo(name = "last_updated_timestamp")
    val lastUpdatedTimestamp: Long = System.currentTimeMillis()
)
