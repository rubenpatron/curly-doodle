package com.habitloss.app.domain.model

import java.time.LocalDate

data class SugarLog(
    val id: Long = 0L,
    val date: LocalDate = LocalDate.now(),
    val trafficLight: SugarTrafficLight,
    val notes: String? = null,
    val timestamp: Long = System.currentTimeMillis()
)
