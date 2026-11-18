package com.habitloss.app.domain.usecase.water

import com.habitloss.app.domain.repository.WaterRepository
import java.time.LocalDate

class DecrementWaterUseCase(
    private val repository: WaterRepository
) {
    suspend operator fun invoke(date: LocalDate = LocalDate.now()) {
        repository.decrementGlass(date)
    }
}
