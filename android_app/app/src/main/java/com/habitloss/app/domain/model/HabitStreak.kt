package com.habitloss.app.domain.model

import java.time.LocalDate

data class HabitStreak(
    val id: Long = 1L,
    val currentStreak: Int = 0,
    val bestStreak: Int = 0,
    val lastCleanDate: LocalDate? = null,
    val startDate: LocalDate = LocalDate.now(),
    val isTodayClean: Boolean = false
) {
    val motivationalMessage: String
        get() = when {
            currentStreak == 0 -> "El primer paso cuenta: mantente firme entre comidas hoy."
            currentStreak in 1..2 -> "¡Gran comienzo! $currentStreak día(s) libre de ultraprocesados."
            currentStreak in 3..6 -> "¡Casi una semana! Tu sensibilidad a la insulina y paladar mejoran."
            currentStreak in 7..13 -> "¡Más de una semana! Los antojos de azúcar se están apagando."
            currentStreak in 14..29 -> "¡Dos semanas completas! Estás dominando tus hábitos y evitando picos de glucosa."
            else -> "¡Increíble disciplina! $currentStreak días continuos sin chatarra."
        }

    fun isCleanForDate(date: LocalDate): Boolean {
        return lastCleanDate != null && lastCleanDate == date
    }
}
