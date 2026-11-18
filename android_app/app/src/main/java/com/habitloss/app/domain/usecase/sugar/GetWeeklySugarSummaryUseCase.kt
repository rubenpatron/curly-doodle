package com.habitloss.app.domain.usecase.sugar

import com.habitloss.app.domain.model.SugarLog
import com.habitloss.app.domain.repository.SugarLogRepository
import kotlinx.coroutines.flow.Flow
import java.time.LocalDate

class GetWeeklySugarSummaryUseCase(
    private val repository: SugarLogRepository
) {
    operator fun invoke(endDate: LocalDate = LocalDate.now()): Flow<List<SugarLog>> {
        val startDate = endDate.minusDays(6)
        return repository.getSugarLogsRange(startDate, endDate)
    }
}
