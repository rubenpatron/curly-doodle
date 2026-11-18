package com.habitloss.app.domain.usecase.sugar

import com.habitloss.app.domain.model.SugarTrafficLight
import com.habitloss.app.domain.repository.HabitStreakRepository
import com.habitloss.app.domain.repository.SugarLogRepository
import java.time.LocalDate

/**
 * Logs the daily sugar traffic light selection.
 * Crucial business logic:
 * - If GREEN ("0 azúcares hoy"), also marks or maintains the clean day in HabitStreak.
 * - If RED ("Snack procesado") or AMBER ("Bebida dulce"), marks a relapse / breaks the clean day.
 */
class LogSugarIntakeUseCase(
    private val sugarRepository: SugarLogRepository,
    private val streakRepository: HabitStreakRepository
) {
    suspend operator fun invoke(
        trafficLight: SugarTrafficLight,
        notes: String? = null,
        date: LocalDate = LocalDate.now()
    ) {
        sugarRepository.logSugar(trafficLight = trafficLight, notes = notes, date = date)
        if (trafficLight.isClean) {
            streakRepository.recordCleanDay(date)
        } else {
            streakRepository.recordRelapse(date)
        }
    }
}
