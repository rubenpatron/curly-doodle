package com.habitloss.app.domain.usecase.sugar

import com.habitloss.app.domain.model.SugarLog
import com.habitloss.app.domain.repository.SugarLogRepository
import kotlinx.coroutines.flow.Flow

class GetTodaySugarLogUseCase(
    private val repository: SugarLogRepository
) {
    operator fun invoke(): Flow<SugarLog?> = repository.getTodaySugarLog()
}
