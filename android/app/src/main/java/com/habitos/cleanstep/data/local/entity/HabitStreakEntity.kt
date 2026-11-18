package com.habitos.cleanstep.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDate

@Entity(tableName = "habit_streaks")
data class HabitStreakEntity(
    @PrimaryKey
    @ColumnInfo(name = "id")
    val id: Long = 1L,

    @ColumnInfo(name = "current_streak")
    val currentStreak: Int = 0,

    @ColumnInfo(name = "best_streak")
    val bestStreak: Int = 0,

    @ColumnInfo(name = "days_without_soda")
    val daysWithoutSoda: Int = 0,

    @ColumnInfo(name = "days_without_cookies")
    val daysWithoutCookies: Int = 0,

    @ColumnInfo(name = "days_without_chips")
    val daysWithoutChips: Int = 0,

    @ColumnInfo(name = "last_clean_date")
    val lastCleanDate: LocalDate? = null,

    @ColumnInfo(name = "last_updated_timestamp")
    val lastUpdatedTimestamp: Long = System.currentTimeMillis()
)
