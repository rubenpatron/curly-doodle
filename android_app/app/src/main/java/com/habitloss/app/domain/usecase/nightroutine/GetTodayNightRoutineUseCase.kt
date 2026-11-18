package com.habitloss.app.domain.usecase.nightroutine

import com.habitloss.app.domain.model.NightRoutine
import com.habitloss.app.domain.repository.NightRoutineRepository
import kotlinx.coroutines.flow.Flow

class GetTodayNightRoutineUseCase(
    private val repository: NightRoutineRepository
) {
    operator fun invoke(): Flow<NightRoutine?> = repository.getTodayRoutine()
}
