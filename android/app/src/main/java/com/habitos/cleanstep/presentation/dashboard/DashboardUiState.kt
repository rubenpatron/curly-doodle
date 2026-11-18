package com.habitos.cleanstep.presentation.dashboard

import com.habitos.cleanstep.domain.model.HabitStreak
import com.habitos.cleanstep.domain.model.NightRoutineSummary
import com.habitos.cleanstep.domain.model.SugarTrafficLight
import com.habitos.cleanstep.domain.model.WaterIntake
import com.habitos.cleanstep.domain.model.WeeklySugarDay

data class DashboardUiState(
    val habitStreak: HabitStreak = HabitStreak(
        currentStreak = 4,
        bestStreak = 9,
        daysWithoutSoda = 6,
        daysWithoutCookies = 4,
        daysWithoutChips = 5
    ),
    val sugarLevelToday: SugarTrafficLight = SugarTrafficLight.GREEN,
    val weeklySugarDays: List<WeeklySugarDay> = emptyList(),
    val waterIntake: WaterIntake = WaterIntake(glassesCount = 5, targetGlasses = 8),
    val nightRoutine: NightRoutineSummary = NightRoutineSummary(),
    val isLoading: Boolean = false,
    val userFeedbackMessage: String? = null
)
