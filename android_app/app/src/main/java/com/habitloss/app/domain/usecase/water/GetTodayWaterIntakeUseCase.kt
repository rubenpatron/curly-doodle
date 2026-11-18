package com.habitloss.app.domain.usecase.water

import com.habitloss.app.domain.model.WaterIntake
import com.habitloss.app.domain.repository.WaterRepository
import kotlinx.coroutines.flow.Flow

class GetTodayWaterIntakeUseCase(
    private val repository: WaterRepository
) {
    operator fun invoke(): Flow<WaterIntake> = repository.getTodayWaterIntake()
}
