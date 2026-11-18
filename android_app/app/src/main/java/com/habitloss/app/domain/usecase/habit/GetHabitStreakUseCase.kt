package com.habitloss.app.domain.usecase.habit

import com.habitloss.app.domain.model.HabitStreak
import com.habitloss.app.domain.repository.HabitStreakRepository
import kotlinx.coroutines.flow.Flow

class GetHabitStreakUseCase(
    private val repository: HabitStreakRepository
) {
    operator fun invoke(): Flow<HabitStreak> = repository.getStreak()
}
