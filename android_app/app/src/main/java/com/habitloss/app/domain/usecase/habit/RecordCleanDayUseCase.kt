package com.habitloss.app.domain.usecase.habit

import com.habitloss.app.domain.repository.HabitStreakRepository
import java.time.LocalDate

class RecordCleanDayUseCase(
    private val repository: HabitStreakRepository
) {
    suspend operator fun invoke(date: LocalDate = LocalDate.now()) {
        repository.recordCleanDay(date)
    }
}
