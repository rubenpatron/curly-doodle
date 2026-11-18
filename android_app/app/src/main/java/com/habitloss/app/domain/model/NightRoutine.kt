package com.habitloss.app.domain.model

import java.time.LocalDate

data class NightRoutine(
    val date: LocalDate = LocalDate.now(),
    val completed: Boolean = false,
    val exercisesDone: List<String> = emptyList(),
    val durationMinutes: Int = 15,
    val weekNumber: Int = 1,
    val difficultyLevel: RoutineDifficulty = RoutineDifficulty.GENTLE,
    val scheduledHour: Int = 22 // 10:00 PM
)
