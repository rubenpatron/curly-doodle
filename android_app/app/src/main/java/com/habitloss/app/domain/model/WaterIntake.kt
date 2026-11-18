package com.habitloss.app.domain.model

import java.time.LocalDate

data class WaterIntake(
    val date: LocalDate = LocalDate.now(),
    val glassesCount: Int = 0,
    val targetGlasses: Int = 8
) {
    val progress: Float
        get() = if (targetGlasses > 0) {
            (glassesCount.toFloat() / targetGlasses).coerceIn(0f, 1f)
        } else 0f

    val volumeMl: Int
        get() = glassesCount * 250

    val targetVolumeMl: Int
        get() = targetGlasses * 250

    val isGoalReached: Boolean
        get() = glassesCount >= targetGlasses

    val remainingGlasses: Int
        get() = (targetGlasses - glassesCount).coerceAtLeast(0)
}
