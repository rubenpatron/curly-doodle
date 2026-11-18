package com.habitos.cleanstep.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDate

@Entity(tableName = "night_routines")
data class NightRoutineEntity(
    @PrimaryKey
    @ColumnInfo(name = "date")
    val date: LocalDate,

    @ColumnInfo(name = "completed")
    val completed: Boolean = false,

    @ColumnInfo(name = "exercises_done")
    val exercisesDone: List<String> = emptyList(),

    @ColumnInfo(name = "duration_minutes")
    val durationMinutes: Int = 15,

    @ColumnInfo(name = "week_number")
    val weekNumber: Int = 1,

    @ColumnInfo(name = "difficulty_level")
    val difficultyLevel: String = "GENTLE",

    @ColumnInfo(name = "scheduled_hour")
    val scheduledHour: Int = 22,

    @ColumnInfo(name = "timestamp")
    val timestamp: Long = System.currentTimeMillis()
)
