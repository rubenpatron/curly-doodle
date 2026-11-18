package com.habitloss.app.data.local.entity

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.PrimaryKey
import com.habitloss.app.domain.model.RoutineDifficulty
import java.time.LocalDate

/**
 * Entidad Room para la rutina nocturna de bajo impacto (+10:00 PM).
 * Adaptada para usuarios sedentarios, activando la bomba muscular sin sobreestimular
 * el sistema nervioso simpático antes de dormir.
 */
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
    val difficultyLevel: RoutineDifficulty = RoutineDifficulty.GENTLE,

    @ColumnInfo(name = "scheduled_hour")
    val scheduledHour: Int = 22,

    @ColumnInfo(name = "timestamp")
    val timestamp: Long = System.currentTimeMillis()
)
