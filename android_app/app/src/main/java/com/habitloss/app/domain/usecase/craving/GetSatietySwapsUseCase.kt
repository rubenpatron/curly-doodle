package com.habitloss.app.domain.usecase.craving

import com.habitloss.app.domain.model.CravingType
import com.habitloss.app.domain.model.SatietySwapItem
import com.habitloss.app.domain.repository.CravingRescueRepository
import kotlinx.coroutines.flow.Flow

class GetSatietySwapsUseCase(
    private val repository: CravingRescueRepository
) {
    operator fun invoke(type: CravingType? = null): Flow<List<SatietySwapItem>> =
        repository.getSatietySwaps(type)
}
