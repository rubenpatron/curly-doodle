package com.habitloss.app.domain.usecase.nightroutine

import com.habitloss.app.domain.model.RoutineDifficulty
import com.habitloss.app.domain.repository.NightRoutineRepository
import java.time.LocalDate

class CompleteNightRoutineUseCase(
    private val repository: NightRoutineRepository
) {
    suspend operator fun invoke(
        exercises: List<String>,
        durationMinutes: Int,
        weekNumber: Int = 1,
        difficulty: RoutineDifficulty = RoutineDifficulty.GENTLE,
        date: LocalDate = LocalDate.now()
    ) {
        repository.completeRoutine(
            date = date,
            exercises = exercises,
            durationMinutes = durationMinutes,
            weekNumber = weekNumber,
            difficulty = difficulty
        )
    }
}
