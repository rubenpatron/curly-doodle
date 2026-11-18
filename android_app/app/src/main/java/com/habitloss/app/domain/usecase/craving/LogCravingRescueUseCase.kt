package com.habitloss.app.domain.usecase.craving

import com.habitloss.app.domain.model.CravingRescueSession
import com.habitloss.app.domain.repository.CravingRescueRepository

class LogCravingRescueUseCase(
    private val repository: CravingRescueRepository
) {
    suspend operator fun invoke(session: CravingRescueSession) {
        repository.logCravingSession(session)
    }
}
