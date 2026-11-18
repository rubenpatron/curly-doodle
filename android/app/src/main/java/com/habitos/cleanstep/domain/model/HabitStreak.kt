package com.habitos.cleanstep.domain.model

data class HabitStreak(
    val currentStreak: Int = 0,
    val bestStreak: Int = 0,
    val daysWithoutSoda: Int = 0,
    val daysWithoutCookies: Int = 0,
    val daysWithoutChips: Int = 0,
    val lastCleanDate: String = ""
) {
    val motivationalMicroCopy: String
        get() = when {
            currentStreak == 0 -> "Hoy es el día 1. Un día a la vez sin refresco ni frituras."
            currentStreak in 1..2 -> "¡Arrancando con fuerza! El azúcar tarda 48h en dejar de pedir más azúcar."
            currentStreak in 3..6 -> "¡Casi una semana limpia! Tus papilas gustativas comienzan a resetearse."
            currentStreak in 7..13 -> "🔥 ¡7+ días seguidos! Estás dominando el impulso vespertino."
            currentStreak in 14..29 -> "⚡ ¡2 semanas invicto! Menos inflamación y más energía estable por la tarde."
            else -> "👑 ¡Hábito consolidado! Eres dueño de tus decisiones, no tus antojos."
        }

    val totalJunkDaysAvoided: Int
        get() = currentStreak
}
