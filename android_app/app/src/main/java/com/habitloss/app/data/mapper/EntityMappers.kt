package com.habitloss.app.data.mapper

import com.habitloss.app.data.local.entity.HabitStreakEntity
import com.habitloss.app.data.local.entity.NightRoutineEntity
import com.habitloss.app.data.local.entity.SugarLogEntity
import com.habitloss.app.data.local.entity.WaterIntakeEntity
import com.habitloss.app.domain.model.HabitStreak
import com.habitloss.app.domain.model.NightRoutine
import com.habitloss.app.domain.model.SugarLog
import com.habitloss.app.domain.model.WaterIntake
import java.time.LocalDate

// --- HabitStreak Mappers ---

fun HabitStreakEntity.toDomain(): HabitStreak {
    val today = LocalDate.now()
    val isTodayClean = lastCleanDate != null && lastCleanDate.isEqual(today)
    return HabitStreak(
        id = id,
        currentStreak = currentStreak,
        bestStreak = bestStreak,
        lastCleanDate = lastCleanDate,
        startDate = startDate,
        isTodayClean = isTodayClean
    )
}

fun HabitStreak.toEntity(): HabitStreakEntity {
    return HabitStreakEntity(
        id = id,
        currentStreak = currentStreak,
        bestStreak = bestStreak,
        lastCleanDate = lastCleanDate,
        startDate = startDate,
        lastUpdatedTimestamp = System.currentTimeMillis()
    )
}

// --- SugarLog Mappers ---

fun SugarLogEntity.toDomain(): SugarLog {
    return SugarLog(
        id = id,
        date = date,
        trafficLight = sugarTrafficLight,
        notes = notes,
        timestamp = timestamp
    )
}

fun SugarLog.toEntity(): SugarLogEntity {
    return SugarLogEntity(
        id = id,
        date = date,
        sugarTrafficLight = trafficLight,
        notes = notes,
        timestamp = timestamp
    )
}

// --- WaterIntake Mappers ---

fun WaterIntakeEntity.toDomain(): WaterIntake {
    return WaterIntake(
        date = date,
        glassesCount = glassesCount,
        targetGlasses = targetGlasses
    )
}

fun WaterIntake.toEntity(): WaterIntakeEntity {
    return WaterIntakeEntity(
        date = date,
        glassesCount = glassesCount,
        targetGlasses = targetGlasses,
        timestamp = System.currentTimeMillis()
    )
}

// --- NightRoutine Mappers ---

fun NightRoutineEntity.toDomain(): NightRoutine {
    return NightRoutine(
        date = date,
        completed = completed,
        exercisesDone = exercisesDone,
        durationMinutes = durationMinutes,
        weekNumber = weekNumber,
        difficultyLevel = difficultyLevel,
        scheduledHour = scheduledHour
    )
}

fun NightRoutine.toEntity(): NightRoutineEntity {
    return NightRoutineEntity(
        date = date,
        completed = completed,
        exercisesDone = exercisesDone,
        durationMinutes = durationMinutes,
        weekNumber = weekNumber,
        difficultyLevel = difficultyLevel,
        scheduledHour = scheduledHour,
        timestamp = System.currentTimeMillis()
    )
}
