package com.habitloss.app.domain.usecase.habit

import com.habitloss.app.domain.repository.HabitStreakRepository
import java.time.LocalDate

class RecordRelapseUseCase(
    private val repository: HabitStreakRepository
) {
    suspend operator fun invoke(date: LocalDate = LocalDate.now()) {
        repository.recordRelapse(date)
    }
}
